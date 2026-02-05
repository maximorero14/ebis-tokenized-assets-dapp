import { useState, useEffect } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { useAssetsList } from '../../hooks/useAssetsList';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../../contracts/FinancialAssetsABI.json';
import PrimaryMarketABI from '../../contracts/PrimaryMarketABI.json';
import DigitalEuroABI from '../../contracts/DigitalEuroABI.json';
import { waitForTransaction } from '../../utils/txUtils';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;
const PRIMARY_MARKET_ADDRESS = import.meta.env.VITE_PRIMARY_MARKET_ADDRESS;
const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;

// Base URI from contract deployment
const METADATA_BASE_URI = "https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeigus5qoiqcybdf67q3zv6n72nmm5mqomeibarmzyejug2jvwondbi";

function PrimaryMarket() {
    const { account, provider, isConnected } = useWeb3();
    const { assets, isLoading: assetsLoading } = useAssetsList(provider);
    const [assetsWithMetadata, setAssetsWithMetadata] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [buyingAsset, setBuyingAsset] = useState(null);
    const [buyAmounts, setBuyAmounts] = useState({});
    const [status, setStatus] = useState('');

    // Scroll to top when status changes to show feedback
    useEffect(() => {
        if (status) {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }, [status]);

    // Fetch metadata for all assets
    const fetchMetadata = async () => {
        if (assets.length === 0) return;

        setIsLoading(true);
        const assetsWithMeta = [];

        for (const asset of assets) {
            try {
                // Convert asset ID to 64-character hex (ERC1155 standard)
                const hexId = asset.id.toString(16).padStart(64, '0');
                const metadataUrl = `${METADATA_BASE_URI}/${hexId}.json`;

                console.log(`Fetching metadata for asset ${asset.id}:`, metadataUrl);

                const response = await fetch(metadataUrl);
                const metadata = await response.json();

                // Get price from PrimaryMarket contract
                let price = 0;
                let availableSupply = 0;

                if (provider && PRIMARY_MARKET_ADDRESS) {
                    const marketContract = new ethers.Contract(
                        PRIMARY_MARKET_ADDRESS,
                        PrimaryMarketABI,
                        provider
                    );

                    const priceInWei = await marketContract.getAssetPrice(asset.id);
                    price = parseFloat(ethers.formatUnits(priceInWei, 6));

                    availableSupply = await marketContract.getAvailableSupply(asset.id);
                }

                assetsWithMeta.push({
                    ...asset,
                    metadata,
                    price,
                    availableSupply: availableSupply.toString()
                });
            } catch (error) {
                console.error(`Error fetching metadata for asset ${asset.id}:`, error);
                // Add asset without metadata
                assetsWithMeta.push({
                    ...asset,
                    metadata: null,
                    price: 0,
                    availableSupply: '0'
                });
            }
        }

        setAssetsWithMetadata(assetsWithMeta);
        setIsLoading(false);
    };

    useEffect(() => {
        fetchMetadata();
    }, [assets, provider]);

    /**
     * PATRÓN DvP (DELIVERY VS PAYMENT) EN BLOCKCHAIN
     * 
     * Este proceso implementa DvP atómico para compra de activos en IPO:
     * 
     * PASO 1: APPROVAL (Aprobación de DEUR)
     * - Primero verificamos si el Primary Market ya tiene allowance suficiente
     * - Si no, llamamos approve() en el contrato DEUR (ERC-20)
     * - approve() le da permiso al Primary Market para gastar nuestros DEUR
     * - Esto NO transfiere fondos, solo autoriza al contrato a hacerlo
     * 
     * PASO 2: BUY ASSET (Compra Atómica)
     * - Llamamos buyAsset() en el Primary Market
     * - El contrato ejecuta ATÓMICAMENTE (todo o nada):
     *   a) Transfiere DEUR de nuestra wallet al fundTreasury (usando el allowance)
     *   b) Transfiere activos del Primary Market a nuestra wallet
     * - Si falla cualquiera de los dos pasos, TODA la transacción se revierte
     * - Esto garantiza que no podemos perder DEUR sin recibir activos (y viceversa)
     * 
     * VENTAJA DEL DvP:
     * - Cero riesgo de contraparte
     * - No puede haber pago sin entrega
     * - No puede haber entrega sin pago
     * - Todo sucede en una sola transacción atómica
     */
    const handleBuy = async (asset) => {
        const amount = buyAmounts[asset.id];
        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (parseFloat(amount) > parseFloat(asset.availableSupply)) {
            setStatus('❌ Not enough assets available');
            return;
        }

        try {
            setBuyingAsset(asset.id);
            setStatus('⏳ Approving DEUR...');

            const signer = await provider.getSigner();

            const totalPrice = asset.price * parseFloat(amount);
            const totalPriceInWei = ethers.parseUnits(totalPrice.toString(), 6);

            setStatus('⏳ Checking allowance...');
            const deurContract = new ethers.Contract(
                DIGITAL_EURO_ADDRESS,
                DigitalEuroABI,
                signer
            );

            const currentAllowance = await deurContract.allowance(account, PRIMARY_MARKET_ADDRESS);

            if (currentAllowance < totalPriceInWei) {
                setStatus('⏳ Approving DEUR...');
                const approveTx = await deurContract.approve(PRIMARY_MARKET_ADDRESS, totalPriceInWei);
                setStatus('⏳ Waiting for approval confirmation...');

                // Robust waiting for approval with timeout
                await waitForTransaction(approveTx, provider);
                setStatus('✅ Approval confirmed!');
            } else {
                setStatus('✅ Allowance sufficient, skipping approval...');
            }

            setStatus('⏳ Buying asset...');
            const marketContract = new ethers.Contract(
                PRIMARY_MARKET_ADDRESS,
                PrimaryMarketABI,
                signer
            );

            const buyTx = await marketContract.buyAsset(asset.id, parseInt(amount));
            setStatus('⏳ Waiting for purchase confirmation...');

            // Robust waiting for purchase with timeout
            const receipt = await waitForTransaction(buyTx, provider);

            const txHash = buyTx.hash || receipt?.hash || receipt?.transactionHash || 'unknown';
            setStatus(`✅ Purchase successful! Tx: ${txHash.substring(0, 10)}...`);
            setBuyAmounts(prev => ({ ...prev, [asset.id]: '' }));

            await fetchMetadata();

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
            setBuyingAsset(null);
        }
    };

    if (assetsLoading || isLoading) {
        return (
            <section id="primary-market" className="section marketplace">
                <h2 className="section-title">Primary Market</h2>
                <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                    <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>⏳</div>
                    <div>Loading assets...</div>
                </div>
            </section>
        );
    }

    if (assetsWithMetadata.length === 0) {
        return (
            <section id="primary-market" className="section marketplace">
                <h2 className="section-title">Primary Market</h2>
                <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                    <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📦</div>
                    <div>No assets available in Primary Market</div>
                </div>
            </section>
        );
    }

    return (
        <section id="primary-market" className="section marketplace">
            <h2 className="section-title">Primary Market</h2>

            {status && (
                <div className="status-message">
                    {status}
                </div>
            )}

            <div className="primary-market-grid">
                {assetsWithMetadata.map((asset) => (
                    <div key={asset.id} className="premium-asset-card">
                        {asset.metadata?.image && (
                            <div className="premium-image-container">
                                <img src={asset.metadata.image} alt={asset.metadata.name} className="premium-asset-image" />
                                <div className="image-overlay"></div>
                            </div>
                        )}

                        <div className="premium-card-content">
                            <div className="asset-header">
                                <h3 className="premium-asset-title">{asset.metadata?.name || asset.name}</h3>
                                <span className="premium-asset-badge">{asset.symbol}</span>
                            </div>



                            {asset.metadata?.attributes && (
                                <div className="premium-attributes">
                                    {asset.metadata.attributes.slice(0, 3).map((attr, idx) => (
                                        <div key={idx} className="premium-attribute">
                                            <span className="premium-attr-label">{attr.trait_type}</span>
                                            <span className="premium-attr-value">{attr.value}</span>
                                        </div>
                                    ))}
                                </div>
                            )}

                            <div className="premium-stats">
                                <div className="premium-stat">
                                    <span className="premium-stat-label">Price</span>
                                    <span className="premium-stat-value">{asset.price.toLocaleString()} DEUR</span>
                                </div>
                                <div className="premium-stat">
                                    <span className="premium-stat-label">Available</span>
                                    <span className="premium-stat-value">{asset.availableSupply}</span>
                                </div>
                            </div>

                            <div className="premium-buy-section">
                                <input
                                    type="number"
                                    placeholder="Amount"
                                    value={buyAmounts[asset.id] || ''}
                                    onChange={(e) => {
                                        const newAmount = e.target.value;
                                        setBuyAmounts(prev => ({ ...prev, [asset.id]: newAmount }));
                                    }}
                                    disabled={buyingAsset !== null}
                                    min="1"
                                    className="premium-input"
                                />
                                <button
                                    onClick={() => handleBuy(asset)}
                                    disabled={buyingAsset !== null}
                                    className="premium-buy-btn"
                                >
                                    {buyingAsset === asset.id ? 'BUYING...' : 'BUY NOW'}
                                </button>
                            </div>

                            {buyAmounts[asset.id] && (
                                <div className="premium-total">
                                    <span>Total:</span>
                                    <span className="premium-total-amount">{(asset.price * parseFloat(buyAmounts[asset.id])).toLocaleString()} DEUR</span>
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </section>
    );
}

export default PrimaryMarket;
