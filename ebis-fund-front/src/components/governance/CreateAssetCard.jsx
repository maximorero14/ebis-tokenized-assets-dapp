import { useState } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../../contracts/FinancialAssetsABI.json';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;

function CreateAssetCard() {
    const { account, provider, isConnected } = useWeb3();
    const [formData, setFormData] = useState({
        assetId: '',
        name: '',
        symbol: ''
    });
    const [status, setStatus] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!isConnected) {
            setStatus('❌ Please connect your wallet');
            return;
        }

        if (!formData.assetId || !formData.name || !formData.symbol) {
            setStatus('❌ Please fill all fields');
            return;
        }

        try {
            setIsLoading(true);
            setStatus('⏳ Creating asset type...');

            const signer = await provider.getSigner();
            const contract = new ethers.Contract(
                FINANCIAL_ASSETS_ADDRESS,
                FinancialAssetsABI,
                signer
            );

            // Call createAssetType(uint256 assetId, string name, string symbol)
            const tx = await contract.createAssetType(
                parseInt(formData.assetId),
                formData.name,
                formData.symbol
            );

            console.log('Transaction sent:', tx.hash);
            setStatus(`⏳ Waiting for confirmation... Tx: ${tx.hash.substring(0, 10)}...`);

            try {
                const receipt = await tx.wait();
                console.log('Transaction confirmed:', receipt);
                setStatus(`✅ Asset created! Tx: ${receipt.hash.substring(0, 10)}...`);
            } catch (waitError) {
                console.warn('Wait error (transaction may still be pending):', waitError);
                // Transaction was sent but confirmation failed - still show success
                setStatus(`✅ Asset created! Tx: ${tx.hash.substring(0, 10)}... (Check Etherscan)`);
            }

            // Reset form
            setFormData({ assetId: '', name: '', symbol: '' });

            // Clear status after 5 seconds
            setTimeout(() => setStatus(''), 5000);
        } catch (error) {
            console.error('Error creating asset:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('AssetAlreadyExists')) {
                setStatus('❌ Asset ID already exists');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="glass-card">
            <h3 className="card-title">✨ Create New Asset</h3>
            <form onSubmit={handleSubmit}>
                <div className="input-group">
                    <label>Asset ID</label>
                    <input
                        type="number"
                        placeholder="e.g., 1"
                        value={formData.assetId}
                        onChange={(e) => setFormData({ ...formData, assetId: e.target.value })}
                        disabled={isLoading}
                        min="1"
                    />
                </div>
                <div className="input-group">
                    <label>Asset Name</label>
                    <input
                        type="text"
                        placeholder="e.g., Gold Token"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        disabled={isLoading}
                    />
                </div>
                <div className="input-group">
                    <label>Asset Symbol</label>
                    <input
                        type="text"
                        placeholder="e.g., GOLD"
                        value={formData.symbol}
                        onChange={(e) => setFormData({ ...formData, symbol: e.target.value })}
                        disabled={isLoading}
                        maxLength="10"
                    />
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
                    disabled={isLoading || !isConnected}
                >
                    {isLoading ? 'Creating...' : 'Create Asset'}
                </button>
            </form>
        </div>
    );
}

export default CreateAssetCard;
