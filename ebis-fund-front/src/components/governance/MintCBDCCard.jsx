import React from 'react';

function MintCBDCCard() {
    return (
        <div className="glass-card">
            <h3 className="card-title">🪙 Mint CBDC</h3>
            <div className="input-group">
                <label>Recipient Address</label>
                <input type="text" placeholder="0x..." defaultValue="" />
            </div>
            <div className="input-group">
                <label>Amount (EUR)</label>
                <input type="number" placeholder="1000.00" defaultValue="" />
            </div>
            <button className="btn-primary">Mint CBDC</button>
        </div>
    );
}

export default MintCBDCCard;
