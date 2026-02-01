import { useState } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import DigitalEuroABI from '../../contracts/DigitalEuroABI.json';

const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;

function MintCBDCCard() {
    const { account, provider, isConnected } = useWeb3();
    const [formData, setFormData] = useState({
        recipient: '',
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

        if (!formData.recipient || !formData.amount) {
            setStatus('❌ Please fill all fields');
            return;
        }

        // Validate Ethereum address
        if (!ethers.isAddress(formData.recipient)) {
            setStatus('❌ Invalid Ethereum address');
            return;
        }

        try {
            setIsLoading(true);
            setStatus('⏳ Minting DEUR...');

            const signer = await provider.getSigner();
            const contract = new ethers.Contract(
                DIGITAL_EURO_ADDRESS,
                DigitalEuroABI,
                signer
            );

            // Convert amount to wei (6 decimals for DEUR)
            const amountInWei = ethers.parseUnits(formData.amount, 6);

            // Call mint(address to, uint256 amount)
            const tx = await contract.mint(formData.recipient, amountInWei);

            setStatus('⏳ Waiting for confirmation...');
            const receipt = await tx.wait();

            setStatus(`✅ DEUR minted successfully! Tx: ${receipt.hash.substring(0, 10)}...`);

            // Reset form
            setFormData({ recipient: '', amount: '' });

            // Clear status after 5 seconds
            setTimeout(() => setStatus(''), 5000);
        } catch (error) {
            console.error('Error minting DEUR:', error);
            if (error.code === 'ACTION_REJECTED') {
                setStatus('❌ Transaction rejected by user');
            } else if (error.message.includes('AccessControl')) {
                setStatus('❌ You do not have MINTER_ROLE');
            } else {
                setStatus(`❌ Error: ${error.message.substring(0, 50)}...`);
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="glass-card">
            <h3 className="card-title">🪙 Mint DEUR</h3>
            <form onSubmit={handleSubmit}>
                <div className="input-group">
                    <label>Recipient Address</label>
                    <input
                        type="text"
                        placeholder="0x..."
                        value={formData.recipient}
                        onChange={(e) => setFormData({ ...formData, recipient: e.target.value })}
                        disabled={isLoading}
                    />
                </div>
                <div className="input-group">
                    <label>Amount (DEUR)</label>
                    <input
                        type="number"
                        placeholder="1000.00"
                        value={formData.amount}
                        onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                        disabled={isLoading}
                        step="0.01"
                        min="0"
                    />
                    <small style={{ opacity: 0.7, fontSize: '0.85rem' }}>
                        DEUR uses 6 decimals
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
                    disabled={isLoading || !isConnected}
                >
                    {isLoading ? 'Minting...' : 'Mint DEUR'}
                </button>
            </form>
        </div>
    );
}

export default MintCBDCCard;
