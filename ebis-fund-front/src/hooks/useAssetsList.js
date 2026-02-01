import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../contracts/FinancialAssetsABI.json';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;

/**
 * Custom hook to fetch all existing assets from FinancialAssets contract
 * @param {object} provider - The ethers provider
 * @returns {object} { assets: Array, isLoading: boolean, refresh: function }
 */
export function useAssetsList(provider) {
    const [assets, setAssets] = useState([]);
    const [isLoading, setIsLoading] = useState(false);

    const fetchAssets = async () => {
        if (!provider || !FINANCIAL_ASSETS_ADDRESS) {
            setAssets([]);
            return;
        }

        try {
            setIsLoading(true);
            const contract = new ethers.Contract(
                FINANCIAL_ASSETS_ADDRESS,
                FinancialAssetsABI,
                provider
            );

            const assetsList = [];
            let maxAssetId = 10; // Default check first 10 IDs

            // Try to get asset type count
            try {
                const assetTypeCount = await contract.getAssetTypeCount();
                if (assetTypeCount > 0) {
                    maxAssetId = Math.max(Number(assetTypeCount), 10);
                }
            } catch (error) {
                console.warn('Could not get asset type count:', error);
            }

            // Fetch each asset
            for (let assetId = 1; assetId <= maxAssetId; assetId++) {
                try {
                    const exists = await contract.assetExists(assetId);
                    if (exists) {
                        const name = await contract.getAssetName(assetId);
                        const symbol = await contract.getAssetSymbol(assetId);

                        assetsList.push({
                            id: assetId,
                            name,
                            symbol,
                            displayName: `${symbol} - ${name} (ID: ${assetId})`
                        });
                    }
                } catch (error) {
                    // Skip assets that don't exist
                    continue;
                }
            }

            console.log('📋 Fetched assets:', assetsList);
            setAssets(assetsList);
        } catch (error) {
            console.error('Error fetching assets list:', error);
            setAssets([]);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchAssets();
    }, [provider]);

    return { assets, isLoading, refresh: fetchAssets };
}
