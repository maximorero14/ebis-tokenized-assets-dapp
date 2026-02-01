import React from 'react';

function MintAssetCard() {
    return (
        <div className="glass-card">
            <h3 className="card-title">💰 Mint Asset</h3>
            <div className="input-group">
                <label>Asset ID</label>
                <input type="number" placeholder="e.g., 1" defaultValue="" />
            </div>
            <div className="input-group">
                <label>Mint Quantity</label>
                <input type="number" placeholder="100" defaultValue="" />
            </div>
            <button className="btn-primary">Mint Asset</button>
        </div>
    );
}

export default MintAssetCard;
