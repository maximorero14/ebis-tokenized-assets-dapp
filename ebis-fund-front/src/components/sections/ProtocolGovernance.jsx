import React from 'react';
import { AssetsProvider } from '../../context/AssetsContext';
import MintCBDCCard from '../governance/MintCBDCCard';
import MintAssetCard from '../governance/MintAssetCard';
import AllAssetsList from '../governance/AllAssetsList';
import CreateAssetCard from '../governance/CreateAssetCard';

function ProtocolGovernance() {
    return (
        <section id="governance" className="section">
            <h2 className="section-title">Protocol Governance</h2>
            <AssetsProvider>
                <div className="governance-grid">
                    <MintCBDCCard />
                    <MintAssetCard />
                    <AllAssetsList />
                    <CreateAssetCard />
                </div>
            </AssetsProvider>
        </section>
    );
}

export default ProtocolGovernance;
