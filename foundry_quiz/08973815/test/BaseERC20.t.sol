// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/BaseERC20.sol";

contract BaseERC20Test is Test {
    BaseERC20 public token;

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;

    function setUp() public {
        vm.prank(owner);
        token = new BaseERC20("TestToken", "TEST", 18, INITIAL_SUPPLY);
    }

    function test_InitialState() public {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_Transfer_Success() public {
        uint256 transferAmount = 1000 * 10**18;

        vm.prank(owner);
        bool success = token.transfer(alice, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }

    function test_Transfer_InsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;

        vm.prank(owner);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(alice, transferAmount);
    }

    function test_Transfer_EmitsEvent() public {
        uint256 transferAmount = 1000 * 10**18;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit BaseERC20.Transfer(owner, alice, transferAmount);
        token.transfer(alice, transferAmount);
    }

    function test_Approve_Success() public {
        uint256 approveAmount = 5000 * 10**18;

        vm.prank(owner);
        bool success = token.approve(alice, approveAmount);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), approveAmount);
    }

    function test_Approve_EmitsEvent() public {
        uint256 approveAmount = 5000 * 10**18;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit BaseERC20.Approval(owner, alice, approveAmount);
        token.approve(alice, approveAmount);
    }

    function test_TransferFrom_Success() public {
        uint256 approveAmount = 5000 * 10**18;
        uint256 transferAmount = 3000 * 10**18;

        // Owner approves Alice
        vm.prank(owner);
        token.approve(alice, approveAmount);

        // Alice transfers from Owner to Bob
        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approveAmount - transferAmount);
    }

    function test_TransferFrom_InsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;

        vm.prank(owner);
        token.approve(alice, transferAmount);

        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transferFrom(owner, bob, transferAmount);
    }

    function test_TransferFrom_InsufficientAllowance() public {
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 2000 * 10**18;

        vm.prank(owner);
        token.approve(alice, approveAmount);

        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        token.transferFrom(owner, bob, transferAmount);
    }

    function test_BalanceOf_ZeroAddress() public {
        vm.expectRevert("ERC20: balance query for the zero address");
        token.balanceOf(address(0));
    }

    function test_Allowance() public {
        uint256 approveAmount = 1000 * 10**18;

        // Initially zero
        assertEq(token.allowance(owner, alice), 0);

        // After approval
        vm.prank(owner);
        token.approve(alice, approveAmount);
        assertEq(token.allowance(owner, alice), approveAmount);
    }

    // Fuzz testing
    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount <= INITIAL_SUPPLY);

        vm.prank(owner);
        bool success = token.transfer(alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        vm.prank(owner);
        bool success = token.approve(alice, amount);

        assertTrue(success);
        assertEq(token.allowance(owner, alice), amount);
    }
}
