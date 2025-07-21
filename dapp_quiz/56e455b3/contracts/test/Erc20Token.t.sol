// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Erc20Token} from "../src/Erc20Token.sol";

contract Erc20TokenTest is Test {
    Erc20Token public token;

    // Test accounts
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    // Token parameters
    string constant TOKEN_NAME = "Test Token";
    string constant TOKEN_SYMBOL = "TEST";
    uint8 constant TOKEN_DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1000000 * 10**TOKEN_DECIMALS; // 1M tokens

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        // Set up test accounts
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);
        charlie = address(0x3);

        // Deploy token contract
        token = new Erc20Token(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOTAL_SUPPLY);
    }

    // ============================================================================
    // Constructor and Basic Properties Tests
    // ============================================================================

    function test_Constructor() public {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), TOKEN_DECIMALS);
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    // ============================================================================
    // BalanceOf Tests
    // ============================================================================

    function test_BalanceOf_Owner() public {
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    function test_BalanceOf_EmptyAccount() public {
        assertEq(token.balanceOf(alice), 0);
    }

    function test_BalanceOf_ZeroAddress_Reverts() public {
        vm.expectRevert("ERC20: balance query for the zero address");
        token.balanceOf(address(0));
    }

    // ============================================================================
    // Transfer Tests
    // ============================================================================

    function test_Transfer_Success() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, amount);

        bool success = token.transfer(alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_Transfer_ZeroAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 0);

        bool success = token.transfer(alice, 0);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }

    function test_Transfer_ToSelf() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, owner, amount);

        bool success = token.transfer(owner, amount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    function test_Transfer_InsufficientBalance_Reverts() public {
        uint256 amount = TOTAL_SUPPLY + 1;

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(alice, amount);
    }

    function test_Transfer_FromNonOwner() public {
        // First give Alice some tokens
        uint256 initialAmount = 500 * 10**TOKEN_DECIMALS;
        token.transfer(alice, initialAmount);

        // Now Alice transfers to Bob
        uint256 transferAmount = 100 * 10**TOKEN_DECIMALS;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, transferAmount);

        bool success = token.transfer(bob, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(alice), initialAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }

    // ============================================================================
    // Approve Tests
    // ============================================================================

    function test_Approve_Success() public {
        uint256 amount = 200 * 10**TOKEN_DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, amount);

        bool success = token.approve(alice, amount);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), amount);
    }

    function test_Approve_ZeroAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, 0);

        bool success = token.approve(alice, 0);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_Approve_OverwriteExistingApproval() public {
        uint256 firstAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 secondAmount = 200 * 10**TOKEN_DECIMALS;

        // First approval
        token.approve(alice, firstAmount);
        assertEq(token.allowance(owner, alice), firstAmount);

        // Overwrite with second approval
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, secondAmount);

        bool success = token.approve(alice, secondAmount);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), secondAmount);
    }

    // ============================================================================
    // Allowance Tests
    // ============================================================================

    function test_Allowance_NoApproval() public {
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_Allowance_WithApproval() public {
        uint256 amount = 150 * 10**TOKEN_DECIMALS;
        token.approve(alice, amount);
        assertEq(token.allowance(owner, alice), amount);
    }

    // ============================================================================
    // TransferFrom Tests
    // ============================================================================

    function test_TransferFrom_Success() public {
        uint256 approvalAmount = 300 * 10**TOKEN_DECIMALS;
        uint256 transferAmount = 150 * 10**TOKEN_DECIMALS;

        // Owner approves Alice to spend tokens
        token.approve(alice, approvalAmount);

        // Alice transfers from owner to bob
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, bob, transferAmount);

        bool success = token.transferFrom(owner, bob, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approvalAmount - transferAmount);
    }

    function test_TransferFrom_ExactAllowance() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        token.approve(alice, amount);

        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, amount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_TransferFrom_InsufficientBalance_Reverts() public {
        // Give Alice approval for more than owner has
        token.approve(alice, TOTAL_SUPPLY + 1);

        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transferFrom(owner, bob, TOTAL_SUPPLY + 1);
    }

    function test_TransferFrom_InsufficientAllowance_Reverts() public {
        uint256 approvalAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 transferAmount = 200 * 10**TOKEN_DECIMALS;

        token.approve(alice, approvalAmount);

        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        token.transferFrom(owner, bob, transferAmount);
    }

    function test_TransferFrom_NoApproval_Reverts() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        token.transferFrom(owner, bob, amount);
    }

    function test_TransferFrom_SelfTransfer() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        // Owner approves self
        token.approve(owner, amount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, amount);

        bool success = token.transferFrom(owner, alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.allowance(owner, owner), 0);
    }

    // ============================================================================
    // Fuzz Tests
    // ============================================================================

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount <= TOTAL_SUPPLY);

        bool success = token.transfer(alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        bool success = token.approve(alice, amount);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), amount);
    }

    function testFuzz_TransferFrom(uint256 approvalAmount, uint256 transferAmount) public {
        vm.assume(transferAmount <= approvalAmount);
        vm.assume(transferAmount <= TOTAL_SUPPLY);

        token.approve(alice, approvalAmount);

        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approvalAmount - transferAmount);
    }

    // ============================================================================
    // Integration Tests
    // ============================================================================

    function test_MultipleTransfers() public {
        uint256 amount1 = 100 * 10**TOKEN_DECIMALS;
        uint256 amount2 = 200 * 10**TOKEN_DECIMALS;
        uint256 amount3 = 50 * 10**TOKEN_DECIMALS;

        // Owner -> Alice
        token.transfer(alice, amount1);

        // Owner -> Bob
        token.transfer(bob, amount2);

        // Alice -> Charlie
        vm.prank(alice);
        token.transfer(charlie, amount3);

        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount1 - amount2);
        assertEq(token.balanceOf(alice), amount1 - amount3);
        assertEq(token.balanceOf(bob), amount2);
        assertEq(token.balanceOf(charlie), amount3);
    }

    function test_ApprovalAndTransferFromChain() public {
        uint256 amount = 300 * 10**TOKEN_DECIMALS;

        // Owner approves Alice
        token.approve(alice, amount);

        // Alice transfers part to Bob
        vm.prank(alice);
        token.transferFrom(owner, bob, amount / 2);

        // Alice transfers rest to Charlie
        vm.prank(alice);
        token.transferFrom(owner, charlie, amount / 2);

        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - amount);
        assertEq(token.balanceOf(bob), amount / 2);
        assertEq(token.balanceOf(charlie), amount / 2);
        assertEq(token.allowance(owner, alice), 0);
    }
}
