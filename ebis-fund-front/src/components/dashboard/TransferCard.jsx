import { useState } from 'react';
import { useWeb3 } from '../../context/Web3Context';
import { ethers } from 'ethers';
import DigitalEuroABI from '../../contracts/DigitalEuroABI.json';

const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;

function TransferCard() {
    const { signer, isConnected } = useWeb3();
    const [recipient, setRecipient] = useState('');
    const [amount, setAmount] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [txHash, setTxHash] = useState('');
    const [error, setError] = useState('');

    const handleTransfer = async (e) => {
        e.preventDefault();

        setError('');
        setTxHash('');

        if (!isConnected) {
            setError('Please connect your wallet first');
            return;
        }

        if (!recipient || !ethers.isAddress(recipient)) {
            setError('Please enter a valid Ethereum address');
            return;
        }

        if (!amount || parseFloat(amount) <= 0) {
            setError('Please enter a valid amount');
            return;
        }

        /**
         * ENVÍO DE TRANSACCIÓN A BLOCKCHAIN (OPERACIÓN DE ESCRITURA)
         * 
         * 1. Creamos instancia del contrato con SIGNER (no provider)
         *    - El signer es necesario para firmar transacciones
         *    - Las transacciones modifican el estado de blockchain y requieren gas
         * 
         * 2. Convertimos la cantidad de DEUR a unidades mínimas (6 decimales)
         *    - Similar a convertir euros a centavos
         *    - parseUnits convierte "10.5" DEUR a "10500000" unidades mínimas
         * 
         * 3. Ejecutamos transfer() del contrato ERC-20
         *    - Esta llamada crea una transacción que debe ser firmada por el usuario en MetaMask
         *    - La transacción se envía a la red y queda pendiente (status: pending)
         * 
         * 4. Esperamos confirmación con tx.wait()
         *    - La transacción se incluye en un bloque
         *    - Esperamos N confirmaciones (por defecto 1)
         *    - Solo después de wait() sabemos que la transferencia fue exitosa
         */
        try {
            setIsLoading(true);

            const contract = new ethers.Contract(
                DIGITAL_EURO_ADDRESS,
                DigitalEuroABI,
                signer
            );

            const amountInWei = ethers.parseUnits(amount, 6);

            const tx = await contract.transfer(recipient, amountInWei);

            console.log('Transaction sent:', tx.hash);
            setTxHash(tx.hash);

            await tx.wait();

            console.log('Transaction confirmed!');

            setRecipient('');
            setAmount('');

            alert(`✅ Successfully sent ${amount} DEUR!`);

        } catch (err) {
            console.error('Transfer error:', err);

            if (err.code === 'ACTION_REJECTED') {
                setError('Transaction rejected by user');
            } else if (err.message.includes('insufficient funds')) {
                setError('Insufficient DEUR balance');
            } else {
                setError(err.message || 'Transfer failed. Please try again.');
            }
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="glass-card">
            <h3 className="card-title">Transfer DEUR</h3>

            <form onSubmit={handleTransfer}>
                <div className="input-group">
                    <label>Recipient Address</label>
                    <input
                        type="text"
                        placeholder="0x..."
                        value={recipient}
                        onChange={(e) => setRecipient(e.target.value)}
                        disabled={isLoading || !isConnected}
                    />
                </div>

                <div className="input-group">
                    <label>Amount (DEUR)</label>
                    <input
                        type="number"
                        placeholder="0.00"
                        step="0.01"
                        min="0"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        disabled={isLoading || !isConnected}
                    />
                </div>

                {error && (
                    <div style={{
                        color: '#ff6b6b',
                        fontSize: '0.9rem',
                        marginBottom: '1rem',
                        padding: '0.5rem',
                        backgroundColor: 'rgba(255, 107, 107, 0.1)',
                        borderRadius: '4px'
                    }}>
                        ⚠️ {error}
                    </div>
                )}

                {txHash && (
                    <div style={{
                        color: '#51cf66',
                        fontSize: '0.9rem',
                        marginBottom: '1rem',
                        padding: '0.5rem',
                        backgroundColor: 'rgba(81, 207, 102, 0.1)',
                        borderRadius: '4px',
                        wordBreak: 'break-all'
                    }}>
                        ✅ Transaction: <a
                            href={`https://sepolia.etherscan.io/tx/${txHash}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{ color: '#51cf66', textDecoration: 'underline' }}
                        >
                            View on Etherscan
                        </a>
                    </div>
                )}

                <button
                    type="submit"
                    className="btn-primary"
                    disabled={isLoading || !isConnected}
                >
                    {isLoading ? 'Sending...' : isConnected ? 'Send Funds' : 'Connect Wallet'}
                </button>
            </form>
        </div>
    );
}

export default TransferCard;
