import { useState, useEffect } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import SecondaryMarketABI from '../../contracts/SecondaryMarketABI.json';
import DigitalEuroABI from '../../contracts/DigitalEuroABI.json';
import FinancialAssetsABI from '../../contracts/FinancialAssetsABI.json';

// Address provided by user
const SECONDARY_MARKET_ADDRESS = import.meta.env.VITE_SECONDARY_MARKET_ADDRESS;
const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;
const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;

// Base URI from contract deployment
const METADATA_BASE_URI = "https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeigus5qoiqcybdf67q3zv6n72nmm5mqomeibarmzyejug2jvwondbi";

function SecondaryMarket() {
    const { account, provider, isConnected } = useWeb3();
    const [marketView, setMarketView] = useState('buy'); // 'buy' or 'sell'
    const [listings, setListings] = useState([]);
    const [userHoldings, setUserHoldings] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [buyingListingId, setBuyingListingId] = useState(null);
    const [creatingListingAssetId, setCreatingListingAssetId] = useState(null);
    const [status, setStatus] = useState('');

    // We need input state similar to PrimaryMarket for buying amounts
    const [buyAmounts, setBuyAmounts] = useState({});

    // State for sell inputs
    const [sellAmounts, setSellAmounts] = useState({});
    const [sellPrices, setSellPrices] = useState({});

    // Fetch listings and metadata
    const fetchListings = async () => {
        if (!provider || !SECONDARY_MARKET_ADDRESS) return;

        setIsLoading(true);
        const activeListings = [];

        try {
            const marketContract = new ethers.Contract(
                SECONDARY_MARKET_ADDRESS,
                SecondaryMarketABI,
                provider
            );

            const listingCount = await marketContract.getListingCount();

            for (let i = 0; i < listingCount; i++) {
                const listing = await marketContract.getListing(i);

                // Only active listings
                if (listing.active) {
                    // Fetch metadata
                    const assetId = listing.assetId;
                    const hexId = assetId.toString(16).padStart(64, '0');
                    const metadataUrl = `${METADATA_BASE_URI}/${hexId}.json`;

                    let metadata = null;
                    try {
                        const response = await fetch(metadataUrl);
                        metadata = await response.json();
                    } catch (err) {
                        console.error(`Error fetching metadata for asset ${assetId}:`, err);
                    }

                    activeListings.push({
                        id: i.toString(), // listingId
                        assetId: assetId.toString(),
                        seller: listing.seller,
                        amount: listing.amount.toString(), // Available amount in listing
                        pricePerUnit: parseFloat(ethers.formatUnits(listing.pricePerUnit, 6)),
                        metadata
                    });
                }
            }
        } catch (error) {
            console.error("Error fetching listings:", error);
        }

        setListings(activeListings);
        setIsLoading(false);
    };

    // Fetch user holdings for sell view
    const fetchUserHoldings = async () => {
        if (!account || !provider || !FINANCIAL_ASSETS_ADDRESS) {
            setUserHoldings([]);
            return;
        }

        try {
            setIsLoading(true);
            const assetsContract = new ethers.Contract(
                FINANCIAL_ASSETS_ADDRESS,
                FinancialAssetsABI,
                provider
            );

            const holdings = [];
            let maxAssetId = 10;

            try {
                const assetTypeCount = await assetsContract.getAssetTypeCount();
                if (assetTypeCount > 0) {
                    maxAssetId = Math.max(Number(assetTypeCount), 10);
                }
            } catch (error) {
                console.warn('Could not get asset type count:', error);
            }

            for (let assetId = 1; assetId <= maxAssetId; assetId++) {
                try {
                    const exists = await assetsContract.assetExists(assetId);
                    if (!exists) continue;

                    const balance = await assetsContract.balanceOf(account, assetId);
                    if (balance > 0n) {
                        const name = await assetsContract.getAssetName(assetId);
                        const symbol = await assetsContract.getAssetSymbol(assetId);

                        // Fetch metadata
                        const hexId = assetId.toString(16).padStart(64, '0');
                        const metadataUrl = `${METADATA_BASE_URI}/${hexId}.json`;

                        let metadata = null;
                        try {
                            const response = await fetch(metadataUrl);
                            metadata = await response.json();
                        } catch (err) {
                            console.error(`Error fetching metadata for asset ${assetId}:`, err);
                        }

                        holdings.push({
                            assetId,
                            name,
                            symbol,
                            balance: balance.toString(),
                            balanceFormatted: ethers.formatUnits(balance, 0),
                            metadata
                        });
                    }
                } catch (error) {
                    if (!error.message.includes('asset')) {
                        console.error(`Error fetching asset ${assetId}:`, error.message);
                    }
                }
            }

            setUserHoldings(holdings);
        } catch (error) {
            console.error('Error fetching user holdings:', error);
            setUserHoldings([]);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        if (marketView === 'buy') {
            fetchListings();
        } else {
            fetchUserHoldings();
        }
    }, [provider, marketView, account]);

    /**
     * COMPRA EN MERCADO SECUNDARIO P2P CON DVP ATÓMICO
     * 
     * Los activos ya están en ESCROW dentro del contrato Secondary Market
     * (fueron transferidos cuando el vendedor creó el listing)
     * 
     * PASO 1: APPROVAL de DEUR
     * - Aprobamos al Secondary Market para gastar nuestros DEUR
     * 
     * PASO 2: EXECUTE TRADE (Intercambio Atómico)
     * - Llamamos executeTrade() en el contrato
     * - El contrato ejecuta ATÓMICAMENTE:
     *   a) transferFrom() DEUR del comprador al vendedor
     *   b) safeTransferFrom() activos del escrow al comprador
     * - Si falla cualquiera, TODA la transacción se revierte
     * 
     * VENTAJA DEL ESCROW + DvP:
     * - El vendedor NO puede retirar sus activos (están bloqueados en escrow)
     * - El comprador NO puede perder DEUR sin recibir activos
     * - Intercambio P2P sin intermediarios confiables
     * - Permite COMPRAS PARCIALES del listing
     */
    const executeBuy = async (listing) => {
        const amount = buyAmounts[listing.id];

        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (!amount || parseFloat(amount) <= 0) {
            setStatus('❌ Please enter a valid amount');
            return;
        }

        if (parseInt(amount) > parseInt(listing.amount)) {
            setStatus('❌ Amount exceeds available quantity');
            return;
        }

        try {
            setBuyingListingId(listing.id);
            setStatus('⏳ Checking allowance...');

            const signer = await provider.getSigner();

            const totalPrice = listing.pricePerUnit * parseFloat(amount);
            const totalPriceInWei = ethers.parseUnits(totalPrice.toString(), 6);

            const deurContract = new ethers.Contract(
                DIGITAL_EURO_ADDRESS,
                DigitalEuroABI,
                signer
            );

            const currentAllowance = await deurContract.allowance(account, SECONDARY_MARKET_ADDRESS);

            if (currentAllowance < totalPriceInWei) {
                setStatus('⏳ Approving DEUR...');
                const approveTx = await deurContract.approve(SECONDARY_MARKET_ADDRESS, totalPriceInWei);
                setStatus('⏳ Waiting for approval confirmation...');
                await approveTx.wait();
            } else {
                setStatus('✅ Allowance sufficient, skipping approval...');
            }

            setStatus('⏳ Buying asset...');
            const marketContract = new ethers.Contract(
                SECONDARY_MARKET_ADDRESS,
                SecondaryMarketABI,
                signer
            );

            const buyTx = await marketContract.executeTrade(listing.id, parseInt(amount));
            setStatus('⏳ Waiting for purchase confirmation...');
            const receipt = await buyTx.wait();

            setStatus(`✅ Purchase successful! Tx: ${receipt.hash.substring(0, 10)}...`);
            setBuyAmounts(prev => ({ ...prev, [listing.id]: '' }));

            await fetchListings();

            setTimeout(() => setStatus(''), 5000);
        } catch (error) {
            console.error('Error buying asset:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('InsufficientBalance')) {
                setStatus('❌ Insufficient DEUR balance');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setBuyingListingId(null);
        }
    };

    /**
     * CREAR LISTING (VENDER) EN MERCADO SECUNDARIO P2P CON ESCROW
     * 
     * PASO 1: APPROVAL de activos
     * - Para ERC-1155 usamos setApprovalForAll() en lugar de approve()
     * - Esto autoriza al Secondary Market a transferir TODOS nuestros activos de este tipo
     * - Solo necesitamos hacer esto UNA VEZ (queda guardado en blockchain)
     * 
     * PASO 2: CREATE LISTING (Los activos van a ESCROW)
     * - Llamamos createListing() en el contrato
     * - El contrato ejecuta safeTransferFrom() moviendo los activos:
     *   FROM: nuestra wallet
     *   TO: dirección del contrato Secondary Market (ESCROW)
     * - Los activos quedan BLOQUEADOS en el contrato hasta que:
     *   a) Alguien compre (ejecute el trade)
     *   b) Nosotros cancelemos el listing
     * 
     * MECANISMO DE ESCROW:
     * - Una vez en escrow, NO podemos gastar esos activos
     * - Los compradores tienen GARANTÍA de que los activos existen
     * - El contrato actúa como "custodio" neutral
     * - Solo el contrato puede liberar los activos (a comprador o de vuelta a vendedor)
     */
    const executeCreateListing = async (holding) => {
        const amount = sellAmounts[holding.assetId];
        const pricePerUnit = sellPrices[holding.assetId];

        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (!amount || parseFloat(amount) <= 0) {
            setStatus('❌ Please enter a valid amount');
            return;
        }

        if (!pricePerUnit || parseFloat(pricePerUnit) <= 0) {
            setStatus('❌ Please enter a valid price');
            return;
        }

        if (parseInt(amount) > parseInt(holding.balance)) {
            setStatus('❌ Amount exceeds your balance');
            return;
        }

        try {
            setCreatingListingAssetId(holding.assetId);
            setStatus('⏳ Checking approval...');

            const signer = await provider.getSigner();

            const assetsContract = new ethers.Contract(
                FINANCIAL_ASSETS_ADDRESS,
                FinancialAssetsABI,
                signer
            );

            const isApproved = await assetsContract.isApprovedForAll(account, SECONDARY_MARKET_ADDRESS);

            if (!isApproved) {
                setStatus('⏳ Approving Secondary Market to transfer your assets...');
                const approveTx = await assetsContract.setApprovalForAll(SECONDARY_MARKET_ADDRESS, true);
                setStatus('⏳ Waiting for approval confirmation...');
                await approveTx.wait();
            } else {
                setStatus('✅ Already approved, skipping approval...');
            }

            setStatus('⏳ Creating listing...');
            const marketContract = new ethers.Contract(
                SECONDARY_MARKET_ADDRESS,
                SecondaryMarketABI,
                signer
            );

            const priceInWei = ethers.parseUnits(pricePerUnit.toString(), 6);
            const createTx = await marketContract.createListing(holding.assetId, parseInt(amount), priceInWei);
            setStatus('⏳ Waiting for listing confirmation...');
            const receipt = await createTx.wait();

            setStatus(`✅ Listing created! Tx: ${receipt.hash.substring(0, 10)}...`);
            setSellAmounts(prev => ({ ...prev, [holding.assetId]: '' }));
            setSellPrices(prev => ({ ...prev, [holding.assetId]: '' }));

            await fetchUserHoldings();

            setTimeout(() => setStatus(''), 5000);
        } catch (error) {
            console.error('Error creating listing:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('InsufficientAssets')) {
                setStatus('❌ Insufficient assets');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setCreatingListingAssetId(null);
        }
    };

    if (isLoading && ((marketView === 'buy' && listings.length === 0) || (marketView === 'sell' && userHoldings.length === 0))) {
        return (
            <section id="secondary-market" className="section marketplace">
                <h2 className="section-title">Secondary Market</h2>

                {/* Market Type Tabs */}
                <div className="market-type-tabs">
                    <button
                        className={`market-type-btn ${marketView === 'buy' ? 'active' : ''}`}
                        onClick={() => setMarketView('buy')}
                    >
                        Buy
                    </button>
                    <button
                        className={`market-type-btn ${marketView === 'sell' ? 'active' : ''}`}
                        onClick={() => setMarketView('sell')}
                    >
                        Sell
                    </button>
                </div>

                <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                    <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>⏳</div>
                    <div>Loading...</div>
                </div>
            </section>
        );
    }

    return (
        <section id="secondary-market" className="section marketplace">
            <h2 className="section-title">Secondary Market</h2>

            {/* Market Type Tabs */}
            <div className="market-type-tabs">
                <button
                    className={`market-type-btn ${marketView === 'buy' ? 'active' : ''}`}
                    onClick={() => setMarketView('buy')}
                >
                    Buy
                </button>
                <button
                    className={`market-type-btn ${marketView === 'sell' ? 'active' : ''}`}
                    onClick={() => setMarketView('sell')}
                >
                    Sell
                </button>
            </div>

            {status && (
                <div className="status-message">
                    {status}
                </div>
            )}

            {/* BUY VIEW */}
            {marketView === 'buy' && (
                <>
                    {listings.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                            <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📦</div>
                            <div>No active listings in Secondary Market</div>
                        </div>
                    ) : (
                        <div className="primary-market-grid">
                            {listings.map((listing) => (
                                <div key={listing.id} className="premium-asset-card">
                                    {listing.metadata?.image && (
                                        <div className="premium-image-container">
                                            <img src={listing.metadata.image} alt={listing.metadata.name} className="premium-asset-image" />
                                            <div className="image-overlay"></div>
                                        </div>
                                    )}

                                    <div className="premium-card-content">
                                        <div className="asset-header">
                                            <h3 className="premium-asset-title">{listing.metadata?.name || `Asset #${listing.assetId}`}</h3>
                                            <span className="premium-asset-badge">ID: {listing.assetId}</span>
                                        </div>

                                        <p className="premium-asset-description">
                                            {listing.metadata?.description || 'No description available'}
                                        </p>

                                        <div className="premium-attributes">
                                            <div className="premium-attribute">
                                                <span className="premium-attr-label">Seller</span>
                                                <span className="premium-attr-value">{listing.seller.substring(0, 6)}...{listing.seller.substring(38)}</span>
                                            </div>
                                        </div>

                                        <div className="premium-stats">
                                            <div className="premium-stat">
                                                <span className="premium-stat-label">Price</span>
                                                <span className="premium-stat-value">{listing.pricePerUnit.toLocaleString()} DEUR</span>
                                            </div>
                                            <div className="premium-stat">
                                                <span className="premium-stat-label">Available</span>
                                                <span className="premium-stat-value">{listing.amount}</span>
                                            </div>
                                        </div>

                                        <div className="premium-buy-section">
                                            <input
                                                type="number"
                                                placeholder="Amount"
                                                value={buyAmounts[listing.id] || ''}
                                                onChange={(e) => {
                                                    const newAmount = e.target.value;
                                                    setBuyAmounts(prev => ({ ...prev, [listing.id]: newAmount }));
                                                }}
                                                disabled={buyingListingId !== null}
                                                min="1"
                                                max={listing.amount}
                                                className="premium-input"
                                            />
                                            <button
                                                onClick={() => executeBuy(listing)}
                                                disabled={buyingListingId !== null}
                                                className="premium-buy-btn"
                                            >
                                                {buyingListingId === listing.id ? 'BUYING...' : 'BUY NOW'}
                                            </button>
                                        </div>

                                        {buyAmounts[listing.id] && (
                                            <div className="premium-total">
                                                <span>Total:</span>
                                                <span className="premium-total-amount">{(listing.pricePerUnit * parseFloat(buyAmounts[listing.id])).toLocaleString()} DEUR</span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </>
            )}

            {/* SELL VIEW */}
            {marketView === 'sell' && (
                <>
                    {!isConnected ? (
                        <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                            <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>🔌</div>
                            <div>Connect your wallet to create listings</div>
                        </div>
                    ) : userHoldings.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                            <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📦</div>
                            <div>You don't have any assets to sell</div>
                        </div>
                    ) : (
                        <div className="primary-market-grid">
                            {userHoldings.map((holding) => (
                                <div key={holding.assetId} className="premium-asset-card">
                                    {holding.metadata?.image && (
                                        <div className="premium-image-container">
                                            <img src={holding.metadata.image} alt={holding.metadata.name} className="premium-asset-image" />
                                            <div className="image-overlay"></div>
                                        </div>
                                    )}

                                    <div className="premium-card-content">
                                        <div className="asset-header">
                                            <h3 className="premium-asset-title">{holding.metadata?.name || holding.name}</h3>
                                            <span className="premium-asset-badge">{holding.symbol}</span>
                                        </div>

                                        <p className="premium-asset-description">
                                            {holding.metadata?.description || 'No description available'}
                                        </p>

                                        <div className="premium-stats">
                                            <div className="premium-stat">
                                                <span className="premium-stat-label">Balance</span>
                                                <span className="premium-stat-value">{holding.balanceFormatted}</span>
                                            </div>
                                            <div className="premium-stat">
                                                <span className="premium-stat-label">Asset ID</span>
                                                <span className="premium-stat-value">{holding.assetId}</span>
                                            </div>
                                        </div>

                                        <div className="premium-buy-section sell-section">
                                            <input
                                                type="number"
                                                placeholder="Amount to sell"
                                                value={sellAmounts[holding.assetId] || ''}
                                                onChange={(e) => {
                                                    const newAmount = e.target.value;
                                                    setSellAmounts(prev => ({ ...prev, [holding.assetId]: newAmount }));
                                                }}
                                                disabled={creatingListingAssetId !== null}
                                                min="1"
                                                max={holding.balance}
                                                className="premium-input"
                                            />
                                            <input
                                                type="number"
                                                placeholder="Price per unit (DEUR)"
                                                value={sellPrices[holding.assetId] || ''}
                                                onChange={(e) => {
                                                    const newPrice = e.target.value;
                                                    setSellPrices(prev => ({ ...prev, [holding.assetId]: newPrice }));
                                                }}
                                                disabled={creatingListingAssetId !== null}
                                                min="0.01"
                                                step="0.01"
                                                className="premium-input"
                                            />
                                            <button
                                                onClick={() => executeCreateListing(holding)}
                                                disabled={creatingListingAssetId !== null}
                                                className="premium-buy-btn"
                                            >
                                                {creatingListingAssetId === holding.assetId ? 'CREATING...' : 'SELL NOW'}
                                            </button>
                                        </div>

                                        {sellAmounts[holding.assetId] && sellPrices[holding.assetId] && (
                                            <div className="premium-total">
                                                <span>Total Value:</span>
                                                <span className="premium-total-amount">{(parseFloat(sellPrices[holding.assetId]) * parseFloat(sellAmounts[holding.assetId])).toLocaleString()} DEUR</span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </>
            )}
        </section>
    );
}

export default SecondaryMarket;
