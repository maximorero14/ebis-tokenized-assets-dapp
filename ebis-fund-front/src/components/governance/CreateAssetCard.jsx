import React from 'react';

function CreateAssetCard() {
    return (
        <div className="glass-card">
            <h3 className="card-title">✨ Create New Asset</h3>
            <div className="input-group">
                <label>Asset Name</label>
                <input type="text" placeholder="e.g., Gold Token" defaultValue="" />
            </div>
            <div className="input-group">
                <label>Asset Symbol</label>
                <input type="text" placeholder="e.g., GOLD" defaultValue="" />
            </div>
            <div className="input-group">
                <label>Initial Supply</label>
                <input type="number" placeholder="1000" defaultValue="" />
            </div>
            <button className="btn-primary">Create Asset</button>
        </div>
    );
}

export default CreateAssetCard;
