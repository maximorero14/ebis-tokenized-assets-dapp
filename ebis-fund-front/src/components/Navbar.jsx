import { useWeb3 } from '../context/Web3Context';
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import DigitalEuroABI from '../contracts/DigitalEuroABI.json';

// Get contract address from environment variables
const DIGITAL_EURO_ADDRESS = import.meta.env.VITE_DIGITAL_EURO_ADDRESS;

function Navbar() {
  const { account, connectWallet, disconnectWallet, isConnected, provider } = useWeb3();
  const [isHovered, setIsHovered] = useState(false);
  const [balance, setBalance] = useState('0');
  const [isLoadingBalance, setIsLoadingBalance] = useState(false);

  /**
   * CONSULTA DE BALANCE EN BLOCKCHAIN (OPERACIÓN DE LECTURA)
   * 
   * 1. Creamos una instancia del contrato con:
   *    - Dirección del contrato (donde está desplegado en blockchain)
   *    - ABI (interfaz que define las funciones del contrato)
   *    - Provider (para leer de blockchain, NO necesita signer)
   * 
   * 2. Llamamos balanceOf(account): función view del contrato ERC-20
   *    - No requiere gas (es solo lectura)
   *    - Retorna el balance en unidades mínimas (wei para ETH, pero aquí usa 6 decimales)
   * 
   * 3. Convertimos de unidades mínimas a unidades legibles con formatUnits
   */
  useEffect(() => {
    const fetchBalance = async () => {
      if (!account || !provider || !DIGITAL_EURO_ADDRESS) {
        setBalance('0');
        return;
      }

      try {
        setIsLoadingBalance(true);

        const contract = new ethers.Contract(
          DIGITAL_EURO_ADDRESS,
          DigitalEuroABI,
          provider
        );

        const balanceWei = await contract.balanceOf(account);
        const decimals = await contract.decimals();

        const formattedBalance = ethers.formatUnits(balanceWei, decimals);

        const balanceNumber = parseFloat(formattedBalance);
        const balanceFormatted = balanceNumber.toLocaleString('en-US', {
          minimumFractionDigits: 0,
          maximumFractionDigits: 2
        });

        setBalance(balanceFormatted);
      } catch (error) {
        console.error('Error fetching DEUR balance:', error);
        setBalance('0');
      } finally {
        setIsLoadingBalance(false);
      }
    };

    fetchBalance();

    const interval = setInterval(fetchBalance, 10000);

    return () => clearInterval(interval);
  }, [account, provider]);

  // Format address to show first 6 and last 4 characters
  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const handleWalletClick = () => {
    if (isConnected) {
      disconnectWallet();
    } else {
      connectWallet();
    }
  };

  // Get button text based on state
  const getButtonText = () => {
    if (!isConnected) {
      return 'Connect';
    }
    if (isHovered) {
      return 'Disconnect';
    }
    return formatAddress(account);
  };

  return (
    <nav className="navbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <img src="/logo.png" alt="EBIS Logo" style={{ height: '70px', width: 'auto' }} />
        <div className="logo">EBIS Fund</div>
      </div>
      <div className="wallet-info">
        {isConnected && (
          <div className="balance-display">
            <span className="balance-label">Balance</span>
            <span className="balance-amount">
              {isLoadingBalance ? 'Loading...' : `${balance} DEUR`}
            </span>
          </div>
        )}
        <button
          className="wallet-btn"
          onClick={handleWalletClick}
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          <span className="wallet-address">
            {getButtonText()}
          </span>
        </button>
      </div>
    </nav>
  );
}

export default Navbar;

