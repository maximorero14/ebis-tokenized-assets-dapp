import { useWeb3 } from '../context/Web3Context';
import { useState } from 'react';

function Navbar() {
  const { account, connectWallet, disconnectWallet, isConnected } = useWeb3();
  const [isHovered, setIsHovered] = useState(false);

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
            <span className="balance-amount">5,000 EURC</span>
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

