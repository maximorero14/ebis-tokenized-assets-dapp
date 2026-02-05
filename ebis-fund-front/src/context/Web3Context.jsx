import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import Onboard from '@web3-onboard/core';
import injectedModule from '@web3-onboard/injected-wallets';

const Web3Context = createContext();

/**
 * CONFIGURACIÓN DE RED BLOCKCHAIN
 * Estas constantes definen a qué red blockchain nos conectamos (Sepolia Testnet)
 * y se obtienen de las variables de entorno (.env)
 */
const CHAIN_ID = Number(import.meta.env.VITE_CHAIN_ID) || 11155111;
const CHAIN_ID_HEX = import.meta.env.VITE_CHAIN_ID_HEX || '0xaa36a7';
const NETWORK_NAME = import.meta.env.VITE_NETWORK_NAME || 'Sepolia Testnet';
const RPC_URL = import.meta.env.VITE_RPC_URL || 'https://rpc.sepolia.org';
const SELECTED_WALLET_KEY = 'selectedWallet';

const injected = injectedModule();

/**
 * INICIALIZACIÓN DE WEB3-ONBOARD
 * Web3-Onboard es la librería que maneja la conexión con wallets (MetaMask, etc.)
 * y proporciona el "provider" que usaremos para comunicarnos con blockchain
 */
const onboard = Onboard({
    wallets: [injected],
    chains: [
        {
            id: CHAIN_ID_HEX,
            token: 'ETH',
            label: NETWORK_NAME,
            rpcUrl: RPC_URL
        }
    ],
    appMetadata: {
        name: 'EBIS Fund',
        icon: '/logo.png',
        description: 'Tokenized Assets Trading Platform',
        recommendedInjectedWallets: [
            { name: 'MetaMask', url: 'https://metamask.io' }
        ]
    },
    accountCenter: {
        desktop: { enabled: false },
        mobile: { enabled: false }
    }
});

export function Web3Provider({ children }) {
    const [wallet, setWallet] = useState(null);
    const [account, setAccount] = useState(null);
    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);
    const [chainId, setChainId] = useState(null);


    /**
     * INICIALIZACIÓN DEL PROVIDER DE ETHERS.JS
     * 
     * Provider: Permite LEER datos de blockchain (balances, estado de contratos, etc.)
     * Signer: Permite ESCRIBIR en blockchain (enviar transacciones, firmar mensajes)
     * 
     * El wallet del usuario (MetaMask) actúa como "signer" para firmar transacciones
     */
    const initializeProvider = useCallback(async (walletInstance) => {
        try {
            const ethersProvider = new ethers.BrowserProvider(walletInstance.provider);
            const ethersSigner = await ethersProvider.getSigner();
            const address = await ethersSigner.getAddress();
            const network = await ethersProvider.getNetwork();

            return {
                wallet: walletInstance,
                account: address,
                provider: ethersProvider,
                signer: ethersSigner,
                chainId: Number(network.chainId)
            };
        } catch (error) {
            console.error('Error initializing provider:', error);
            throw error;
        }
    }, []);


    const connectWallet = useCallback(async () => {
        try {
            const wallets = await onboard.connectWallet();

            if (wallets[0]) {
                const walletData = await initializeProvider(wallets[0]);

                setWallet(walletData.wallet);
                setAccount(walletData.account);
                setProvider(walletData.provider);
                setSigner(walletData.signer);
                setChainId(walletData.chainId);

                localStorage.setItem(SELECTED_WALLET_KEY, wallets[0].label);
            }
        } catch (error) {
            console.error('Error connecting wallet:', error);
        }
    }, [initializeProvider]);


    const disconnectWallet = useCallback(async () => {
        if (wallet) {
            try {
                await onboard.disconnectWallet({ label: wallet.label });
            } catch (error) {
                console.error('Error disconnecting wallet:', error);
            } finally {
                setWallet(null);
                setAccount(null);
                setProvider(null);
                setSigner(null);
                setChainId(null);
                localStorage.removeItem(SELECTED_WALLET_KEY);
            }
        }
    }, [wallet]);


    useEffect(() => {
        const autoReconnect = async () => {
            const previouslySelectedWallet = localStorage.getItem(SELECTED_WALLET_KEY);

            if (!previouslySelectedWallet) return;

            try {
                const wallets = await onboard.connectWallet({
                    autoSelect: {
                        label: previouslySelectedWallet,
                        disableModals: true
                    }
                });

                if (wallets[0]) {
                    const walletData = await initializeProvider(wallets[0]);

                    setWallet(walletData.wallet);
                    setAccount(walletData.account);
                    setProvider(walletData.provider);
                    setSigner(walletData.signer);
                    setChainId(walletData.chainId);
                }
            } catch (error) {
                console.error('Auto-reconnect failed:', error);
                localStorage.removeItem(SELECTED_WALLET_KEY);
            }
        };

        autoReconnect();
    }, [initializeProvider]);


    /**
     * EVENT LISTENERS DE LA WALLET
     * 
     * accountsChanged: Se dispara cuando el usuario cambia de cuenta en MetaMask
     * chainChanged: Se dispara cuando el usuario cambia de red (ej: de Sepolia a Mainnet)
     * 
     * Estos eventos son nativos de Ethereum Provider API (EIP-1193)
     */
    useEffect(() => {
        if (!wallet?.provider) return;

        const handleAccountsChanged = async (accounts) => {
            try {
                if (accounts.length === 0) {
                    await disconnectWallet();
                } else {
                    const walletData = await initializeProvider(wallet);
                    setAccount(walletData.account);
                    setSigner(walletData.signer);
                }
            } catch (error) {
                console.error('Error handling account change:', error);
            }
        };

        const handleChainChanged = async (chainIdHex) => {
            try {
                const newChainId = parseInt(chainIdHex, 16);
                setChainId(newChainId);

                const walletData = await initializeProvider(wallet);
                setProvider(walletData.provider);
                setSigner(walletData.signer);
            } catch (error) {
                console.error('Error handling chain change:', error);
            }
        };

        wallet.provider.on('accountsChanged', handleAccountsChanged);
        wallet.provider.on('chainChanged', handleChainChanged);


        return () => {
            wallet.provider.off('accountsChanged', handleAccountsChanged);
            wallet.provider.off('chainChanged', handleChainChanged);
        };
    }, [wallet, disconnectWallet, initializeProvider]);

    const value = {
        wallet,
        account,
        provider,
        signer,
        chainId,
        connectWallet,
        disconnectWallet,
        isConnected: !!account,

        isCorrectNetwork: chainId === CHAIN_ID
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