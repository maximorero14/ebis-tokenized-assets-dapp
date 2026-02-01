import React from 'react';

function TransferCard() {
    return (
        <div className="glass-card">
            <h3 className="card-title">Transfer DEUR</h3>
            <div className="input-group">
                <label>Recipient Address</label>
                <input type="text" placeholder="0x..." defaultValue="" />
            </div>
            <div className="input-group">
                <label>Amount (DEUR)</label>
                <input type="number" placeholder="0.00" defaultValue="" />
            </div>
            <button className="btn-primary">Send Funds</button>
        </div>
    );
}

export default TransferCard;
