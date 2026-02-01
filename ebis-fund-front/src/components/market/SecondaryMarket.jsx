import { useState, useEffect } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import SecondaryMarketABI from '../../contracts/SecondaryMarketABI.json';
import DigitalEuroABI from '../../contracts/DigitalEuroABI.json';

// Address provided by user
const SECONDARY_MARKET_ADDRESS = "0xb677eefc8c60919ff4726dda3fa827b70fd64f89";
const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;

// Base URI from contract deployment
const METADATA_BASE_URI = "https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeignpqpasdhwfe4h5zj3vyfnezmeid3aq36g7h4jt6nktadcihisna";

function SecondaryMarket() {
    const { account, provider, isConnected } = useWeb3();
    const [listings, setListings] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [buyingListingId, setBuyingListingId] = useState(null);
    const [status, setStatus] = useState('');

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

    useEffect(() => {
        fetchListings();
    }, [provider]);

    const handleBuy = async (listing) => {
        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        // For secondary market, we usually buy the whole listing or a specific amount.
        // The contract executeTrade takes (listingId, amount). 
        // Based on UI pattern, we probably want to let user choose amount causing split/partial fill if contract supports it.
        // Assuming user enters amount to buy from this listing.
        // WARNING: The provided ABI 'executeTrade' takes (listingId, amount). 
        // We need an input for amount just like Primary Market.

        // Let's assume we implement the same input logic as Primary Market.
        // But first let's finish the scaffold.
    };

    // We need input state similar to PrimaryMarket for buying amounts
    const [buyAmounts, setBuyAmounts] = useState({});

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

        // Check if amount exceeds listing amount
        if (parseInt(amount) > parseInt(listing.amount)) {
            setStatus('❌ Amount exceeds available quantity');
            return;
        }

        try {
            setBuyingListingId(listing.id);
            setStatus('⏳ Checking allowance...');

            const signer = await provider.getSigner();

            // Calculate total price
            const totalPrice = listing.pricePerUnit * parseFloat(amount);
            const totalPriceInWei = ethers.parseUnits(totalPrice.toString(), 6);

            // Step 1: Check Allowance
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

            // Step 2: Buy asset
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

            // Refresh
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

    if (isLoading) {
        return (
            <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>⏳</div>
                <div>Loading market listings...</div>
            </div>
        );
    }

    if (listings.length === 0) {
        return (
            <div style={{ textAlign: 'center', padding: '3rem', opacity: 0.7 }}>
                <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📦</div>
                <div>No active listings in Secondary Market</div>
            </div>
        );
    }

    return (
        <div className="primary-market">
            {status && (
                <div className="status-message">
                    {status}
                </div>
            )}

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
        </div>
    );
}

export default SecondaryMarket;
