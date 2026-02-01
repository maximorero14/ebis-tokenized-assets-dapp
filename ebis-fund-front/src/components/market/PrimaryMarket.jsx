import React from 'react';
import AssetCard from '../shared/AssetCard';

function PrimaryMarket() {
    return (
        <div id="primary-market" className="market-section">
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
                <AssetCard bgClass="gold-bg" symbol="GOLD" name="Tokenized Gold" price="€1,850.00">
                    <div className="asset-info">
                        <span className="info-label">Available</span>
                        <span className="info-value">1,000 tokens</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="property-bg" symbol="PROP" name="Real Estate Fund" price="€5,200.00">
                    <div className="asset-info">
                        <span className="info-label">Available</span>
                        <span className="info-value">500 tokens</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="bond-bg" symbol="BOND" name="Corporate Bonds" price="€1,000.00">
                    <div className="asset-info">
                        <span className="info-label">Available</span>
                        <span className="info-value">2,500 tokens</span>
                    </div>
                </AssetCard>

                <AssetCard bgClass="art-bg" symbol="ART" name="Digital Art Collection" price="€3,500.00">
                    <div className="asset-info">
                        <span className="info-label">Available</span>
                        <span className="info-value">100 tokens</span>
                    </div>
                </AssetCard>
            </div>
        </div>
    );
}

export default PrimaryMarket;
