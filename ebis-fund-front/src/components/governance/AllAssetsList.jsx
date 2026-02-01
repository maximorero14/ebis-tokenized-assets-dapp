import { useWeb3 } from '../../context/Web3Context';
import { useAssetsList } from '../../hooks/useAssetsList';

function AllAssetsList() {
    const { provider } = useWeb3();
    const { assets, isLoading, refresh } = useAssetsList(provider);

    return (
        <div className="glass-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                <h3 className="card-title">📋 All Assets</h3>
                <button
                    onClick={refresh}
                    disabled={isLoading}
                    style={{
                        padding: '0.5rem 1rem',
                        background: 'rgba(0, 255, 255, 0.1)',
                        border: '1px solid rgba(0, 255, 255, 0.3)',
                        borderRadius: '8px',
                        color: '#00ffff',
                        cursor: 'pointer',
                        fontSize: '0.85rem'
                    }}
                >
                    {isLoading ? '⏳' : '🔄'} Refresh
                </button>
            </div>

            {isLoading && (
                <div style={{ textAlign: 'center', padding: '2rem', opacity: 0.7 }}>
                    Loading assets...
                </div>
            )}

            {!isLoading && assets.length === 0 && (
                <div style={{ textAlign: 'center', padding: '2rem', opacity: 0.7 }}>
                    No assets created yet. Create your first asset!
                </div>
            )}

            {!isLoading && assets.length > 0 && (
                <div style={{
                    maxHeight: '300px',
                    overflowY: 'auto',
                    paddingRight: '0.5rem'
                }}>
                    {assets.map((asset) => (
                        <div
                            key={asset.id}
                            style={{
                                padding: '1rem',
                                marginBottom: '0.75rem',
                                background: 'rgba(255, 255, 255, 0.03)',
                                border: '1px solid rgba(255, 255, 255, 0.08)',
                                borderRadius: '8px'
                            }}
                        >
                            <div style={{
                                display: 'flex',
                                justifyContent: 'space-between',
                                alignItems: 'center',
                                marginBottom: '0.5rem'
                            }}>
                                <span style={{
                                    fontSize: '1.1rem',
                                    fontWeight: 'bold',
                                    color: '#00ffff'
                                }}>
                                    {asset.symbol}
                                </span>
                                <span style={{
                                    padding: '0.25rem 0.75rem',
                                    background: 'rgba(0, 255, 255, 0.1)',
                                    border: '1px solid rgba(0, 255, 255, 0.3)',
                                    borderRadius: '12px',
                                    fontSize: '0.85rem'
                                }}>
                                    ID: {asset.id}
                                </span>
                            </div>
                            <div style={{
                                fontSize: '0.9rem',
                                opacity: 0.8
                            }}>
                                {asset.name}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            <div style={{
                marginTop: '1rem',
                padding: '0.75rem',
                background: 'rgba(0, 255, 255, 0.05)',
                borderRadius: '8px',
                fontSize: '0.9rem',
                textAlign: 'center'
            }}>
                Total Assets: <strong>{assets.length}</strong>
            </div>
        </div>
    );
}

export default AllAssetsList;
