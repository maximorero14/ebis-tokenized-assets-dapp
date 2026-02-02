import { useState } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { useAssets } from '../../context/AssetsContext';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../../contracts/FinancialAssetsABI.json';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;

function MintAssetCard() {
    const { account, provider, isConnected } = useWeb3();
    const { assets, isLoading: assetsLoading } = useAssets();
    const [formData, setFormData] = useState({
        assetId: '',
        amount: ''
    });
    const [status, setStatus] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (!formData.assetId || !formData.amount) {
            setStatus('❌ Please fill all fields');
            return;
        }

        try {
            setIsLoading(true);
            setStatus('⏳ Minting assets...');

            const signer = await provider.getSigner();
            const contract = new ethers.Contract(
                FINANCIAL_ASSETS_ADDRESS,
                FinancialAssetsABI,
                signer
            );

            // Call mint(uint256 assetId, uint256 amount)
            // Tokens are automatically sent to PrimaryMarket
            const tx = await contract.mint(
                parseInt(formData.assetId),
                parseInt(formData.amount)
            );

            setStatus('⏳ Waiting for confirmation...');
            const receipt = await tx.wait();

            setStatus(`✅ Assets minted to PrimaryMarket! Tx: ${receipt.hash.substring(0, 10)}...`);

            // Reset form
            setFormData({ assetId: '', amount: '' });

            // Clear status after 5 seconds
            setTimeout(() => setStatus(''), 5000);
        } catch (error) {
            console.error('Error minting assets:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('InvalidAssetId')) {
                setStatus('❌ Invalid asset ID');
            } else if (error.message.includes('PrimaryMarketNotSet')) {
                setStatus('❌ Primary market not configured');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="glass-card">
            <h3 className="card-title">💰 Mint Asset</h3>
            <form onSubmit={handleSubmit}>
                <div className="input-group">
                    <label>Asset ID</label>
                    <select
                        value={formData.assetId}
                        onChange={(e) => setFormData({ ...formData, assetId: e.target.value })}
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
                    <label>Amount</label>
                    <input
                        type="number"
                        placeholder="100"
                        value={formData.amount}
                        onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                        disabled={isLoading}
                        min="1"
                    />
                    <small style={{ opacity: 0.7, fontSize: '0.85rem' }}>
                        Tokens will be minted to PrimaryMarket contract
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
                    {isLoading ? 'Minting...' : 'Mint Asset'}
                </button>
            </form>
        </div>
    );
}

export default MintAssetCard;
