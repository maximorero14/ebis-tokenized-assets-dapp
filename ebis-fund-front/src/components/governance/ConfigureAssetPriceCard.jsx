import { useState } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { useAssets } from '../../context/AssetsContext';
import { ethers } from 'ethers';
import PrimaryMarketABI from '../../contracts/PrimaryMarketABI.json';
import { waitForTransaction } from '../../utils/txUtils';

const PRIMARY_MARKET_ADDRESS = import.meta.env.VITE_PRIMARY_MARKET_ADDRESS;

function ConfigureAssetPriceCard() {
    const { account, provider, isConnected } = useWeb3();
    const { assets, isLoading: assetsLoading } = useAssets();
    const [selectedAssetId, setSelectedAssetId] = useState('');
    const [price, setPrice] = useState('');
    const [status, setStatus] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (!selectedAssetId) {
            setStatus('❌ Please select an asset');
            return;
        }

        if (!price || parseFloat(price) <= 0) {
            setStatus('❌ Price must be greater than 0');
            return;
        }

        try {
            setIsLoading(true);
            setStatus('⏳ Configuring asset price...');

            const signer = await provider.getSigner();
            const contract = new ethers.Contract(
                PRIMARY_MARKET_ADDRESS,
                PrimaryMarketABI,
                signer
            );

            /**
             * CONFIGURACIÓN DE PRECIO EN PRIMARY MARKET
             * 
             * configureAsset(assetId, price):
             * - Establece el precio de un asset en el mercado primario
             * - El precio se almacena en wei (6 decimales para DEUR)
             * - Requiere rol FUND_MANAGER_ROLE
             * - Emite evento AssetConfigured(assetId, price)
             * 
             * Este precio será usado por buyAsset() para calcular el costo total
             * de la compra: totalPrice = price * amount
             */
            const priceInWei = ethers.parseUnits(price.toString(), 6);

            const tx = await contract.configureAsset(
                parseInt(selectedAssetId),
                priceInWei
            );

            console.log('Transaction sent:', tx.hash);
            setStatus(`⏳ Waiting for confirmation... Tx: ${tx.hash.substring(0, 10)}...`);

            const receipt = await waitForTransaction(tx, provider);

            console.log('Transaction confirmed:', receipt);
            setStatus(`✅ Price configured! Tx: ${receipt.hash.substring(0, 10)}...`);

            // Reset form
            setSelectedAssetId('');
            setPrice('');

            // Clear status after 5 seconds
            setTimeout(() => setStatus(''), 10000);
        } catch (error) {
            console.error('Error configuring price:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('AccessControlUnauthorizedAccount')) {
                setStatus('❌ You do not have FUND_MANAGER_ROLE');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="glass-card">
            <h3 className="card-title">💰 Configure Asset Price</h3>
            <form onSubmit={handleSubmit}>
                <div className="input-group">
                    <label>Asset ID</label>
                    <select
                        value={selectedAssetId}
                        onChange={(e) => setSelectedAssetId(e.target.value)}
                        disabled={isLoading || assetsLoading}
                        style={{
                            width: '100%',
                            padding: '0.75rem',
                            background: 'rgba(255, 255, 255, 0.05)',
                            border: '1px solid rgba(255, 255, 255, 0.1)',
                            borderRadius: '8px',
                            color: '#ffffff',
                            fontSize: '1rem',
                            cursor: 'pointer'
                        }}
                    >
                        <option value="">Select an asset...</option>
                        {assets.map((asset) => (
                            <option key={asset.id} value={asset.id}>
                                {asset.displayName}
                            </option>
                        ))}
                    </select>
                    {assetsLoading && (
                        <small style={{ opacity: 0.7, fontSize: '0.85rem' }}>
                            Loading assets...
                        </small>
                    )}
                    {!assetsLoading && assets.length === 0 && (
                        <small style={{ opacity: 0.7, fontSize: '0.85rem' }}>
                            No assets available. Create one first.
                        </small>
                    )}
                </div>
                <div className="input-group">
                    <label>Price (DEUR)</label>
                    <input
                        type="number"
                        placeholder="e.g., 100"
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        disabled={isLoading}
                        min="0.000001"
                        step="0.000001"
                    />
                    <small style={{ opacity: 0.7, fontSize: '0.85rem', marginTop: '0.25rem' }}>
                        Price per share in Digital Euro
                    </small>
                </div>
                {status && (
                    <div style={{
                        padding: '0.75rem',
                        marginBottom: '1rem',
                        borderRadius: '8px',
                        background: 'rgba(255, 255, 255, 0.05)',
                        fontSize: '0.9rem'
                    }}>
                        {status}
                    </div>
                )}
                <button
                    type="submit"
                    className="btn-primary"
                    disabled={isLoading || !isConnected || assets.length === 0}
                >
                    {isLoading ? 'Setting Price...' : 'Set Price'}
                </button>
            </form>
        </div>
    );
}

export default ConfigureAssetPriceCard;
