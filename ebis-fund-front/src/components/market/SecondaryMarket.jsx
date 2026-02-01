import React from 'react';
import AssetCard from '../shared/AssetCard';

function SecondaryMarket() {
    return (
        <div id="secondary-market" className="market-section">
            <div className="market-controls">
                <div className="search-bar">
                    <svg className="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="11" cy="11" r="8"></circle>
                        <path d="m21 21-4.35-4.35"></path>
                    </svg>
                    <input type="text" placeholder="Search assets..." />
                </div>
            </div>

            <div className="asset-grid">
                <AssetCard bgClass="gold-bg" symbol="GOLD" name="Tokenized Gold" price="€1,875.00">
                    <div className="asset-info">
                        <span className="info-label">Quantity</span>
                        <span className="info-value">25 tokens</span>
                    </div>
                    <div className="asset-info">
                        <span className="info-label">Seller</span>
                        <span className="info-value seller-address">0x7a4...b2c</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="property-bg" symbol="PROP" name="Real Estate Fund" price="€5,350.00">
                    <div className="asset-info">
                        <span className="info-label">Quantity</span>
                        <span className="info-value">10 tokens</span>
                    </div>
                    <div className="asset-info">
                        <span className="info-label">Seller</span>
                        <span className="info-value seller-address">0x3f9...d8a</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="bond-bg" symbol="BOND" name="Corporate Bonds" price="€1,020.00">
                    <div className="asset-info">
                        <span className="info-label">Quantity</span>
                        <span className="info-value">50 tokens</span>
                    </div>
                    <div className="asset-info">
                        <span className="info-label">Seller</span>
                        <span className="info-value seller-address">0x9c2...f1e</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="art-bg" symbol="ART" name="Digital Art #001" price="€3,650.00">
                    <div className="asset-info">
                        <span className="info-label">Quantity</span>
                        <span className="info-value">5 tokens</span>
                    </div>
                    <div className="asset-info">
                        <span className="info-label">Seller</span>
                        <span className="info-value seller-address">0x5e8...a3d</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="gold-bg" symbol="GOLD" name="Tokenized Gold" price="€1,860.00">
                    <div className="asset-info">
                        <span className="info-label">Quantity</span>
                        <span className="info-value">15 tokens</span>
                    </div>
                    <div className="asset-info">
                        <span className="info-label">Seller</span>
                        <span className="info-value seller-address">0x1b4...c7f</span>
                    </div>
                </AssetCard>
            </div>
        </div>
    );
}

export default SecondaryMarket;
