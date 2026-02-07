// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DigitalEuro} from "../src/DigitalEuro.sol";
import {FinancialAssets} from "../src/FinancialAssets.sol";
import {PrimaryMarket} from "../src/PrimaryMarket.sol";
import {SecondaryMarket} from "../src/SecondaryMarket.sol";

/**
 * FULL SYSTEM DEMO - Complete Happy Path
 *
 * This demo demonstrates the complete lifecycle of the tokenized investment fund platform:
 *
 * 1. Setup: Deploy all contracts
 * 2. Fund Creation: Create investment fund assets
 * 3. Primary Market: Investors buy shares (IPO)
 * 4. Secondary Market: Investors trade shares P2P
 * 5. Complete Workflow: From fund creation to secondary trading
 *
 * This represents a realistic user journey showing how all contracts work together.
 *
 * Usage: forge script script/FullSystemDemo.s.sol --rpc-url sepolia --account main_sepolia --broadcast
 */
contract FullSystemDemo is Script {
    // Constants for DEUR (6 decimals)
    uint256 constant DEUR = 1e6;

    // Deployed contracts
    DigitalEuro digitalEuro;
    FinancialAssets financialAssets;
    PrimaryMarket primaryMarket;
    SecondaryMarket secondaryMarket;

    // Actors
    address fundManager;
    address investor1;
    address investor2;
    address investor3;

    uint256 fundManagerPk;
    uint256 investor1Pk;
    uint256 investor2Pk;
    uint256 investor3Pk;

    function run() external {
        console.log(
            "\n======================================================================"
        );
        console.log("FULL SYSTEM DEMO - HAPPY PATH");
        console.log(
            "======================================================================"
        );
        console.log("Complete workflow: Fund Creation -> IPO -> P2P Trading\n");

        // Derive accounts from mnemonic
        setupAccounts();

        // Execute all phases
        phase1_SystemDeployment();
        phase2_FundCreation();
        phase3_DEURDistribution();
        phase4_PrimaryMarketIPO();
        phase5_SecondaryMarketListings();
        phase6_SecondaryMarketTrading();
        finalSummary();

        // Show deployed contract addresses
        deploymentSummary();

        console.log("\n==> Full System Demo Completed Successfully!\n");
    }

    function setupAccounts() internal {
        console.log("==> Participants:");

        string memory mnemonic = vm.envString("SEPOLIA_MNEMONIC");
        string memory derivationPath = "m/44'/60'/0'/0/";

        // Derive keys from mnemonic (same as Hardhat config)
        fundManagerPk = vm.deriveKey(mnemonic, derivationPath, 0);
        investor1Pk = vm.deriveKey(mnemonic, derivationPath, 1);
        investor2Pk = vm.deriveKey(mnemonic, derivationPath, 2);
        investor3Pk = vm.deriveKey(mnemonic, derivationPath, 3);

        fundManager = vm.addr(fundManagerPk);
        investor1 = vm.addr(investor1Pk);
        investor2 = vm.addr(investor2Pk);
        investor3 = vm.addr(investor3Pk);

        console.log("   Fund Manager:", fundManager);
        console.log("   Investor 1:  ", investor1);
        console.log("   Investor 2:  ", investor2);
        console.log("   Investor 3:  ", investor3);
    }

    function phase1_SystemDeployment() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 1: SYSTEM DEPLOYMENT");
        console.log(
            "======================================================================\n"
        );

        vm.startBroadcast(fundManagerPk);

        // Deploy Digital Euro
        digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
        console.log("==> Digital Euro (DEUR) deployed");
        console.log("   Address:", address(digitalEuro));

        // Deploy Financial Assets
        string
            memory baseUri = "https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeid42im5sn3kgswi5fgemsql66pp4s75gr62idcwsoxkutqk3odbvy/{id}.json";
        financialAssets = new FinancialAssets(baseUri);
        console.log("\n==> Financial Assets (ERC-1155) deployed");
        console.log("   Address:", address(financialAssets));

        // Deploy Primary Market
        primaryMarket = new PrimaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
        console.log("\n==> Primary Market (IPO) deployed");
        console.log("   Address:", address(primaryMarket));

        // Deploy Secondary Market
        secondaryMarket = new SecondaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
        console.log("\n==> Secondary Market (P2P) deployed");
        console.log("   Address:", address(secondaryMarket));

        // Configure Financial Assets
        console.log("\n==> Configuring Primary Market in Financial Assets...");
        financialAssets.setPrimaryMarket(address(primaryMarket));
        console.log("   Primary Market configured successfully");

        vm.stopBroadcast();
    }

    function phase2_FundCreation() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 2: FUND CREATION & SHARE ISSUANCE");
        console.log(
            "======================================================================\n"
        );

        vm.startBroadcast(fundManagerPk);

        console.log("==> Fund Manager creating investment funds...");

        // Create asset types
        financialAssets.createAssetType(0, "Nexus Technology Fund", "TECH");
        console.log("   Created: Nexus Technology Fund (ID: 0)");

        financialAssets.createAssetType(
            1,
            "Goldstone Precious Metals Fund",
            "GOLD"
        );
        console.log("   Created: Goldstone Precious Metals Fund (ID: 1)");

        financialAssets.createAssetType(
            2,
            "Apex Real Estate Capital Fund",
            "REAL"
        );
        console.log("   Created: Apex Real Estate Capital Fund (ID: 2)");

        financialAssets.createAssetType(
            3,
            "Green Future Sustainable Energy Fund",
            "GREEN"
        );
        console.log("   Created: Green Future Sustainable Energy Fund (ID: 3)");

        financialAssets.createAssetType(
            4,
            "MediCare Healthcare & Biotech Fund",
            "HEALTH"
        );
        console.log("   Created: MediCare Healthcare & Biotech Fund (ID: 4)");

        console.log("\n==> Fund Manager issuing shares to Primary Market...");

        financialAssets.mint(0, 1000);
        console.log("   Issued 1,000 TECH shares");

        financialAssets.mint(1, 500);
        console.log("   Issued 500 GOLD shares");

        financialAssets.mint(2, 750);
        console.log("   Issued 750 REAL shares");

        financialAssets.mint(3, 800);
        console.log("   Issued 800 GREEN shares");

        financialAssets.mint(4, 600);
        console.log("   Issued 600 HEALTH shares");

        console.log("\n==> Fund Manager setting IPO prices...");

        primaryMarket.configureAsset(0, 100 * DEUR);
        console.log("   TECH: 100 DEUR per share");

        primaryMarket.configureAsset(1, 200 * DEUR);
        console.log("   GOLD: 200 DEUR per share");

        primaryMarket.configureAsset(2, 150 * DEUR);
        console.log("   REAL: 150 DEUR per share");

        primaryMarket.configureAsset(3, 80 * DEUR);
        console.log("   GREEN: 80 DEUR per share");

        primaryMarket.configureAsset(4, 250 * DEUR);
        console.log("   HEALTH: 250 DEUR per share");

        vm.stopBroadcast();
    }

    function phase3_DEURDistribution() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 3: CENTRAL BANK - DEUR DISTRIBUTION");
        console.log(
            "======================================================================\n"
        );

        vm.startBroadcast(fundManagerPk);

        console.log("==> Central Bank minting Digital Euro to investors...");

        digitalEuro.mint(investor1, 50000 * DEUR);
        console.log("   Investor 1: 50,000 DEUR");

        digitalEuro.mint(investor2, 30000 * DEUR);
        console.log("   Investor 2: 30,000 DEUR");

        digitalEuro.mint(investor3, 40000 * DEUR);
        console.log("   Investor 3: 40,000 DEUR");

        console.log("   DEUR distributed - Investors ready to trade");

        vm.stopBroadcast();
    }

    function phase4_PrimaryMarketIPO() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 4: PRIMARY MARKET - IPO PURCHASES");
        console.log(
            "======================================================================\n"
        );

        // Investor 1 purchases
        console.log(
            "==> Investor 1: Purchasing from IPO (Tech-focused strategy)..."
        );
        vm.startBroadcast(investor1Pk);

        digitalEuro.approve(address(primaryMarket), 30000 * DEUR);
        primaryMarket.buyAsset(0, 100); // 100 TECH @ 100 = 10,000
        console.log("   Bought 100 TECH shares for 10,000 DEUR");

        primaryMarket.buyAsset(1, 50); // 50 GOLD @ 200 = 10,000
        console.log("   Bought 50 GOLD shares for 10,000 DEUR");
        console.log("   Total spent: 20,000 DEUR");

        vm.stopBroadcast();

        // Investor 2 purchases
        console.log(
            "\n==> Investor 2: Purchasing from IPO (ESG-focused strategy)..."
        );
        vm.startBroadcast(investor2Pk);

        digitalEuro.approve(address(primaryMarket), 25000 * DEUR);
        primaryMarket.buyAsset(3, 100); // 100 GREEN @ 80 = 8,000
        console.log("   Bought 100 GREEN shares for 8,000 DEUR");

        primaryMarket.buyAsset(2, 80); // 80 REAL @ 150 = 12,000
        console.log("   Bought 80 REAL shares for 12,000 DEUR");
        console.log("   Total spent: 20,000 DEUR");

        vm.stopBroadcast();

        // Investor 3 purchases
        console.log(
            "\n==> Investor 3: Purchasing from IPO (Balanced strategy)..."
        );
        vm.startBroadcast(investor3Pk);

        digitalEuro.approve(address(primaryMarket), 35000 * DEUR);
        primaryMarket.buyAsset(4, 60); // 60 HEALTH @ 250 = 15,000
        console.log("   Bought 60 HEALTH shares for 15,000 DEUR");

        primaryMarket.buyAsset(1, 30); // 30 GOLD @ 200 = 6,000
        console.log("   Bought 30 GOLD shares for 6,000 DEUR");

        primaryMarket.buyAsset(0, 50); // 50 TECH @ 100 = 5,000
        console.log("   Bought 50 TECH shares for 5,000 DEUR");
        console.log("   Total spent: 26,000 DEUR");

        vm.stopBroadcast();

        // IPO Results
        console.log("\n==> IPO Results:");
        uint256 treasuryBalance = digitalEuro.balanceOf(fundManager);
        console.log("   Fund Treasury raised (DEUR):", treasuryBalance / DEUR);

        console.log("   TECH remaining:", primaryMarket.getAvailableSupply(0));
        console.log("   GOLD remaining:", primaryMarket.getAvailableSupply(1));
        console.log("   REAL remaining:", primaryMarket.getAvailableSupply(2));
        console.log("   GREEN remaining:", primaryMarket.getAvailableSupply(3));
        console.log(
            "   HEALTH remaining:",
            primaryMarket.getAvailableSupply(4)
        );
    }

    function phase5_SecondaryMarketListings() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 5: SECONDARY MARKET - CREATING LISTINGS");
        console.log(
            "======================================================================\n"
        );

        console.log(
            "==> Scenario: Investors creating listings for various funds"
        );

        // Investor 1 approves and lists
        vm.startBroadcast(investor1Pk);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        vm.stopBroadcast();

        // Investor 2 approves
        vm.startBroadcast(investor2Pk);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        vm.stopBroadcast();

        console.log("   Approvals granted to Secondary Market");

        // Investor 1 lists TECH
        console.log("\n==> Investor 1: Listing TECH shares at premium...");
        vm.startBroadcast(investor1Pk);
        secondaryMarket.createListing(0, 60, 120 * DEUR); // 60 TECH @ 120 DEUR (20% premium)
        console.log(
            "   Listing 0: 60 TECH @ 120 DEUR/share (20% premium over IPO)"
        );
        console.log("   60 TECH shares locked in escrow");
        vm.stopBroadcast();

        // Investor 2 lists GREEN
        console.log("\n==> Investor 2: Listing GREEN shares...");
        vm.startBroadcast(investor2Pk);
        secondaryMarket.createListing(3, 50, 85 * DEUR); // 50 GREEN @ 85 DEUR (6% premium)
        console.log(
            "   Listing 1: 50 GREEN @ 85 DEUR/share (6% premium over IPO)"
        );
        console.log("   50 GREEN shares locked in escrow");
        vm.stopBroadcast();
    }

    function phase6_SecondaryMarketTrading() internal {
        console.log(
            "\n======================================================================"
        );
        console.log("PHASE 6: SECONDARY MARKET - P2P TRADING (DvP)");
        console.log(
            "======================================================================\n"
        );

        // Trade 1: Investor 2 buys TECH from Investor 1
        console.log(
            "==> Trade 1: Investor 2 buys TECH from Investor 1's listing"
        );
        console.log(
            "\n==> Investor 2: Purchasing TECH from Secondary Market..."
        );

        vm.startBroadcast(investor2Pk);
        digitalEuro.approve(address(secondaryMarket), 6000 * DEUR);
        secondaryMarket.executeTrade(0, 40); // Buy 40 TECH from listing 0
        console.log(
            "   Bought 40 TECH from Investor 1 for 4,800 DEUR (40 x 120)"
        );
        console.log(
            "   Atomic DvP: DEUR payment + Asset delivery in 1 transaction"
        );
        vm.stopBroadcast();

        uint256 inv2Tech = financialAssets.balanceOf(investor2, 0);
        console.log("\n   Investor 2 now has (TECH):", inv2Tech);
        console.log("   Investor 1 received: 4,800 DEUR");

        // Trade 2: Investor 3 buys GREEN from Investor 2
        console.log(
            "\n==> Trade 2: Investor 3 buys GREEN from Investor 2's listing"
        );
        console.log(
            "\n==> Investor 3: Purchasing GREEN from Secondary Market..."
        );

        vm.startBroadcast(investor3Pk);
        digitalEuro.approve(address(secondaryMarket), 5000 * DEUR);
        secondaryMarket.executeTrade(1, 30); // Buy 30 GREEN from listing 1
        console.log(
            "   Bought 30 GREEN from Investor 2 for 2,550 DEUR (30 x 85)"
        );
        console.log(
            "   Atomic DvP: DEUR payment + Asset delivery in 1 transaction"
        );
        vm.stopBroadcast();

        uint256 inv3Green = financialAssets.balanceOf(investor3, 3);
        console.log("\n   Investor 3 now has (GREEN):", inv3Green);
        console.log("   Investor 2 received: 2,550 DEUR");
    }

    function finalSummary() internal view {
        console.log(
            "\n======================================================================"
        );
        console.log("FINAL PORTFOLIO SUMMARY");
        console.log(
            "======================================================================\n"
        );

        // Investor 1
        uint256 inv1TechFinal = financialAssets.balanceOf(investor1, 0);
        uint256 inv1GoldFinal = financialAssets.balanceOf(investor1, 1);
        uint256 inv1DEURFinal = digitalEuro.balanceOf(investor1);

        console.log("==> Investor 1 (Tech + Precious Metals):");
        console.log("   TECH shares:", inv1TechFinal);
        console.log("   GOLD shares:", inv1GoldFinal);
        console.log("   DEUR balance:", inv1DEURFinal / DEUR);
        console.log(
            "   Strategy: IPO investor who sold TECH at premium (120 vs 100 IPO)"
        );
        console.log(
            "   P2P Profit (DEUR):",
            ((120 * DEUR - 100 * DEUR) * 40) / DEUR
        );

        // Investor 2
        uint256 inv2TechFinal = financialAssets.balanceOf(investor2, 0);
        uint256 inv2GreenFinal = financialAssets.balanceOf(investor2, 3);
        uint256 inv2RealFinal = financialAssets.balanceOf(investor2, 2);
        uint256 inv2DEURFinal = digitalEuro.balanceOf(investor2);

        console.log("\n==> Investor 2 (ESG-focused + TECH):");
        console.log("   TECH shares:", inv2TechFinal);
        console.log("   GREEN shares:", inv2GreenFinal);
        console.log("   REAL shares:", inv2RealFinal);
        console.log("   DEUR balance:", inv2DEURFinal / DEUR);
        console.log(
            "   Strategy: ESG focus with opportunistic TECH purchase on secondary"
        );

        // Investor 3
        uint256 inv3TechFinal = financialAssets.balanceOf(investor3, 0);
        uint256 inv3GoldFinal = financialAssets.balanceOf(investor3, 1);
        uint256 inv3GreenFinal = financialAssets.balanceOf(investor3, 3);
        uint256 inv3HealthFinal = financialAssets.balanceOf(investor3, 4);
        uint256 inv3DEURFinal = digitalEuro.balanceOf(investor3);

        console.log("\n==> Investor 3 (Balanced Diversification):");
        console.log("   TECH shares:", inv3TechFinal);
        console.log("   GOLD shares:", inv3GoldFinal);
        console.log("   GREEN shares:", inv3GreenFinal);
        console.log("   HEALTH shares:", inv3HealthFinal);
        console.log("   DEUR balance:", inv3DEURFinal / DEUR);
        console.log(
            "   Strategy: Well-diversified portfolio across 4 different fund types"
        );

        // Fund Treasury
        uint256 finalTreasury = digitalEuro.balanceOf(fundManager);
        console.log("\n==> Fund Treasury:");
        console.log("   Total raised from IPO (DEUR):", finalTreasury / DEUR);
        console.log(
            "   Deployment: Available for fund management and investments"
        );

        // Market Statistics
        console.log("\n==> Market Statistics:");
        console.log("   IPO Performance:");

        uint256 techSold = 1000 - primaryMarket.getAvailableSupply(0);
        uint256 goldSold = 500 - primaryMarket.getAvailableSupply(1);
        uint256 realSold = 750 - primaryMarket.getAvailableSupply(2);
        uint256 greenSold = 800 - primaryMarket.getAvailableSupply(3);
        uint256 healthSold = 600 - primaryMarket.getAvailableSupply(4);

        console.log("   - TECH sold:", techSold);
        console.log("   - GOLD sold:", goldSold);
        console.log("   - REAL sold:", realSold);
        console.log("   - GREEN sold:", greenSold);
        console.log("   - HEALTH sold:", healthSold);

        uint256 secondaryVolume = (120 * DEUR * 40 + 85 * DEUR * 30) / DEUR;
        console.log("   Secondary Market Volume (DEUR):", secondaryVolume);

        // Key Features
        console.log(
            "\n======================================================================"
        );
        console.log("KEY FEATURES DEMONSTRATED");
        console.log(
            "======================================================================\n"
        );

        console.log("==> Complete System Integration:");
        console.log("   - All 4 contracts working together seamlessly");
        console.log("   - 5 diverse fund types created and traded");
        console.log("   - Realistic user journey from IPO to P2P trading");
        console.log("   - Multiple investment strategies demonstrated");

        console.log("\n==> DvP (Delivery vs Payment) Settlement:");
        console.log("   - Primary Market: Atomic DEUR <-> Asset swap");
        console.log("   - Secondary Market: Atomic P2P settlement");
        console.log("   - Multiple listings and trades executed");
        console.log("   - Zero counterparty risk");

        console.log("\n==> Market Functionality:");
        console.log("   - Primary Market (IPO) for initial distribution");
        console.log(
            "   - Secondary Market (P2P) for price discovery and liquidity"
        );
        console.log("   - Partial fills enabling liquidity");
        console.log("   - Asset escrow protecting both parties");

        console.log("\n==> Tokenization Benefits:");
        console.log("   - 24/7 trading capability");
        console.log("   - Fractional ownership (can buy 1 share)");
        console.log("   - Instant settlement (no T+2 delays)");
        console.log("   - Transparent on-chain history");
        console.log("   - Programmable compliance (via roles)");
    }

    function deploymentSummary() internal view {
        console.log(
            "\n======================================================================"
        );
        console.log("DEPLOYED CONTRACT ADDRESSES");
        console.log(
            "======================================================================\n"
        );

        console.log("==> Core Contracts:");
        console.log("   DigitalEuro (DEUR):     ", address(digitalEuro));
        console.log("   FinancialAssets (ERC1155):", address(financialAssets));
        console.log("   PrimaryMarket (IPO):    ", address(primaryMarket));
        console.log("   SecondaryMarket (P2P):  ", address(secondaryMarket));

        console.log(
            "======================================================================"
        );
    }
}
