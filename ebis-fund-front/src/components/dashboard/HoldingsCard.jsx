import { useState, useEffect } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../../contracts/FinancialAssetsABI.json';
import PrimaryMarketABI from '../../contracts/PrimaryMarketABI.json';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;
const PRIMARY_MARKET_ADDRESS = import.meta.env.VITE_PRIMARY_MARKET_ADDRESS;

function HoldingsCard() {
    const { account, provider, isConnected } = useWeb3();
    const [holdings, setHoldings] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [totalValue, setTotalValue] = useState(0);

    useEffect(() => {
        const fetchHoldings = async () => {
            if (!account || !provider || !FINANCIAL_ASSETS_ADDRESS) {
                setHoldings([]);
                setTotalValue(0);
                return;
            }

            try {
                setIsLoading(true);
                const assetsContract = new ethers.Contract(
                    FINANCIAL_ASSETS_ADDRESS,
                    FinancialAssetsABI,
                    provider
                );

                const marketContract = new ethers.Contract(
                    PRIMARY_MARKET_ADDRESS,
                    PrimaryMarketABI,
                    provider
                );

                console.log('🔍 Fetching holdings for account:', account);
                console.log('📍 FinancialAssets address:', FINANCIAL_ASSETS_ADDRESS);
                console.log('📍 PrimaryMarket address:', PRIMARY_MARKET_ADDRESS);

                const userHoldings = [];
                let totalPortfolioValue = 0;

                // Try to get asset type count, but don't rely on it exclusively
                let maxAssetId = 10; // Check first 10 asset IDs by default
                try {
                    const assetTypeCount = await assetsContract.getAssetTypeCount();
                    console.log('📊 Asset type count:', assetTypeCount.toString());
                    if (assetTypeCount > 0) {
                        maxAssetId = Math.max(Number(assetTypeCount), 10);
                    }
                } catch (error) {
                    console.warn('⚠️ Could not get asset type count, checking IDs 1-10:', error);
                }

                // Check balance for each asset ID
                for (let assetId = 1; assetId <= maxAssetId; assetId++) {
                    try {
                        // First check if asset exists
                        const exists = await assetsContract.assetExists(assetId);
                        if (!exists) {
                            continue;
                        }

                        // Check if user has balance for this asset
                        const balance = await assetsContract.balanceOf(account, assetId);
                        console.log(`Asset ${assetId} balance:`, balance.toString());

                        if (balance > 0n) {
                            // Get asset details
                            const name = await assetsContract.getAssetName(assetId);
                            const symbol = await assetsContract.getAssetSymbol(assetId);
                            const totalSupply = await assetsContract['totalSupply(uint256)'](assetId);

                            // Get price from PrimaryMarket (in DEUR with 6 decimals)
                            const priceInWei = await marketContract.getAssetPrice(assetId);
                            const pricePerToken = parseFloat(ethers.formatUnits(priceInWei, 6));

                            // Calculate total value for this holding
                            const balanceNum = parseFloat(ethers.formatUnits(balance, 0));
                            const holdingValue = balanceNum * pricePerToken;
                            totalPortfolioValue += holdingValue;

                            console.log(`✅ Found asset ${assetId}:`, {
                                name,
                                symbol,
                                balance: balance.toString(),
                                price: pricePerToken,
                                value: holdingValue
                            });

                            userHoldings.push({
                                assetId,
                                name,
                                symbol,
                                balance: balance.toString(),
                                totalSupply: totalSupply.toString(),
                                balanceFormatted: ethers.formatUnits(balance, 0),
                                price: pricePerToken,
                                value: holdingValue
                            });
                        }
                    } catch (error) {
                        // Silently skip assets that don't exist or have errors
                        if (!error.message.includes('asset')) {
                            console.error(`Error fetching asset ${assetId}:`, error.message);
                        }
                    }
                }

                console.log('📦 Total holdings found:', userHoldings.length);
                console.log('💰 Total portfolio value:', totalPortfolioValue, 'DEUR');

                setHoldings(userHoldings);
                setTotalValue(totalPortfolioValue);

            } catch (error) {
                console.error('❌ Error fetching holdings:', error);
                setHoldings([]);
                setTotalValue(0);
            } finally {
                setIsLoading(false);
            }
        };

        fetchHoldings();

        // Refresh holdings every 15 seconds
        const interval = setInterval(fetchHoldings, 15000);

        return () => clearInterval(interval);
    }, [account, provider]);

    if (!isConnected) {
        return (
            <div className="glass-card">
                <h3 className="card-title">Your Holdings</h3>
                <div style={{
                    padding: '2rem',
                    textAlign: 'center',
                    color: 'rgba(255, 255, 255, 0.6)'
                }}>
                    Connect your wallet to view your holdings
                </div>
            </div>
        );
    }

    if (isLoading && holdings.length === 0) {
        return (
            <div className="glass-card">
                <h3 className="card-title">Your Holdings</h3>
                <div style={{
                    padding: '2rem',
                    textAlign: 'center',
                    color: 'rgba(255, 255, 255, 0.6)'
                }}>
                    Loading your holdings...
                </div>
            </div>
        );
    }

    if (holdings.length === 0) {
        return (
            <div className="glass-card">
                <h3 className="card-title">Your Holdings</h3>
                <div style={{
                    padding: '2rem',
                    textAlign: 'center',
                    color: 'rgba(255, 255, 255, 0.6)'
                }}>
                    You don't have any assets yet
                </div>
            </div>
        );
    }

    return (
        <div className="glass-card">
            <h3 className="card-title">Your Holdings</h3>
            <div className="holdings-list">
                {holdings.map((holding) => (
                    <div key={holding.assetId} className="holding-item">
                        <div className="holding-left">
                            <div className="holding-info">
                                <span className="holding-symbol">{holding.symbol}</span>
                                <span className="holding-name">{holding.name}</span>
                            </div>
                            <div className="holding-values">
                                <span className="holding-amount">
                                    {holding.balanceFormatted} tokens
                                </span>
                                <span className="holding-price" style={{ fontSize: '0.85rem', opacity: 0.7 }}>
                                    ID: {holding.assetId}
                                </span>
                                <span className="holding-price" style={{ fontSize: '0.85rem', opacity: 0.7 }}>
                                    {holding.price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} DEUR
                                </span>
                            </div>
                        </div>
                        <button className="btn-sell" disabled>
                            Sell
                        </button>
                    </div>
                ))}
            </div>
            <div className="total-value">
                <span>Total Portfolio Value</span>
                <span className="total-amount">
                    {totalValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} DEUR
                </span>
            </div>
        </div>
    );
}

export default HoldingsCard;
