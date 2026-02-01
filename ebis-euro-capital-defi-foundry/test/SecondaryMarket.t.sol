// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SecondaryMarket} from "../src/SecondaryMarket.sol";
import {DigitalEuro} from "../src/DigitalEuro.sol";
import {FinancialAssets} from "../src/FinancialAssets.sol";
import {
    IAccessControl
} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IERC20Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {
    IERC1155Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {
    ERC1155Holder
} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract SecondaryMarketTest is Test, ERC1155Holder {
    SecondaryMarket public secondaryMarket;
    DigitalEuro public digitalEuro;
    FinancialAssets public financialAssets;

    address public owner;
    address public seller;
    address public buyer1;
    address public buyer2;
    address public unauthorizedUser;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    string public constant BASE_URI =
        "https://api.fondo-inversion.com/assets/{id}.json";
    uint256 public constant ASSET_ID_1 = 1;
    uint256 public constant ASSET_ID_2 = 2;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed assetId,
        uint256 amount,
        uint256 pricePerUnit
    );
    event TradeExecuted(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 assetId,
        uint256 amount,
        uint256 totalPrice
    );
    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller,
        uint256 assetId,
        uint256 amount
    );
    event ListingUpdated(uint256 indexed listingId, uint256 newAmount);

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        unauthorizedUser = makeAddr("unauthorizedUser");

        digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
        financialAssets = new FinancialAssets(BASE_URI);
        secondaryMarket = new SecondaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
    }

    // Deployment Tests
    function test_Deployment_CorrectReferences() public view {
        assertEq(address(secondaryMarket.digitalEuro()), address(digitalEuro));
        assertEq(
            address(secondaryMarket.financialAssets()),
            address(financialAssets)
        );
    }

    function test_Deployment_GrantDefaultAdminRoleToDeployer() public view {
        assertTrue(secondaryMarket.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_Deployment_RevertCheck_ZeroAddressDigitalEuro() public {
        vm.expectRevert(SecondaryMarket.SecondaryMarketInvalidAddress.selector);
        new SecondaryMarket(address(0), address(financialAssets));
    }

    function test_Deployment_RevertCheck_ZeroAddressFinancialAssets() public {
        vm.expectRevert(SecondaryMarket.SecondaryMarketInvalidAddress.selector);
        new SecondaryMarket(address(digitalEuro), address(0));
    }

    function test_Deployment_InitialListingCountZero() public view {
        assertEq(secondaryMarket.getListingCount(), 0);
    }

    // Listing Creation Tests
    function test_CreateListing_Success() public {
        // Setup seller with assets
        financialAssets.setPrimaryMarket(owner); // Set owner as primary market for simplicity to mint
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);

        uint256 price = 100 * 10 ** 6;
        secondaryMarket.createListing(ASSET_ID_1, 50, price);
        vm.stopPrank();

        assertEq(secondaryMarket.getListingCount(), 1);
    }

    function test_CreateListing_AssetsLocked() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(seller, ASSET_ID_1), 50);
        assertEq(
            financialAssets.balanceOf(address(secondaryMarket), ASSET_ID_1),
            50
        );
    }

    function test_CreateListing_EmitsEvent() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);

        vm.expectEmit(true, true, true, true);
        emit ListingCreated(0, seller, ASSET_ID_1, 50, 100 * 10 ** 6);

        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();
    }

    function test_CreateListing_RevertCheck_ZeroAmount() public {
        vm.prank(seller);
        vm.expectRevert(SecondaryMarket.SecondaryMarketInvalidAmount.selector);
        secondaryMarket.createListing(ASSET_ID_1, 0, 100);
    }

    function test_CreateListing_RevertCheck_ZeroPrice() public {
        vm.prank(seller);
        vm.expectRevert(SecondaryMarket.SecondaryMarketInvalidPrice.selector);
        secondaryMarket.createListing(ASSET_ID_1, 50, 0);
    }

    // Trade Execution Tests
    function test_ExecuteTrade_FullMatch() public {
        // 1. Setup Seller listing
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        // 2. Setup Buyer
        digitalEuro.mint(buyer1, 5000 * 10 ** 6);

        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 5000 * 10 ** 6);

        // 3. Execute Trade
        secondaryMarket.executeTrade(0, 50);
        vm.stopPrank();

        // 4. Verify Settlement
        assertEq(financialAssets.balanceOf(buyer1, ASSET_ID_1), 50);
        assertEq(digitalEuro.balanceOf(buyer1), 0);
        assertEq(digitalEuro.balanceOf(seller), 5000 * 10 ** 6);

        // Verify Listing Closed
        assertFalse(secondaryMarket.isListingActive(0));
    }

    function test_ExecuteTrade_PartialMatch() public {
        // Setup listing for 50
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        // Buyer takes 20
        digitalEuro.mint(buyer1, 2000 * 10 ** 6);
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 2000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 20);
        vm.stopPrank();

        // Check listing states
        assertTrue(secondaryMarket.isListingActive(0));
        SecondaryMarket.Listing memory listing = secondaryMarket.getListing(0);
        assertEq(listing.amount, 30);
    }

    function test_ExecuteTrade_EmitsEvents() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        digitalEuro.mint(buyer1, 5000 * 10 ** 6);
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 5000 * 10 ** 6);

        vm.expectEmit(true, true, true, true);
        emit TradeExecuted(0, buyer1, seller, ASSET_ID_1, 50, 5000 * 10 ** 6);

        secondaryMarket.executeTrade(0, 50);
        vm.stopPrank();
    }

    function test_ExecuteTrade_EmitsListingUpdatedOnPartial() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        digitalEuro.mint(buyer1, 2000 * 10 ** 6);
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 2000 * 10 ** 6);

        vm.expectEmit(true, false, false, true);
        emit ListingUpdated(0, 30);

        secondaryMarket.executeTrade(0, 20);
        vm.stopPrank();
    }

    function test_ExecuteTrade_RevertCheck_InsufficientAssetsInListing()
        public
    {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        digitalEuro.mint(buyer1, 10000 * 10 ** 6);
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 10000 * 10 ** 6);

        vm.expectRevert(
            SecondaryMarket.SecondaryMarketInsufficientAssets.selector
        );
        secondaryMarket.executeTrade(0, 100); // Only 50 available
        vm.stopPrank();
    }

    function test_ExecuteTrade_RevertCheck_InsufficientBalance() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        digitalEuro.mint(buyer1, 100 * 10 ** 6); // Only 100 DEUR
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 5000 * 10 ** 6);

        vm.expectRevert(
            SecondaryMarket.SecondaryMarketInsufficientBalance.selector
        );
        secondaryMarket.executeTrade(0, 50); // Needs 5000
        vm.stopPrank();
    }

    function test_ExecuteTrade_RevertCheck_InsufficientAllowance() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        digitalEuro.mint(buyer1, 5000 * 10 ** 6);
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 100 * 10 ** 6); // Only 100 allowance

        vm.expectRevert(
            SecondaryMarket.SecondaryMarketInsufficientAllowance.selector
        );
        secondaryMarket.executeTrade(0, 50); // Needs 5000
        vm.stopPrank();
    }

    // Cancellation Tests
    function test_CancelListing_Success() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);

        secondaryMarket.cancelListing(0);
        vm.stopPrank();

        assertFalse(secondaryMarket.isListingActive(0));
    }

    function test_CancelListing_ReturnsAssets() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);

        secondaryMarket.cancelListing(0);
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(seller, ASSET_ID_1), 100); // 100 - 50 + 50
    }

    function test_CancelListing_EmitsEvent() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);

        vm.expectEmit(true, true, false, true);
        emit ListingCancelled(0, seller, ASSET_ID_1, 50);

        secondaryMarket.cancelListing(0);
        vm.stopPrank();
    }

    function test_CancelListing_RevertCheck_Unauthorized() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        vm.prank(buyer1);
        vm.expectRevert(SecondaryMarket.SecondaryMarketUnauthorized.selector);
        secondaryMarket.cancelListing(0);
    }

    function test_CancelListing_RevertCheck_NotActive() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        secondaryMarket.cancelListing(0); // cancelled once

        vm.expectRevert(
            SecondaryMarket.SecondaryMarketListingNotActive.selector
        );
        secondaryMarket.cancelListing(0); // cancel again
        vm.stopPrank();
    }

    // Pause Tests
    function test_Pause_AdminCanPause() public {
        secondaryMarket.pause();
        assertTrue(secondaryMarket.paused());

        secondaryMarket.unpause();
        assertFalse(secondaryMarket.paused());
    }

    function test_Pause_PreventsCreation() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        vm.stopPrank();

        secondaryMarket.pause();

        vm.prank(seller);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100);
    }

    function test_Pause_AllowsCancellation() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100);
        vm.stopPrank();

        secondaryMarket.pause();

        vm.prank(seller);
        secondaryMarket.cancelListing(0); // Should succeed
        assertFalse(secondaryMarket.isListingActive(0));
    }

    // View Functions
    function test_View_GetListing() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        vm.stopPrank();

        SecondaryMarket.Listing memory listing = secondaryMarket.getListing(0);
        assertEq(listing.seller, seller);
        assertEq(listing.assetId, ASSET_ID_1);
        assertEq(listing.amount, 50);
        assertEq(listing.pricePerUnit, 100 * 10 ** 6);
        assertTrue(listing.active);
    }

    function test_View_GetActiveListing_RevertInactive() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6);
        secondaryMarket.cancelListing(0);
        vm.stopPrank();

        vm.expectRevert(
            SecondaryMarket.SecondaryMarketListingNotActive.selector
        );
        secondaryMarket.getActiveListing(0);
    }

    // Integration
    function test_Integration_MultipleTrades() public {
        financialAssets.setPrimaryMarket(owner);
        financialAssets.createAssetType(ASSET_ID_1, "Tech", "TECH");
        financialAssets.createAssetType(ASSET_ID_2, "Health", "HEALTH");

        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.mint(ASSET_ID_2, 50);
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_1, 100, "");
        financialAssets.safeTransferFrom(owner, seller, ASSET_ID_2, 50, "");

        vm.startPrank(seller);
        financialAssets.setApprovalForAll(address(secondaryMarket), true);
        secondaryMarket.createListing(ASSET_ID_1, 50, 100 * 10 ** 6); // ID 0
        secondaryMarket.createListing(ASSET_ID_2, 30, 200 * 10 ** 6); // ID 1
        vm.stopPrank();

        digitalEuro.mint(buyer1, 10000 * 10 ** 6);
        digitalEuro.mint(buyer2, 5000 * 10 ** 6);

        // Buyer 1 buys 30 from Listing 0 (Tech)
        vm.startPrank(buyer1);
        digitalEuro.approve(address(secondaryMarket), 10000 * 10 ** 6);
        secondaryMarket.executeTrade(0, 30);
        vm.stopPrank();

        // Buyer 2 buys 20 from Listing 1 (Health)
        vm.startPrank(buyer2);
        digitalEuro.approve(address(secondaryMarket), 5000 * 10 ** 6);
        secondaryMarket.executeTrade(1, 20);
        vm.stopPrank();

        // Verify Balances
        assertEq(financialAssets.balanceOf(buyer1, ASSET_ID_1), 30);
        assertEq(financialAssets.balanceOf(buyer2, ASSET_ID_2), 20);

        // Seller Earnings:
        // 30 * 100 = 3000
        // 20 * 200 = 4000
        // Total = 7000
        assertEq(digitalEuro.balanceOf(seller), 7000 * 10 ** 6);
    }
}
