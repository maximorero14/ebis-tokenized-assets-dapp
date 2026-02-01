import { createContext, useContext, useState, useEffect } from 'react';
import { ethers } from 'ethers';
import Onboard from '@web3-onboard/core';
import injectedModule from '@web3-onboard/injected-wallets';
import walletConnectModule from '@web3-onboard/walletconnect';

const Web3Context = createContext();

// Initialize Web3-Onboard
const injected = injectedModule();

// NOTA: Para usar WalletConnect (código QR), necesitas un Project ID gratuito de https://cloud.walletconnect.com
// Por ahora lo dejamos comentado para que funcione directo con MetaMask (Browser Extension)
/*
const walletConnect = walletConnectModule({
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
  requiredChains: [11155111],
});
*/

const onboard = Onboard({
    wallets: [injected /*, walletConnect */], // Descomentar si consigues el Project ID
    chains: [
        {
            id: '0xaa36a7', // 11155111 in hex (Sepolia)
            token: 'ETH',
            label: 'Sepolia Testnet',
            // RPC Público gratuito para Sepolia (No requiere API Key para pruebas básicas)
            rpcUrl: 'https://rpc.sepolia.org'
        }
    ],
    appMetadata: {
        name: 'EBIS Fund',
        icon: '/logo.png',
        description: 'Tokenized Assets Trading Platform',
        recommendedInjectedWallets: [
            { name: 'MetaMask', url: 'https://metamask.io' },
            { name: 'Coinbase', url: 'https://wallet.coinbase.com/' }
        ]
    },
    accountCenter: {
        desktop: {
            enabled: false
        },
        mobile: {
            enabled: false
        }
    }
});

export function Web3Provider({ children }) {
    const [wallet, setWallet] = useState(null);
    const [account, setAccount] = useState(null);
    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);
    const [chainId, setChainId] = useState(null);

    // Connect wallet
    const connectWallet = async () => {
        try {
            const wallets = await onboard.connectWallet();

            if (wallets[0]) {
                const ethersProvider = new ethers.BrowserProvider(wallets[0].provider);
                const ethersSigner = await ethersProvider.getSigner();
                const address = await ethersSigner.getAddress();
                const network = await ethersProvider.getNetwork();

                setWallet(wallets[0]);
                setAccount(address);
                setProvider(ethersProvider);
                setSigner(ethersSigner);
                setChainId(Number(network.chainId));

                // Save wallet to localStorage
                localStorage.setItem('selectedWallet', wallets[0].label);
            }
        } catch (error) {
            console.error('Error connecting wallet:', error);
        }
    };

    // Disconnect wallet
    const disconnectWallet = async () => {
        if (wallet) {
            await onboard.disconnectWallet({ label: wallet.label });
            setWallet(null);
            setAccount(null);
            setProvider(null);
            setSigner(null);
            setChainId(null);
            localStorage.removeItem('selectedWallet');
        }
    };

    // Auto-reconnect on page load
    useEffect(() => {
        const previouslySelectedWallet = localStorage.getItem('selectedWallet');

        if (previouslySelectedWallet) {
            onboard.connectWallet({
                autoSelect: { label: previouslySelectedWallet, disableModals: true }
            }).then(wallets => {
                if (wallets[0]) {
                    const ethersProvider = new ethers.BrowserProvider(wallets[0].provider);
                    ethersProvider.getSigner().then(ethersSigner => {
                        ethersSigner.getAddress().then(address => {
                            ethersProvider.getNetwork().then(network => {
                                setWallet(wallets[0]);
                                setAccount(address);
                                setProvider(ethersProvider);
                                setSigner(ethersSigner);
                                setChainId(Number(network.chainId));
                            });
                        });
                    });
                }
            }).catch(err => {
                console.error('Auto-reconnect failed:', err);
                localStorage.removeItem('selectedWallet');
            });
        }
    }, []);

    // Listen for account changes
    useEffect(() => {
        if (wallet && wallet.provider) {
            const handleAccountsChanged = async (accounts) => {
                if (accounts.length === 0) {
                    disconnectWallet();
                } else {
                    const ethersProvider = new ethers.BrowserProvider(wallet.provider);
                    const ethersSigner = await ethersProvider.getSigner();
                    const address = await ethersSigner.getAddress();
                    setAccount(address);
                    setSigner(ethersSigner);
                }
            };

            const handleChainChanged = async (chainIdHex) => {
                const newChainId = parseInt(chainIdHex, 16);
                setChainId(newChainId);

                if (wallet.provider) {
                    const ethersProvider = new ethers.BrowserProvider(wallet.provider);
                    setProvider(ethersProvider);
                    const ethersSigner = await ethersProvider.getSigner();
                    setSigner(ethersSigner);
                }
            };

            wallet.provider.on('accountsChanged', handleAccountsChanged);
            wallet.provider.on('chainChanged', handleChainChanged);

            return () => {
                wallet.provider.removeListener('accountsChanged', handleAccountsChanged);
                wallet.provider.removeListener('chainChanged', handleChainChanged);
            };
        }
    }, [wallet]);

    const value = {
        wallet,
        account,
        provider,
        signer,
        chainId,
        connectWallet,
        disconnectWallet,
        isConnected: !!account
    };

    return <Web3Context.Provider value={value}>{children}</Web3Context.Provider>;
}

export function useWeb3() {
    const context = useContext(Web3Context);
    if (!context) {
        throw new Error('useWeb3 must be used within a Web3Provider');
    }
    return context;
}
