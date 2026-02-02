import React, { createContext, useContext, useEffect, useRef } from 'react';
import { useWeb3 } from './Web3Context';
import { useAssetsList } from '../hooks/useAssetsList';

const AssetsContext = createContext();

/**
 * Provider component that manages assets state for the entire application
 * - Provides a single source of truth for all assets
 * - Automatically polls for new assets every 30 seconds
 * - Exposes refresh function for manual updates (e.g., after asset creation)
 */
export function AssetsProvider({ children }) {
    const { provider } = useWeb3();
    const { assets, isLoading, refresh } = useAssetsList(provider);
    const intervalRef = useRef(null);

    // Set up automatic polling every 30 seconds
    useEffect(() => {
        if (!provider) {
            // Clear interval if provider is not available
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
                intervalRef.current = null;
            }
            return;
        }

        // Set up polling interval
        intervalRef.current = setInterval(() => {
            console.log('🔄 Auto-polling for new assets...');
            refresh();
        }, 30000); // 30 seconds

        // Cleanup on unmount or provider change
        return () => {
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
                intervalRef.current = null;
            }
        };
    }, [provider, refresh]);

    const value = {
        assets,
        isLoading,
        refreshAssets: refresh
    };

    return (
        <AssetsContext.Provider value={value}>
            {children}
        </AssetsContext.Provider>
    );
}

/**
 * Custom hook to access assets context
 * @returns {object} { assets, isLoading, refreshAssets }
 */
export function useAssets() {
    const context = useContext(AssetsContext);
    if (!context) {
        throw new Error('useAssets must be used within an AssetsProvider');
    }
    return context;
}
