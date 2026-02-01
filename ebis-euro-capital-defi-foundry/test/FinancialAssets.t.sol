// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FinancialAssets} from "../src/FinancialAssets.sol";
import {
    IAccessControl
} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IERC1155Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {
    ERC1155Holder
} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract FinancialAssetsTest is Test, ERC1155Holder {
    FinancialAssets public financialAssets;

    address public owner;
    address public primaryMarket;
    address public investor1;
    address public investor2;
    address public unauthorizedUser;

    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    string public constant BASE_URI =
        "https://api.fondo-inversion.com/assets/{id}.json";
    uint256 public constant ASSET_ID_1 = 1;
    uint256 public constant ASSET_ID_2 = 2;

    event AssetTypeCreated(uint256 indexed assetId, string name, string symbol);
    event PrimaryMarketSet(
        address indexed previousMarket,
        address indexed newMarket
    );
    event AssetsMinted(
        uint256 indexed assetId,
        address indexed to,
        uint256 amount
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    function setUp() public {
        owner = address(this);
        primaryMarket = makeAddr("primaryMarket");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        unauthorizedUser = makeAddr("unauthorizedUser");

        financialAssets = new FinancialAssets(BASE_URI);
    }

    // Deployment Tests
    function test_Deployment_CorrectURI() public view {
        assertEq(financialAssets.uri(ASSET_ID_1), BASE_URI);
    }

    function test_Deployment_GrantDefaultAdminRoleToDeployer() public view {
        assertTrue(financialAssets.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_Deployment_GrantFundManagerRoleToDeployer() public view {
        assertTrue(financialAssets.hasRole(FUND_MANAGER_ROLE, owner));
    }

    function test_Deployment_ZeroInitialPrimaryMarket() public view {
        assertEq(financialAssets.primaryMarket(), address(0));
    }

    function test_Deployment_ZeroInitialAssetTypeCount() public view {
        assertEq(financialAssets.getAssetTypeCount(), 0);
    }

    // Asset Creation Tests
    function test_AssetCreation_FundManagerCanCreateAsset() public {
        financialAssets.createAssetType(ASSET_ID_1, "Technology Fund", "TECH");

        assertEq(financialAssets.getAssetName(ASSET_ID_1), "Technology Fund");
        assertEq(financialAssets.getAssetSymbol(ASSET_ID_1), "TECH");
        assertTrue(financialAssets.assetExists(ASSET_ID_1));
    }

    function test_AssetCreation_IncrementsCount() public {
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        assertEq(financialAssets.getAssetTypeCount(), 1);

        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );
        assertEq(financialAssets.getAssetTypeCount(), 2);
    }

    function test_AssetCreation_EmitsAssetTypeCreatedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit AssetTypeCreated(ASSET_ID_1, "Technology Fund", "TECH");

        financialAssets.createAssetType(ASSET_ID_1, "Technology Fund", "TECH");
    }

    function test_AssetCreation_RevertCheck_DuplicateAssetID() public {
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        vm.expectRevert(
            FinancialAssets.FinancialAssetsAssetAlreadyExists.selector
        );
        financialAssets.createAssetType(ASSET_ID_1, "Duplicate", "DUP");
    }

    function test_AssetCreation_RevertCheck_UnauthorizedUser() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                FUND_MANAGER_ROLE
            )
        );
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
    }

    function test_AssetCreation_AssetExistsReturnsFalseForNonExistent()
        public
        view
    {
        assertFalse(financialAssets.assetExists(999));
    }

    // Primary Market Configuration Tests
    function test_PrimaryMarket_AdminCanSetMarket() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        assertEq(financialAssets.primaryMarket(), primaryMarket);
    }

    function test_PrimaryMarket_EmitsPrimaryMarketSetEvent() public {
        vm.expectEmit(true, true, false, true);
        emit PrimaryMarketSet(address(0), primaryMarket);

        financialAssets.setPrimaryMarket(primaryMarket);
    }

    function test_PrimaryMarket_RevertCheck_SetZeroAddress() public {
        vm.expectRevert(
            FinancialAssets.FinancialAssetsInvalidPrimaryMarket.selector
        );
        financialAssets.setPrimaryMarket(address(0));
    }

    function test_PrimaryMarket_RevertCheck_UnauthorizedUser() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                DEFAULT_ADMIN_ROLE
            )
        );
        financialAssets.setPrimaryMarket(primaryMarket);
    }

    // Minting Tests
    function test_Minting_FundManagerCanMintToPrimaryMarket() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256 mintAmount = 1000;
        financialAssets.mint(ASSET_ID_1, mintAmount);

        assertEq(
            financialAssets.balanceOf(primaryMarket, ASSET_ID_1),
            mintAmount
        );
    }

    function test_Minting_IncreasesTotalSupply() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256 mintAmount = 500;
        financialAssets.mint(ASSET_ID_1, mintAmount);

        assertEq(financialAssets.totalSupply(ASSET_ID_1), mintAmount);
    }

    function test_Minting_EmitsAssetsMintedEvent() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256 mintAmount = 100;

        vm.expectEmit(true, true, false, true); // AssetId, To are indexed. Amount is not indexed in standard event? Check contract definition.
        // Contract Event: event AssetsMinted(uint256 indexed assetId, address indexed to, uint256 amount);
        // Correct.
        emit AssetsMinted(ASSET_ID_1, primaryMarket, mintAmount);

        financialAssets.mint(ASSET_ID_1, mintAmount);
    }

    function test_Minting_RevertCheck_PrimaryMarketNotSet() public {
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        vm.expectRevert(
            FinancialAssets.FinancialAssetsPrimaryMarketNotSet.selector
        );
        financialAssets.mint(ASSET_ID_1, 100);
    }

    function test_Minting_RevertCheck_ZeroAmount() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        vm.expectRevert(FinancialAssets.FinancialAssetsInvalidAmount.selector);
        financialAssets.mint(ASSET_ID_1, 0);
    }

    function test_Minting_RevertCheck_NonExistentAsset() public {
        financialAssets.setPrimaryMarket(primaryMarket);

        vm.expectRevert(FinancialAssets.FinancialAssetsInvalidAssetId.selector);
        financialAssets.mint(999, 100);
    }

    function test_Minting_RevertCheck_UnauthorizedUser() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                FUND_MANAGER_ROLE
            )
        );
        financialAssets.mint(ASSET_ID_1, 100);
    }

    function test_Minting_MultipleTimesSameAsset() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256 firstMint = 1000;
        uint256 secondMint = 500;
        uint256 thirdMint = 200;

        financialAssets.mint(ASSET_ID_1, firstMint);
        financialAssets.mint(ASSET_ID_1, secondMint);
        financialAssets.mint(ASSET_ID_1, thirdMint);

        uint256 total = firstMint + secondMint + thirdMint;
        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_1), total);
        assertEq(financialAssets.totalSupply(ASSET_ID_1), total);
    }

    function test_Minting_BatchMint() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );

        uint256[] memory ids = new uint256[](2);
        ids[0] = ASSET_ID_1;
        ids[1] = ASSET_ID_2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 2000;

        financialAssets.mintBatch(ids, amounts);

        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_1), 1000);
        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_2), 2000);
    }

    function test_Minting_BatchMint_RevertCheck_PrimaryMarketNotSet() public {
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256[] memory ids = new uint256[](1);
        ids[0] = ASSET_ID_1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert(
            FinancialAssets.FinancialAssetsPrimaryMarketNotSet.selector
        );
        financialAssets.mintBatch(ids, amounts);
    }

    function test_Minting_BatchMint_RevertCheck_ZeroAmount() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");

        uint256[] memory ids = new uint256[](1);
        ids[0] = ASSET_ID_1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(FinancialAssets.FinancialAssetsInvalidAmount.selector);
        financialAssets.mintBatch(ids, amounts);
    }

    function test_Minting_BatchMint_RevertCheck_NonExistentAsset() public {
        financialAssets.setPrimaryMarket(primaryMarket);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 999;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert(FinancialAssets.FinancialAssetsInvalidAssetId.selector);
        financialAssets.mintBatch(ids, amounts);
    }

    // Transfer Tests (ERC-1155 functionality)
    // Note: PrimaryMarket needs to be an EOA or handle ERC1155 receipts for testing effectively if using vm.prank
    // Since primaryMarket address is created via makeAddr, it's an EOA and should be fine receiving tokens?
    // Actually, ERC1155 safeTransfer checks for onERC1155Received implementation if `to` is a contract.
    // `makeAddr` creates an address with no code, so safeTransfer succeeds (assuming plain simple address).
    // However, if we prank AS the primaryMarket to send, that's fine.

    function test_Transfer_BetweenAccounts() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 1000);

        uint256 transferAmount = 100;

        vm.prank(primaryMarket);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor1,
            ASSET_ID_1,
            transferAmount,
            ""
        );

        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_1), 900);
        assertEq(
            financialAssets.balanceOf(investor1, ASSET_ID_1),
            transferAmount
        );
    }

    function test_Transfer_RevertCheck_ExceedingBalance() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 1000);

        uint256 excessiveAmount = 2000;

        vm.prank(primaryMarket);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC1155Errors.ERC1155InsufficientBalance.selector,
                primaryMarket,
                1000,
                excessiveAmount,
                ASSET_ID_1
            )
        );
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor1,
            ASSET_ID_1,
            excessiveAmount,
            ""
        );
    }

    function test_Transfer_ApprovedTransferUsingSetApprovalForAll() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 1000);

        // Primary market approves investor1
        vm.prank(primaryMarket);
        financialAssets.setApprovalForAll(investor1, true);

        assertTrue(financialAssets.isApprovedForAll(primaryMarket, investor1));

        // Investor1 transfers from primaryMarket to investor2
        uint256 transferAmount = 100;
        vm.prank(investor1);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor2,
            ASSET_ID_1,
            transferAmount,
            ""
        );

        assertEq(
            financialAssets.balanceOf(investor2, ASSET_ID_1),
            transferAmount
        );
    }

    function test_Transfer_RevertCheck_MissingApproval() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 1000);

        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC1155Errors.ERC1155MissingApprovalForAll.selector,
                unauthorizedUser,
                primaryMarket
            )
        );
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor2,
            ASSET_ID_1,
            100,
            ""
        );
    }

    function test_Transfer_EmitsTransferSingleEvent() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.mint(ASSET_ID_1, 1000);

        uint256 transferAmount = 100;

        vm.expectEmit(true, true, true, true);
        // operator, from, to, id, value
        emit TransferSingle(
            primaryMarket,
            primaryMarket,
            investor1,
            ASSET_ID_1,
            transferAmount
        );

        vm.prank(primaryMarket);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor1,
            ASSET_ID_1,
            transferAmount,
            ""
        );
    }

    function test_Transfer_EmitsApprovalForAllEvent() public {
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(primaryMarket, investor1, true);

        vm.prank(primaryMarket);
        financialAssets.setApprovalForAll(investor1, true);
    }

    function test_Transfer_BatchTransfer() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );

        uint256[] memory mintIds = new uint256[](2);
        mintIds[0] = ASSET_ID_1;
        mintIds[1] = ASSET_ID_2;
        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 1000;
        mintAmounts[1] = 2000;

        financialAssets.mintBatch(mintIds, mintAmounts);

        uint256[] memory ids = new uint256[](2);
        ids[0] = ASSET_ID_1;
        ids[1] = ASSET_ID_2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(primaryMarket);
        financialAssets.safeBatchTransferFrom(
            primaryMarket,
            investor1,
            ids,
            amounts,
            ""
        );

        assertEq(financialAssets.balanceOf(investor1, ASSET_ID_1), 100);
        assertEq(financialAssets.balanceOf(investor1, ASSET_ID_2), 200);
    }

    function test_Transfer_EmitsTransferBatchEvent() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );

        uint256[] memory mintIds = new uint256[](2);
        mintIds[0] = ASSET_ID_1;
        mintIds[1] = ASSET_ID_2;
        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 1000;
        mintAmounts[1] = 2000;
        financialAssets.mintBatch(mintIds, mintAmounts);

        uint256[] memory ids = new uint256[](2);
        ids[0] = ASSET_ID_1;
        ids[1] = ASSET_ID_2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(
            primaryMarket,
            primaryMarket,
            investor1,
            ids,
            amounts
        );

        vm.prank(primaryMarket);
        financialAssets.safeBatchTransferFrom(
            primaryMarket,
            investor1,
            ids,
            amounts,
            ""
        );
    }

    function test_Transfer_BalanceOfBatch() public {
        financialAssets.setPrimaryMarket(primaryMarket);
        financialAssets.createAssetType(ASSET_ID_1, "Tech Fund", "TECH");
        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );

        uint256[] memory mintIds = new uint256[](2);
        mintIds[0] = ASSET_ID_1;
        mintIds[1] = ASSET_ID_2;
        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 1000;
        mintAmounts[1] = 2000;
        financialAssets.mintBatch(mintIds, mintAmounts);

        vm.prank(primaryMarket);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor1,
            ASSET_ID_1,
            100,
            ""
        );

        vm.prank(primaryMarket);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor2,
            ASSET_ID_2,
            200,
            ""
        );

        address[] memory accounts = new address[](2);
        accounts[0] = investor1;
        accounts[1] = investor2;

        uint256[] memory ids = new uint256[](2);
        ids[0] = ASSET_ID_1;
        ids[1] = ASSET_ID_2;

        uint256[] memory balances = financialAssets.balanceOfBatch(
            accounts,
            ids
        );

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }

    // Access Control Tests
    function test_AccessControl_AdminCanGrantFundManagerRole() public {
        financialAssets.grantRole(FUND_MANAGER_ROLE, investor1);
        assertTrue(financialAssets.hasRole(FUND_MANAGER_ROLE, investor1));

        // New fund manager can create asset
        vm.prank(investor1);
        financialAssets.createAssetType(ASSET_ID_1, "New Fund", "NEW");

        assertEq(financialAssets.getAssetName(ASSET_ID_1), "New Fund");
    }

    function test_AccessControl_AdminCanRevokeFundManagerRole() public {
        financialAssets.grantRole(FUND_MANAGER_ROLE, investor1);
        financialAssets.revokeRole(FUND_MANAGER_ROLE, investor1);
        assertFalse(financialAssets.hasRole(FUND_MANAGER_ROLE, investor1));

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                investor1,
                FUND_MANAGER_ROLE
            )
        );
        financialAssets.createAssetType(ASSET_ID_1, "Fail", "FAIL");
    }

    function test_AccessControl_RenounceRole() public {
        financialAssets.grantRole(FUND_MANAGER_ROLE, investor1);

        vm.prank(investor1);
        financialAssets.renounceRole(FUND_MANAGER_ROLE, investor1);
        assertFalse(financialAssets.hasRole(FUND_MANAGER_ROLE, investor1));
    }

    function test_AccessControl_RevertCheck_NonAdminCannotGrantRole() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                DEFAULT_ADMIN_ROLE
            )
        );
        financialAssets.grantRole(FUND_MANAGER_ROLE, investor1);
    }

    // Integration Test
    function test_Integration_CompleteFlow() public {
        // Step 1: Create multiple asset types
        financialAssets.createAssetType(ASSET_ID_1, "Technology Fund", "TECH");
        financialAssets.createAssetType(
            ASSET_ID_2,
            "Healthcare Fund",
            "HEALTH"
        );
        assertEq(financialAssets.getAssetTypeCount(), 2);

        // Step 2: Set primary market
        financialAssets.setPrimaryMarket(primaryMarket);

        // Step 3: Mint assets to primary market
        uint256[] memory mintIds = new uint256[](2);
        mintIds[0] = ASSET_ID_1;
        mintIds[1] = ASSET_ID_2;
        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 5000;
        mintAmounts[1] = 3000;

        financialAssets.mintBatch(mintIds, mintAmounts);

        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_1), 5000);
        assertEq(financialAssets.balanceOf(primaryMarket, ASSET_ID_2), 3000);

        // Step 4: Primary market transfers to investors
        vm.startPrank(primaryMarket);
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor1,
            ASSET_ID_1,
            1000,
            ""
        );
        financialAssets.safeTransferFrom(
            primaryMarket,
            investor2,
            ASSET_ID_2,
            500,
            ""
        );
        vm.stopPrank();

        assertEq(financialAssets.balanceOf(investor1, ASSET_ID_1), 1000);
        assertEq(financialAssets.balanceOf(investor2, ASSET_ID_2), 500);

        // Step 5: Investor to investor transfer
        vm.prank(investor1);
        financialAssets.safeTransferFrom(
            investor1,
            investor2,
            ASSET_ID_1,
            200,
            ""
        );

        assertEq(financialAssets.balanceOf(investor1, ASSET_ID_1), 800);
        assertEq(financialAssets.balanceOf(investor2, ASSET_ID_1), 200);

        assertEq(financialAssets.totalSupply(ASSET_ID_1), 5000);
        assertEq(financialAssets.totalSupply(ASSET_ID_2), 3000);
    }
}
