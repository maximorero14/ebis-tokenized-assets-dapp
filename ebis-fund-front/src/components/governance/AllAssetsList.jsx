import React from 'react';

function AllAssetsList() {
    return (
        <div className="glass-card">
            <h3 className="card-title">📋 All Assets</h3>
            <div className="assets-list">
                <div className="asset-list-item">
                    <div className="asset-list-info">
                        <div className="asset-id">ID: 0</div>
                        <div className="asset-name">Tokenized Gold</div>
                        <div className="asset-symbol">GOLD</div>
                    </div>
                </div>
                <div className="asset-list-item">
                    <div className="asset-list-info">
                        <div className="asset-id">ID: 1</div>
                        <div className="asset-name">Real Estate Fund</div>
                        <div className="asset-symbol">PROP</div>
                    </div>
                </div>
                <div className="asset-list-item">
                    <div className="asset-list-info">
                        <div className="asset-id">ID: 2</div>
                        <div className="asset-name">Corporate Bonds</div>
                        <div className="asset-symbol">BOND</div>
                    </div>
                </div>
                <div className="asset-list-item">
                    <div className="asset-list-info">
                        <div className="asset-id">ID: 3</div>
                        <div className="asset-name">Fine Art Collection</div>
                        <div className="asset-symbol">ART</div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default AllAssetsList;
