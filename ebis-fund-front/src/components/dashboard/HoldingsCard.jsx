import React from 'react';

function HoldingsCard() {
    return (
        <div className="glass-card">
            <h3 className="card-title">Your Holdings</h3>
            <div className="holdings-list">
                <div className="holding-item">
                    <div className="holding-left">
                        <div className="holding-info">
                            <span className="holding-symbol">GOLD</span>
                            <span className="holding-name">Tokenized Gold</span>
                        </div>
                        <div className="holding-values">
                            <span className="holding-amount">2.5 tokens</span>
                            <span className="holding-price">€4,625</span>
                        </div>
                    </div>
                    <button className="btn-sell">Sell</button>
                </div>
                <div className="holding-item">
                    <div className="holding-left">
                        <div className="holding-info">
                            <span className="holding-symbol">PROP</span>
                            <span className="holding-name">Real Estate Fund</span>
                        </div>
                        <div className="holding-values">
                            <span className="holding-amount">1.0 tokens</span>
                            <span className="holding-price">€5,200</span>
                        </div>
                    </div>
                    <button className="btn-sell">Sell</button>
                </div>
                <div className="holding-item">
                    <div className="holding-left">
                        <div className="holding-info">
                            <span className="holding-symbol">BOND</span>
                            <span className="holding-name">Corporate Bonds</span>
                        </div>
                        <div className="holding-values">
                            <span className="holding-amount">10.0 tokens</span>
                            <span className="holding-price">€10,000</span>
                        </div>
                    </div>
                    <button className="btn-sell">Sell</button>
                </div>
                <div className="holding-item">
                    <div className="holding-left">
                        <div className="holding-info">
                            <span className="holding-symbol">ART</span>
                            <span className="holding-name">Fine Art Collection</span>
                        </div>
                        <div className="holding-values">
                            <span className="holding-amount">0.5 tokens</span>
                            <span className="holding-price">€3,500</span>
                        </div>
                    </div>
                    <button className="btn-sell">Sell</button>
                </div>
            </div>
            <div className="total-value">
                <span>Total Portfolio Value</span>
                <span className="total-amount">€23,325.00</span>
            </div>
        </div>
    );
}

export default HoldingsCard;
