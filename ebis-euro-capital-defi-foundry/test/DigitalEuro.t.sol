// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {DigitalEuro} from "../src/DigitalEuro.sol";
import {
    IAccessControl
} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IERC20Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract DigitalEuroTest is Test {
    DigitalEuro public digitalEuro;

    address public owner;
    address public investor1;
    address public investor2;
    address public unauthorizedUser;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event TokensMinted(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        owner = address(this); // Test contract is the deployer/owner
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        unauthorizedUser = makeAddr("unauthorizedUser");

        digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
    }

    // Deployment Tests
    function test_Deployment_CorrectNameAndSymbol() public view {
        assertEq(digitalEuro.name(), "Digital Euro");
        assertEq(digitalEuro.symbol(), "DEUR");
    }

    function test_Deployment_CorrectDecimals() public view {
        assertEq(digitalEuro.decimals(), 6);
    }

    function test_Deployment_GrantDefaultAdminRoleToDeployer() public view {
        assertTrue(digitalEuro.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_Deployment_GrantMinterRoleToDeployer() public view {
        assertTrue(digitalEuro.hasRole(MINTER_ROLE, owner));
    }

    function test_Deployment_ZeroInitialTotalSupply() public view {
        assertEq(digitalEuro.totalSupply(), 0);
    }

    // Minting Tests (Central Bank functionality)
    function test_Minting_OwnerWithMinterRoleCanMint() public {
        uint256 mintAmount = 1000 ether; // using ether unit for simplicity, though decimals is 6
        // Note: In Foundry 'ether' keyword just multiplies by 10^18.
        // If logic relies on 6 decimals, be careful.
        // The original test used parseEther("1000") which implies 18 decimals usually in hardhat/viem unless configured otherwise.
        // DigitalEuro has 6 decimals, so let's stick to raw values or helper if needed.
        // But usually OpenZeppelin ERC20 doesn't enforce decimals on input, just stored value.
        // Let's us 1000 * 10**18 to match "parseEther" behavior from original test if it was standard.

        // Wait, original test said: "const mintAmount = parseEther("1000");"
        // And asserted "balance == mintAmount".
        // Let's assume standard behavior.

        digitalEuro.mint(investor1, mintAmount);
        assertEq(digitalEuro.balanceOf(investor1), mintAmount);
    }

    function test_Minting_IncreasesTotalSupply() public {
        uint256 mintAmount = 500 ether;
        digitalEuro.mint(investor1, mintAmount);
        assertEq(digitalEuro.totalSupply(), mintAmount);
    }

    function test_Minting_EmitsTokensMintedEvent() public {
        uint256 mintAmount = 100 ether;

        vm.expectEmit(true, false, false, true);
        emit TokensMinted(investor1, mintAmount);

        digitalEuro.mint(investor1, mintAmount);
    }

    function test_Minting_RevertCheck_ZeroAddress() public {
        uint256 mintAmount = 100 ether;
        address zeroAddress = address(0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                zeroAddress
            )
        );
        digitalEuro.mint(zeroAddress, mintAmount);
    }

    function test_Minting_RevertCheck_ZeroAmount() public {
        vm.expectRevert(DigitalEuro.DigitalEuroInvalidAmount.selector);
        digitalEuro.mint(investor1, 0);
    }

    function test_Minting_RevertCheck_UnauthorizedUser() public {
        uint256 mintAmount = 100 ether;

        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                MINTER_ROLE
            )
        );
        digitalEuro.mint(investor1, mintAmount);
    }

    function test_Minting_MultipleInvestors() public {
        uint256 amount1 = 1000 ether;
        uint256 amount2 = 2000 ether;

        digitalEuro.mint(investor1, amount1);
        digitalEuro.mint(investor2, amount2);

        assertEq(digitalEuro.balanceOf(investor1), amount1);
        assertEq(digitalEuro.balanceOf(investor2), amount2);
        assertEq(digitalEuro.totalSupply(), amount1 + amount2);
    }

    function test_Minting_MultipleMintsSameInvestor() public {
        uint256 firstMint = 1000 ether;
        uint256 secondMint = 500 ether;
        uint256 thirdMint = 200 ether;

        digitalEuro.mint(investor1, firstMint);
        digitalEuro.mint(investor1, secondMint);
        digitalEuro.mint(investor1, thirdMint);

        uint256 total = firstMint + secondMint + thirdMint;
        assertEq(digitalEuro.balanceOf(investor1), total);
        assertEq(digitalEuro.totalSupply(), total);
    }

    // Transfer Tests (Standard ERC-20 functionality)
    function test_Transfer_BetweenAccounts() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 transferAmount = 100 ether;

        vm.prank(investor1);
        digitalEuro.transfer(investor2, transferAmount);

        assertEq(digitalEuro.balanceOf(investor1), 900 ether);
        assertEq(digitalEuro.balanceOf(investor2), transferAmount);
    }

    function test_Transfer_RevertCheck_ExceedingBalance() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 excessiveAmount = 2000 ether;

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                investor1,
                initialAmount,
                excessiveAmount
            )
        );
        digitalEuro.transfer(investor2, excessiveAmount);
    }

    function test_Transfer_ApprovedTransferFrom() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 approvalAmount = 200 ether;
        uint256 transferAmount = 100 ether;

        // Approve investor2 to spend investor1's tokens
        vm.prank(investor1);
        digitalEuro.approve(investor2, approvalAmount);

        assertEq(digitalEuro.allowance(investor1, investor2), approvalAmount);

        // Transfer from investor1 to owner using investor2's approval
        vm.prank(investor2);
        digitalEuro.transferFrom(investor1, owner, transferAmount);

        assertEq(digitalEuro.balanceOf(owner), transferAmount);
    }

    function test_Transfer_RevertCheck_TransferFromWithoutApproval() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 transferAmount = 100 ether;

        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                unauthorizedUser,
                0,
                transferAmount
            )
        );
        digitalEuro.transferFrom(investor1, investor2, transferAmount);
    }

    function test_Transfer_RevertCheck_ToZeroAddress() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 transferAmount = 100 ether;
        address zeroAddress = address(0);

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                zeroAddress
            )
        );
        digitalEuro.transfer(zeroAddress, transferAmount);
    }

    function test_Transfer_EmitsTransferEvent() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 transferAmount = 100 ether;

        vm.expectEmit(true, true, false, true);
        emit Transfer(investor1, investor2, transferAmount); // Value is not indexed, so 3rd arg is false

        vm.prank(investor1);
        digitalEuro.transfer(investor2, transferAmount);
    }

    function test_Transfer_EmitsApprovalEvent() public {
        uint256 approvalAmount = 500 ether;

        vm.expectEmit(true, true, false, true);
        emit Approval(investor1, investor2, approvalAmount);

        vm.prank(investor1);
        digitalEuro.approve(investor2, approvalAmount);
    }

    function test_Transfer_ReducesAllowanceAfterTransferFrom() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 approvalAmount = 500 ether;
        uint256 transferAmount = 200 ether;

        vm.prank(investor1);
        digitalEuro.approve(investor2, approvalAmount);

        vm.prank(investor2);
        digitalEuro.transferFrom(investor1, owner, transferAmount);

        uint256 remaining = digitalEuro.allowance(investor1, investor2);
        assertEq(remaining, approvalAmount - transferAmount);
    }

    function test_Transfer_RevertCheck_InsufficientAllowance() public {
        uint256 initialAmount = 1000 ether;
        digitalEuro.mint(investor1, initialAmount);

        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 200 ether;

        vm.prank(investor1);
        digitalEuro.approve(investor2, approvalAmount);

        vm.prank(investor2);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                investor2,
                approvalAmount,
                transferAmount
            )
        );
        digitalEuro.transferFrom(investor1, owner, transferAmount);
    }

    function test_Transfer_AllowApproveWithZeroCheck() public {
        uint256 initialApproval = 500 ether;

        vm.prank(investor1);
        digitalEuro.approve(investor2, initialApproval);
        assertEq(digitalEuro.allowance(investor1, investor2), initialApproval);

        vm.prank(investor1);
        digitalEuro.approve(investor2, 0);
        assertEq(digitalEuro.allowance(investor1, investor2), 0);
    }

    // Access Control Tests
    function test_AccessControl_AdminCanGrantMinterRole() public {
        digitalEuro.grantRole(MINTER_ROLE, investor1);
        assertTrue(digitalEuro.hasRole(MINTER_ROLE, investor1));

        // New minter should be able to mint
        uint256 mintAmount = 500 ether;
        vm.prank(investor1);
        digitalEuro.mint(investor2, mintAmount);

        assertEq(digitalEuro.balanceOf(investor2), mintAmount);
    }

    function test_AccessControl_AdminCanRevokeMinterRole() public {
        digitalEuro.grantRole(MINTER_ROLE, investor1);
        digitalEuro.revokeRole(MINTER_ROLE, investor1);

        assertFalse(digitalEuro.hasRole(MINTER_ROLE, investor1));

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                investor1,
                MINTER_ROLE
            )
        );
        digitalEuro.mint(investor2, 100 ether);
    }

    function test_AccessControl_RenounceRole() public {
        digitalEuro.grantRole(MINTER_ROLE, investor1);
        assertTrue(digitalEuro.hasRole(MINTER_ROLE, investor1));

        vm.prank(investor1);
        digitalEuro.renounceRole(MINTER_ROLE, investor1);

        assertFalse(digitalEuro.hasRole(MINTER_ROLE, investor1));

        vm.prank(investor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                investor1,
                MINTER_ROLE
            )
        );
        digitalEuro.mint(investor2, 100 ether);
    }

    function test_AccessControl_RevertCheck_NonAdminCannotGrantRoles() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                unauthorizedUser,
                DEFAULT_ADMIN_ROLE
            )
        );
        digitalEuro.grantRole(MINTER_ROLE, investor2);
    }

    // Integration Test
    function test_Integration_CompleteFlow() public {
        // Central Bank mints tokens
        digitalEuro.mint(investor1, 5000 ether);
        digitalEuro.mint(investor2, 3000 ether);

        assertEq(digitalEuro.balanceOf(investor1), 5000 ether);
        assertEq(digitalEuro.balanceOf(investor2), 3000 ether);

        // Investor1 transfers to investor2
        vm.prank(investor1);
        digitalEuro.transfer(investor2, 1000 ether);

        assertEq(digitalEuro.balanceOf(investor1), 4000 ether);
        assertEq(digitalEuro.balanceOf(investor2), 4000 ether);

        // Investor2 approves investor1
        vm.prank(investor2);
        digitalEuro.approve(investor1, 500 ether);

        // Investor1 uses approval to transfer to themselves
        vm.prank(investor1);
        digitalEuro.transferFrom(investor2, investor1, 500 ether);

        assertEq(digitalEuro.balanceOf(investor1), 4500 ether);
        assertEq(digitalEuro.balanceOf(investor2), 3500 ether);

        assertEq(digitalEuro.totalSupply(), 8000 ether);
    }
}
