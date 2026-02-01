// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {PrimaryMarket} from "../src/PrimaryMarket.sol";
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
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract PrimaryMarketTest is Test {
    PrimaryMarket public primaryMarket;
    DigitalEuro public digitalEuro;
    FinancialAssets public financialAssets;

    address public owner;
    address public investor1;
    address public investor2;
    address public unauthorizedUser;

    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    string public constant BASE_URI =
        "https://api.fondo-inversion.com/assets/{id}.json";
    uint256 public constant ASSET_ID_1 = 1;
    uint256 public constant ASSET_ID_2 = 2;

    event AssetConfigured(uint256 indexed assetId, uint256 price);
    event AssetPurchased(
        address indexed buyer,
        uint256 indexed assetId,
        uint256 amount,
        uint256 totalPrice
    );
    event FundTreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );

    function setUp() public {
        owner = address(this);
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        unauthorizedUser = makeAddr("unauthorizedUser");

        digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
        financialAssets = new FinancialAssets(BASE_URI);
        primaryMarket = new PrimaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
    }

    // Deployment Tests
    function test_Deployment_CorrectReferences() public view {
        assertEq(address(primaryMarket.digitalEuro()), address(digitalEuro));
        assertEq(
            address(primaryMarket.financialAssets()),
            address(financialAssets)
        );
    }

    function test_Deployment_GrantDefaultAdminRoleToDeployer() public view {
        assertTrue(primaryMarket.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_Deployment_GrantFundManagerRoleToDeployer() public view {
        assertTrue(primaryMarket.hasRole(FUND_MANAGER_ROLE, owner));
    }

    function test_Deployment_SetFundTreasuryToDeployer() public view {
        assertEq(primaryMarket.fundTreasury(), owner);
    }

    function test_Deployment_RevertCheck_ZeroAddressDigitalEuro() public {
        vm.expectRevert(PrimaryMarket.PrimaryMarketInvalidAddress.selector);
        new PrimaryMarket(address(0), address(financialAssets));
    }

    function test_Deployment_RevertCheck_ZeroAddressFinancialAssets() public {
        vm.expectRevert(PrimaryMarket.PrimaryMarketInvalidAddress.selector);
        new PrimaryMarket(address(digitalEuro), address(0));
    }

    // Asset Configuration Tests
    function test_AssetConfiguration_FundManagerCanConfigure() public {
        uint256 price = 100 * 10 ** 6; // 6 decimals
        primaryMarket.configureAsset(ASSET_ID_1, price);

        assertEq(primaryMarket.getAssetPrice(ASSET_ID_1), price);
    }

    function test_AssetConfiguration_EmitsAssetConfiguredEvent() public {
        uint256 price = 100 * 10 ** 6;

        vm.expectEmit(true, false, false, true);
        emit AssetConfigured(ASSET_ID_1, price);

        primaryMarket.configureAsset(ASSET_ID_1, price);
    }

    function test_AssetConfiguration_RevertCheck_ZeroPrice() public {
        vm.expectRevert(PrimaryMarket.PrimaryMarketInvalidPrice.selector);
        primaryMarket.configureAsset(ASSET_ID_1, 0);
    }

    function test_AssetConfiguration_RevertCheck_UnauthorizedUser() public {
        uint256 price = 100 * 10 ** 6;

        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                FUND_MANAGER_ROLE
            )
        );
        primaryMarket.configureAsset(ASSET_ID_1, price);
    }

    function test_AssetConfiguration_UpdatePrice() public {
        uint256 initialPrice = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, initialPrice);

        uint256 newPrice = 150 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, newPrice);

        assertEq(primaryMarket.getAssetPrice(ASSET_ID_1), newPrice);
    }

    // Asset Purchase Tests
    function test_Purchase_InvestorCanBuy() public {
        // Setup
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);

        uint256 price = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, price);

        uint256 purchaseAmount = 10;
        uint256 totalCost = price * purchaseAmount;

        // Mint DEUR to investor
        digitalEuro.mint(investor1, 1000 * 10 ** 6);

        // Approve and buy
        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), totalCost);
        primaryMarket.buyAsset(ASSET_ID_1, purchaseAmount);
        vm.stopPrank();

        // Verify
        assertEq(
            financialAssets.balanceOf(investor1, ASSET_ID_1),
            purchaseAmount
        );
        assertEq(
            digitalEuro.balanceOf(investor1),
            (1000 * 10 ** 6) - totalCost
        );
        assertEq(digitalEuro.balanceOf(owner), totalCost); // Treasury is owner
    }

    function test_Purchase_EmitsAssetPurchasedEvent() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);

        uint256 price = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, price);

        uint256 purchaseAmount = 10;
        uint256 totalCost = price * purchaseAmount;

        digitalEuro.mint(investor1, 1000 * 10 ** 6);

        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), totalCost);

        vm.expectEmit(true, true, false, true);
        emit AssetPurchased(investor1, ASSET_ID_1, purchaseAmount, totalCost);

        primaryMarket.buyAsset(ASSET_ID_1, purchaseAmount);
        vm.stopPrank();
    }

    function test_Purchase_RevertCheck_ZeroAmount() public {
        vm.prank(investor1);
        vm.expectRevert(PrimaryMarket.PrimaryMarketInvalidAmount.selector);
        primaryMarket.buyAsset(ASSET_ID_1, 0);
    }

    function test_Purchase_RevertCheck_UnconfiguredAsset() public {
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        // Not configured

        vm.prank(investor1);
        vm.expectRevert(PrimaryMarket.PrimaryMarketAssetNotConfigured.selector);
        primaryMarket.buyAsset(ASSET_ID_1, 10);
    }

    function test_Purchase_RevertCheck_InsufficientSupply() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 10); // Only 10 minted

        uint256 price = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, price);

        digitalEuro.mint(investor1, 5000 * 10 ** 6);

        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 5000 * 10 ** 6);

        // Try to buy 50
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC1155Errors.ERC1155InsufficientBalance.selector,
                address(primaryMarket),
                10,
                50,
                ASSET_ID_1
            )
        );
        primaryMarket.buyAsset(ASSET_ID_1, 50);
        vm.stopPrank();
    }

    function test_Purchase_RevertCheck_InsufficientBalance() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);

        uint256 price = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, price);

        // Mint only 50 DEUR
        digitalEuro.mint(investor1, 50 * 10 ** 6);

        vm.startPrank(investor1);
        // Approve enough but don't have enough balance
        digitalEuro.approve(address(primaryMarket), 1000 * 10 ** 6);

        // Buy 10 assets costs 1000 DEUR
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                investor1,
                50 * 10 ** 6,
                1000 * 10 ** 6
            )
        );
        primaryMarket.buyAsset(ASSET_ID_1, 10);
        vm.stopPrank();
    }

    function test_Purchase_RevertCheck_InsufficientAllowance() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);

        uint256 price = 100 * 10 ** 6;
        primaryMarket.configureAsset(ASSET_ID_1, price);

        digitalEuro.mint(investor1, 1000 * 10 ** 6);

        vm.startPrank(investor1);
        // Approve only 50 DEUR
        digitalEuro.approve(address(primaryMarket), 50 * 10 ** 6);

        // Buy 10 assets costs 1000 DEUR
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(primaryMarket),
                50 * 10 ** 6,
                1000 * 10 ** 6
            )
        );
        primaryMarket.buyAsset(ASSET_ID_1, 10);
        vm.stopPrank();
    }

    function test_Purchase_AvailableSupplyUpdates() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);

        assertEq(primaryMarket.getAvailableSupply(ASSET_ID_1), 100);

        digitalEuro.mint(investor1, 3000 * 10 ** 6);

        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 3000 * 10 ** 6);
        primaryMarket.buyAsset(ASSET_ID_1, 20);
        vm.stopPrank();

        assertEq(primaryMarket.getAvailableSupply(ASSET_ID_1), 80);
    }

    // Pause Tests
    function test_Pause_FundManagerCanPauseAndUnpause() public {
        primaryMarket.pause();
        assertTrue(primaryMarket.paused());

        primaryMarket.unpause();
        assertFalse(primaryMarket.paused());
    }

    function test_Pause_RevertCheck_PurchasesPaused() public {
        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);
        digitalEuro.mint(investor1, 1000 * 10 ** 6);

        vm.prank(investor1);
        digitalEuro.approve(address(primaryMarket), 1000 * 10 ** 6);

        primaryMarket.pause();

        vm.prank(investor1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        primaryMarket.buyAsset(ASSET_ID_1, 10);
    }

    function test_Pause_RevertCheck_UnauthorizedUser() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                FUND_MANAGER_ROLE
            )
        );
        primaryMarket.pause();
    }

    // Treasury Tests
    function test_Treasury_AdminCanUpdate() public {
        primaryMarket.updateFundTreasury(investor1);
        assertEq(primaryMarket.fundTreasury(), investor1);
    }

    function test_Treasury_EmitsFundTreasuryUpdatedEvent() public {
        vm.expectEmit(true, true, false, true);
        emit FundTreasuryUpdated(owner, investor1);

        primaryMarket.updateFundTreasury(investor1);
    }

    function test_Treasury_RevertCheck_ZeroAddress() public {
        vm.expectRevert(PrimaryMarket.PrimaryMarketInvalidAddress.selector);
        primaryMarket.updateFundTreasury(address(0));
    }

    function test_Treasury_RevertCheck_UnauthorizedUser() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                DEFAULT_ADMIN_ROLE
            )
        );
        primaryMarket.updateFundTreasury(investor1);
    }

    function test_Treasury_PaymentsGoToUpdatedTreasury() public {
        primaryMarket.updateFundTreasury(investor2);

        financialAssets.setPrimaryMarket(address(primaryMarket));
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 100);
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);

        digitalEuro.mint(investor1, 1000 * 10 ** 6);

        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 1000 * 10 ** 6);
        primaryMarket.buyAsset(ASSET_ID_1, 10);
        vm.stopPrank();

        assertEq(digitalEuro.balanceOf(investor2), 1000 * 10 ** 6);
    }

    // Access Control Tests
    function test_AccessControl_AdminCanGrantFundManagerRole() public {
        primaryMarket.grantRole(FUND_MANAGER_ROLE, investor1);
        assertTrue(primaryMarket.hasRole(FUND_MANAGER_ROLE, investor1));

        vm.prank(investor1);
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);
        assertEq(primaryMarket.getAssetPrice(ASSET_ID_1), 100 * 10 ** 6);
    }

    function test_AccessControl_AdminCanRevokeFundManagerRole() public {
        primaryMarket.grantRole(FUND_MANAGER_ROLE, investor1);
        assertTrue(primaryMarket.hasRole(FUND_MANAGER_ROLE, investor1));

        primaryMarket.revokeRole(FUND_MANAGER_ROLE, investor1);
        assertFalse(primaryMarket.hasRole(FUND_MANAGER_ROLE, investor1));

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                investor1,
                FUND_MANAGER_ROLE
            )
        );
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);
    }

    // Integration Test
    function test_Integration_MultipleInvestorsBuyingAssets() public {
        // Setup Primary Market
        financialAssets.setPrimaryMarket(address(primaryMarket));

        // Create Assets
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.createAssetType(ASSET_ID_2, "Health Fund", "HEALTH");

        // Mint Assets
        financialAssets.mint(ASSET_ID_1, 100);
        financialAssets.mint(ASSET_ID_2, 100);

        // Configure Prices
        primaryMarket.configureAsset(ASSET_ID_1, 100 * 10 ** 6);
        primaryMarket.configureAsset(ASSET_ID_2, 200 * 10 ** 6);

        // Mint DEUR to Investors
        digitalEuro.mint(investor1, 5000 * 10 ** 6);
        digitalEuro.mint(investor2, 3000 * 10 ** 6);

        // Investor1 buys 10 TECH (1000 DEUR)
        vm.startPrank(investor1);
        digitalEuro.approve(address(primaryMarket), 5000 * 10 ** 6);
        primaryMarket.buyAsset(ASSET_ID_1, 10);
        vm.stopPrank();

        // Investor2 buys 5 HEALTH (1000 DEUR)
        vm.startPrank(investor2);
        digitalEuro.approve(address(primaryMarket), 3000 * 10 ** 6);
        primaryMarket.buyAsset(ASSET_ID_2, 5);
        vm.stopPrank();

        // Verify Asset Balances
        assertEq(financialAssets.balanceOf(investor1, ASSET_ID_1), 10);
        assertEq(financialAssets.balanceOf(investor2, ASSET_ID_2), 5);

        // Verify DEUR Balances
        assertEq(digitalEuro.balanceOf(investor1), 4000 * 10 ** 6);
        assertEq(digitalEuro.balanceOf(investor2), 2000 * 10 ** 6);
        assertEq(digitalEuro.balanceOf(owner), 2000 * 10 ** 6); // Treasury
    }
}
