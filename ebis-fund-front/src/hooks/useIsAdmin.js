import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import FinancialAssetsABI from '../contracts/FinancialAssetsABI.json';

const FINANCIAL_ASSETS_ADDRESS = import.meta.env.VITE_FINANCIAL_ASSETS_ADDRESS;

// DEFAULT_ADMIN_ROLE is 0x0000000000000000000000000000000000000000000000000000000000000000
const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

/**
 * Custom hook to check if the connected account has admin role
 * @param {string} account - The connected wallet address
 * @param {object} provider - The ethers provider
 * @returns {boolean} isAdmin - Whether the account has DEFAULT_ADMIN_ROLE
 */
export function useIsAdmin(account, provider) {
    const [isAdmin, setIsAdmin] = useState(false);

    useEffect(() => {
        const checkAdminRole = async () => {
            if (!account || !provider || !FINANCIAL_ASSETS_ADDRESS) {
                setIsAdmin(false);
                return;
            }

            try {
                const contract = new ethers.Contract(
                    FINANCIAL_ASSETS_ADDRESS,
                    FinancialAssetsABI,
                    provider
                );

                // Check if account has DEFAULT_ADMIN_ROLE
                const hasRole = await contract.hasRole(DEFAULT_ADMIN_ROLE, account);
                console.log('🔐 Admin check for', account, ':', hasRole);
                setIsAdmin(hasRole);
            } catch (error) {
                console.error('Error checking admin role:', error);
                setIsAdmin(false);
            }
        };

        checkAdminRole();
    }, [account, provider]);

    return isAdmin;
}
