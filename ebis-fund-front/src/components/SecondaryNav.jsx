import React from 'react';
import { useWeb3 } from '../context/Web3Context';
import { useIsAdmin } from '../hooks/useIsAdmin';

function SecondaryNav({ activeSection, setActiveSection }) {
    const { account, provider } = useWeb3();
    const isAdmin = useIsAdmin(account, provider);

    return (
        <nav className="secondary-nav">
            <div className="nav-container">
                <a
                    href="#"
                    onClick={(e) => { e.preventDefault(); setActiveSection('dashboard'); }}
                    className={`nav-link ${activeSection === 'dashboard' ? 'active' : ''}`}
                >
                    Dashboard
                </a>
                {isAdmin && (
                    <a
                        href="#"
                        onClick={(e) => { e.preventDefault(); setActiveSection('governance'); }}
                        className={`nav-link ${activeSection === 'governance' ? 'active' : ''}`}
                    >
                        Protocol Governance
                    </a>
                )}
                <a
                    href="#"
                    onClick={(e) => { e.preventDefault(); setActiveSection('market'); }}
                    className={`nav-link ${activeSection === 'market' ? 'active' : ''}`}
                >
                    Live Market
                </a>
            </div>
        </nav>
    );
}

export default SecondaryNav;

