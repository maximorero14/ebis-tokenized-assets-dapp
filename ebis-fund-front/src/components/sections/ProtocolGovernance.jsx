import React from 'react';
import MintCBDCCard from '../governance/MintCBDCCard';
import MintAssetCard from '../governance/MintAssetCard';
import AllAssetsList from '../governance/AllAssetsList';
import CreateAssetCard from '../governance/CreateAssetCard';

function ProtocolGovernance() {
    return (
        <section id="governance" className="section">
            <h2 className="section-title">Protocol Governance</h2>
            <div className="governance-grid">
                <MintCBDCCard />
                <MintAssetCard />
                <AllAssetsList />
                <CreateAssetCard />
            </div>
        </section>
    );
}

export default ProtocolGovernance;
