import React, { useState } from 'react';
import PrimaryMarket from '../market/PrimaryMarket';
import SecondaryMarket from '../market/SecondaryMarket';

function LiveMarket() {
    const [marketType, setMarketType] = useState('primary');

    return (
        <section id="market" className="section marketplace">
            <h2 className="section-title">Live Market</h2>

            {/* Market Type Tabs */}
            <div className="market-type-tabs">
                <button
                    className={`market-type-btn ${marketType === 'primary' ? 'active' : ''}`}
                    onClick={() => setMarketType('primary')}
                >
                    Primary Market
                </button>
                <button
                    className={`market-type-btn ${marketType === 'secondary' ? 'active' : ''}`}
                    onClick={() => setMarketType('secondary')}
                >
                    Secondary Market
                </button>
            </div>

            {marketType === 'primary' ? <PrimaryMarket /> : <SecondaryMarket />}
        </section>
    );
}

export default LiveMarket;
