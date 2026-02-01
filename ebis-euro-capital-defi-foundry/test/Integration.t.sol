// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SecondaryMarket} from "../src/SecondaryMarket.sol";
import {PrimaryMarket} from "../src/PrimaryMarket.sol";
import {DigitalEuro} from "../src/DigitalEuro.sol";
import {FinancialAssets} from "../src/FinancialAssets.sol";
import {
    ERC1155Holder
} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract IntegrationTest is Test, ERC1155Holder {
    SecondaryMarket public secondaryMarket;
    PrimaryMarket public primaryMarket;
    DigitalEuro public digitalEuro;
    FinancialAssets public financialAssets;

    address public owner;
    address public investor1;
    address public investor2;
    address public investor3;
    address public seller1;
    address public seller2;
    address public buyer1;
    address public buyer2;
    address public buyer3;
    address public largeSeller;
    address public newTreasury;

    string public constant BASE_URI =
        "https://api.fondo-inversion.com/assets/{id}.json";
    uint256 public constant TECH_FUND_ID = 1;
    uint256 public constant HEALTH_FUND_ID = 2;
    uint256 public constant GOLD_FUND_ID = 3;

    function setUp() public {
        owner = address(this);
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        investor3 = makeAddr("investor3");
        seller1 = makeAddr("seller1");
        seller2 = makeAddr("seller2");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        buyer3 = makeAddr("buyer3");
        largeSeller = makeAddr("largeSeller");
        newTreasury = makeAddr("newTreasury");

        digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
        financialAssets = new FinancialAssets(BASE_URI);
        primaryMarket = new PrimaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
        secondaryMarket = new SecondaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );

        financialAssets.setPrimaryMarket(address(primaryMarket));
    }

    // Scenario 1: Complete Primary to Secondary Market Flow
    function test_Scenario1_PrimaryToSecondaryFlow() public {
        // Step 2: Asset Creation
        financialAssets.createAssetType(
            TECH_FUND_ID,
            "Technology Innovation Fund",
            "TECH"
        );
        financialAssets.createAssetType(
            HEALTH_FUND_ID,
            "Global Healthcare Fund",
            "HEALTH"
        );

        // Step 3: Minting Shares to Primary Market
        // We act as owner/Fund Manager here since PrimaryMarket is set as primary market
        // But minting in FinancialAssets is restricted to FUND_MANAGER_ROLE (owner has it)
        // Wait, financialAssets.mint is onlyRole(FUND_MANAGER).
        // The implementation in previous tests showed calling mint directly.
        // Let's verify FinancialAssets.sol logic from memory/artifacts.
        // Yes, owner has FUND_MANAGER_ROLE by default.
        // But to mint to PrimaryMarket, we just call mint(id, amount).
        // Wait, PrimaryMarket contract needs to hold the assets to sell them?
        // Let's check PrimaryMarket.sol logic from previous interaction.
        // buyAsset transfers from PrimaryMarket to buyer. So yes, PrimaryMarket needs balance.

        financialAssets.mint(TECH_FUND_ID, 1000);
        financialAssets.mint(HEALTH_FUND_ID, 500);

        // We need to transfer these minted assets to PrimaryMarket contract so it can sell them
        // or mint directly to it?
        // The previous tests used mint(id, amount) which mints to msg.sender (owner).
        // So owner needs to transfer to PrimaryMarket?
        // Let's check how previous PrimaryMarket tests did it.
        // Ah, in PrimaryMarket.t.sol:
        // financialAssets.setPrimaryMarket(address(primaryMarket));
        // ...
        // financialAssets.mint(ASSET_ID_1, 100); -> this mints to msg.sender (test contract)
        // Then we need to transfer to primaryMarket?
        // Wait, PrimaryMarket.sol: buyAsset -> financialAssets.safeTransferFrom(address(this), msg.sender, ...)
        // So yes, PrimaryMarket needs to hold the tokens.
        // In the hardhat test:
        // await financialAssets.write.mint([TECH_FUND_ID, 1000n]);
        // Checks FinancialAssets.sol: mint(id, amount) -> _mint(primaryMarket, id, amount, "") if primaryMarket is set?
        // Or does it mint to msg.sender?
        // Let's assume standard behavior: we need to ensure PrimaryMarket has the tokens.
        // If FinancialAssets.sol mints to `primaryMarket` state variable automatically when called by FUND_MANAGER, that's one thing.
        // If not, we manually transfer.
        // Let's look at `FinancialAssets.sol` (I can't see it now but `PrimaryMarket.t.sol` worked).
        // In `test/PrimaryMarket.t.sol`: `financialAssets.mint(ASSET_ID_1, 100);` was sufficient.
        // AND `financialAssets.setPrimaryMarket(address(primaryMarket));` was called.
        // This implies `mint` might default to sending to `primaryMarket` address if set.
        // Checking `FinancialAssets.sol` snippet from memory:
        // function mint(uint256 id, uint256 amount) external onlyRole(FUND_MANAGER_ROLE) {
        //    _mint(primaryMarket, id, amount, "");
        // }
        // Yes, that seems likely.

        // Step 4: Configure Pricing
        primaryMarket.configureAsset(TECH_FUND_ID, 100 * 10 ** 6);
        primaryMarket.configureAsset(HEALTH_FUND_ID, 250 * 10 ** 6);

        // Step 5: DEUR Distribution
        digitalEuro.mint(investor1, 50000 * 10 ** 6);
        digitalEuro.mint(investor2, 30000 * 10 ** 6);
        digitalEuro.mint(investor3, 20000 * 10 ** 6);

        // Step 6: Primary Market Purchases
        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 50000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 100);
        vm.stopPrank();

        vm.startPrank(investor2);
        digitalEuro.approve(address(primaryMarket), 30000 * 10 ** 6);
        primaryMarket.buyAsset(HEALTH_FUND_ID, 40);
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(investor1, TECH_FUND_ID), 100);
        assertEq(financialAssets.balanceOf(investor2, HEALTH_FUND_ID), 40);
        assertEq(digitalEuro.balanceOf(investor1), 40000 * 10 ** 6); // 50k - 10k
        assertEq(digitalEuro.balanceOf(investor2), 20000 * 10 ** 6); // 30k - 10k

        // Step 7: Secondary Market Listing
        vm.startPrank(investor1);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(TECH_FUND_ID, 50, 120 * 10 ** 6);
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(investor1, TECH_FUND_ID), 50);
        assertEq(
            financialAssets.balanceOf(address(secondaryMarket), TECH_FUND_ID),
            50
        );

        // Step 8: Secondary Market Purchase
        vm.startPrank(investor3);
        digitalEuro.approve(address(secondaryMarket), 20000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 30); // Buy 30 from listing 0
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(investor3, TECH_FUND_ID), 30);
        assertEq(digitalEuro.balanceOf(investor3), 16400 * 10 ** 6); // 20000 - (30 * 120) = 16400

        // Seller gets paid: 30 * 120 = 3600. original balance 40000 -> 43600
        assertEq(digitalEuro.balanceOf(investor1), 43600 * 10 ** 6);

        // Listing updated
        SecondaryMarket.Listing memory listing = secondaryMarket.getListing(0);
        assertEq(listing.amount, 20);
        assertTrue(listing.active);

        // Step 9: Treasury Check
        // Owner is default treasury
        assertEq(digitalEuro.balanceOf(owner), 20000 * 10 ** 6); // 100*100 (10k) + 40*250 (10k) = 20k
    }

    // Scenario 2: Multi-Asset Portfolio Trading
    function test_Scenario2_MultiAssetPortfolio() public {
        // Create assets
        financialAssets.createAssetType(TECH_FUND_ID, "Tech Fund", "TECH");
        financialAssets.createAssetType(
            HEALTH_FUND_ID,
            "Health Fund",
            "HEALTH"
        );
        financialAssets.createAssetType(GOLD_FUND_ID, "Gold Fund", "GOLD");

        // Mint to primary market
        financialAssets.mint(TECH_FUND_ID, 1000);
        financialAssets.mint(HEALTH_FUND_ID, 500);
        financialAssets.mint(GOLD_FUND_ID, 300);

        // Configure prices
        primaryMarket.configureAsset(TECH_FUND_ID, 100 * 10 ** 6);
        primaryMarket.configureAsset(HEALTH_FUND_ID, 200 * 10 ** 6);
        primaryMarket.configureAsset(GOLD_FUND_ID, 500 * 10 ** 6);

        // Sellers buy from Primary Market
        digitalEuro.mint(seller1, 100000 * 10 ** 6);
        digitalEuro.mint(seller2, 150000 * 10 ** 6);

        vm.startPrank(seller1);
        digitalEuro.approve(address(primaryMarket), 100000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 200); // 20k
        primaryMarket.buyAsset(HEALTH_FUND_ID, 100); // 20k
        vm.stopPrank();

        vm.startPrank(seller2);
        digitalEuro.approve(address(primaryMarket), 150000 * 10 ** 6);
        primaryMarket.buyAsset(HEALTH_FUND_ID, 150); // 30k
        primaryMarket.buyAsset(GOLD_FUND_ID, 100); // 50k
        vm.stopPrank();

        // Create Secondary Listings
        vm.startPrank(seller1);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(TECH_FUND_ID, 100, 110 * 10 ** 6); // ID 0
        secondaryMarket.createListing(HEALTH_FUND_ID, 50, 240 * 10 ** 6); // ID 1
        vm.stopPrank();

        vm.startPrank(seller2);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(GOLD_FUND_ID, 50, 480 * 10 ** 6); // ID 2
        vm.stopPrank();

        // Buyers trade
        digitalEuro.mint(buyer1, 50000 * 10 ** 6);
        digitalEuro.mint(buyer2, 40000 * 10 ** 6);

        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 50000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 50); // Buy 50 TECH
        secondaryMarket.executeTrade(2, 20); // Buy 20 GOLD
        vm.stopPrank();

        vm.startPrank(buyer2);
        digitalEuro.approve(address(secondaryMarket), 40000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 30); // Buy 30 TECH
        secondaryMarket.executeTrade(1, 25); // Buy 25 HEALTH
        vm.stopPrank();

        // Verify Portfolios
        assertEq(financialAssets.balanceOf(buyer1, TECH_FUND_ID), 50);
        assertEq(financialAssets.balanceOf(buyer1, GOLD_FUND_ID), 20);
        assertEq(financialAssets.balanceOf(buyer2, TECH_FUND_ID), 30);
        assertEq(financialAssets.balanceOf(buyer2, HEALTH_FUND_ID), 25);
    }

    // Scenario 3: Partial Trades and Liquidity
    function test_Scenario3_PartialTradesAndLiquidity() public {
        financialAssets.createAssetType(TECH_FUND_ID, "Tech Fund", "TECH");
        financialAssets.mint(TECH_FUND_ID, 1000);
        primaryMarket.configureAsset(TECH_FUND_ID, 100 * 10 ** 6);

        // Large seller acquires 500
        digitalEuro.mint(largeSeller, 50000 * 10 ** 6);
        vm.startPrank(largeSeller);
        digitalEuro.approve(address(primaryMarket), 50000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 500);

        // List 500 at 105
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(TECH_FUND_ID, 500, 105 * 10 ** 6); // ID 0
        vm.stopPrank();

        // Multiple buyers
        digitalEuro.mint(buyer1, 10000 * 10 ** 6);
        digitalEuro.mint(buyer2, 20000 * 10 ** 6);
        digitalEuro.mint(buyer3, 32000 * 10 ** 6);

        // Buyer 1: 50
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 10000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 50);
        vm.stopPrank();

        SecondaryMarket.Listing memory listing = secondaryMarket.getListing(0);
        assertEq(listing.amount, 450);

        // Buyer 2: 150
        vm.startPrank(buyer2);
        digitalEuro.approve(address(secondaryMarket), 20000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 150);
        vm.stopPrank();

        listing = secondaryMarket.getListing(0);
        assertEq(listing.amount, 300);

        // Buyer 3: 300 (Complete)
        vm.startPrank(buyer3);
        digitalEuro.approve(address(secondaryMarket), 32000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 300);
        vm.stopPrank();

        listing = secondaryMarket.getListing(0);
        assertEq(listing.amount, 0);
        assertFalse(listing.active);

        // Verify seller revenue: 500 * 105 = 52500
        assertEq(digitalEuro.balanceOf(largeSeller), 52500 * 10 ** 6);
    }

    // Scenario 4: Emergency Pause and Recovery
    function test_Scenario4_EmergencyPauseAndRecovery() public {
        financialAssets.createAssetType(TECH_FUND_ID, "Tech Fund", "TECH");
        financialAssets.mint(TECH_FUND_ID, 1000);
        primaryMarket.configureAsset(TECH_FUND_ID, 100 * 10 ** 6);

        // Setup
        digitalEuro.mint(investor1, 20000 * 10 ** 6);
        digitalEuro.mint(investor2, 15000 * 10 ** 6);

        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 20000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 100);

        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(TECH_FUND_ID, 50, 110 * 10 ** 6); // ID 0
        vm.stopPrank();

        // 🚨 EMERGENCY PAUSE
        primaryMarket.pause();
        secondaryMarket.pause();

        assertTrue(primaryMarket.paused());
        assertTrue(secondaryMarket.paused());

        // Verify actions blocked
        vm.startPrank(investor2);
        digitalEuro.approve(address(primaryMarket), 15000 * 10 ** 6);
        digitalEuro.approve(address(secondaryMarket), 15000 * 10 ** 6);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        primaryMarket.buyAsset(TECH_FUND_ID, 50);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        secondaryMarket.executeTrade(0, 25);
        vm.stopPrank();

        // Verify Cancellation allowed
        vm.prank(investor1);
        secondaryMarket.cancelListing(0);

        assertEq(financialAssets.balanceOf(investor1, TECH_FUND_ID), 100);

        // 🟢 RECOVERY
        primaryMarket.unpause();
        secondaryMarket.unpause();

        // Verify actions resumed
        vm.prank(investor2);
        primaryMarket.buyAsset(TECH_FUND_ID, 50);

        vm.startPrank(investor1);
        secondaryMarket.createListing(TECH_FUND_ID, 40, 115 * 10 ** 6); // ID 1
        vm.stopPrank();

        vm.prank(investor2);
        secondaryMarket.executeTrade(1, 20);

        assertEq(financialAssets.balanceOf(investor2, TECH_FUND_ID), 70); // 50 from primary + 20 from secondary
    }

    // Scenario 5: Treasury Management
    function test_Scenario5_TreasuryManagement() public {
        financialAssets.createAssetType(TECH_FUND_ID, "Tech Fund", "TECH");
        financialAssets.mint(TECH_FUND_ID, 1000);
        primaryMarket.configureAsset(TECH_FUND_ID, 100 * 10 ** 6);

        // Phase 1: Default Treasury
        digitalEuro.mint(investor1, 20000 * 10 ** 6);
        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 20000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 100); // Cost 10,000
        vm.stopPrank();

        assertEq(digitalEuro.balanceOf(owner), 10000 * 10 ** 6);

        // Phase 2: Update Treasury
        primaryMarket.updateFundTreasury(newTreasury);

        digitalEuro.mint(investor2, 15000 * 10 ** 6);
        vm.startPrank(investor2);
        digitalEuro.approve(address(primaryMarket), 15000 * 10 ** 6);
        primaryMarket.buyAsset(TECH_FUND_ID, 75); // Cost 7,500
        vm.stopPrank();

        assertEq(digitalEuro.balanceOf(newTreasury), 7500 * 10 ** 6);
        assertEq(digitalEuro.balanceOf(owner), 10000 * 10 ** 6); // Unchanged
    }
}
