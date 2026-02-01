function Navbar() {
  return (
    <nav className="navbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <img src="/logo.png" alt="EBIS Logo" style={{ height: '40px' }} />
        <div className="logo">EBIS Fund</div>
      </div>
      <div className="wallet-info">
        <div className="balance-display">
          <span className="balance-label">Balance</span>
          <span className="balance-amount">5,000 EURC</span>
        </div>
        <button className="wallet-btn">
          <span className="wallet-address">0x12...89</span>
        </button>
      </div>
    </nav>
  );
}

export default Navbar;
