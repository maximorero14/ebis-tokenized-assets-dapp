import React from 'react';

function AssetCard({ bgClass, symbol, name, price, children }) {
    return (
        <div className="asset-card">
            <div className={`asset-image ${bgClass}`}></div>
            <div className="asset-content">
                <div className="token-symbol">{symbol}</div>
                <div className="asset-name">{name}</div>

                {children}

                <div className="asset-price">
                    <span className="price-label">Price</span>
                    {price}
                </div>
                <button className="btn-buy">Buy Now</button>
            </div>
        </div>
    );
}

export default AssetCard;
