import React from 'react';
import TransferCard from '../dashboard/TransferCard';
import HoldingsCard from '../dashboard/HoldingsCard';

function Dashboard() {
    return (
        <section id="dashboard" className="section">
            <h2 className="section-title">Dashboard</h2>
            <div className="dashboard-grid">
                <TransferCard />
                <HoldingsCard />
            </div>
        </section>
    );
}

export default Dashboard;
