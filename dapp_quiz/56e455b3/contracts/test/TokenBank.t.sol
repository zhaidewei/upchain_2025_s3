// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract TokenBankTest is Test {
    TokenBank public bank;

    // Test accounts
    address public admin;
    address public alice;
    address public bob;
    address public charlie;
    address public david;
    address public eve;

    // Test amounts
    uint256 constant SMALL_DEPOSIT = 0.1 ether;
    uint256 constant MEDIUM_DEPOSIT = 1 ether;
    uint256 constant LARGE_DEPOSIT = 5 ether;
    uint256 constant HUGE_DEPOSIT = 10 ether;

    function setUp() public {
        // Set up test accounts
        admin = address(0x999); // Use a proper EOA
        alice = address(0x1);
        bob = address(0x2);
        charlie = address(0x3);
        david = address(0x4);
        eve = address(0x5);

        // Give test accounts some ETH
        vm.deal(admin, 100 ether); // Give it some ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(david, 100 ether);
        vm.deal(eve, 100 ether);

        // Deploy bank contract
        bank = new TokenBank();
    }

    // ============================================================================
    // Constructor and Basic Properties Tests
    // ============================================================================

    function test_Constructor() public {
        assertEq(bank.admin(), admin);
        assertEq(bank.getContractBalance(), 0);
        assertEq(bank.getDepositorsCount(), 0);
    }

    // ============================================================================
    // Deposit Tests
    // ============================================================================

    function test_Deposit_Success() public {
        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        assertEq(bank.balances(alice), MEDIUM_DEPOSIT);
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT);
        assertEq(bank.getDepositorsCount(), 1);
        assertEq(bank.depositors(0), alice);
    }

    function test_Deposit_ZeroAmount_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.deposit{value: 0}();
    }

    function test_Deposit_MultipleDepositsFromSameUser() public {
        vm.startPrank(alice);

        bank.deposit{value: SMALL_DEPOSIT}();
        assertEq(bank.balances(alice), SMALL_DEPOSIT);
        assertEq(bank.getDepositorsCount(), 1);

        bank.deposit{value: MEDIUM_DEPOSIT}();
        assertEq(bank.balances(alice), SMALL_DEPOSIT + MEDIUM_DEPOSIT);
        assertEq(bank.getDepositorsCount(), 1); // Should not increase

        vm.stopPrank();
    }

    function test_Deposit_MultipleDifferentUsers() public {
        vm.prank(alice);
        bank.deposit{value: SMALL_DEPOSIT}();

        vm.prank(bob);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        vm.prank(charlie);
        bank.deposit{value: LARGE_DEPOSIT}();

        assertEq(bank.balances(alice), SMALL_DEPOSIT);
        assertEq(bank.balances(bob), MEDIUM_DEPOSIT);
        assertEq(bank.balances(charlie), LARGE_DEPOSIT);
        assertEq(bank.getContractBalance(), SMALL_DEPOSIT + MEDIUM_DEPOSIT + LARGE_DEPOSIT);
        assertEq(bank.getDepositorsCount(), 3);
    }

    function test_Deposit_ViaReceive() public {
        vm.prank(alice);
        (bool success,) = address(bank).call{value: MEDIUM_DEPOSIT}("");

        assertTrue(success);
        assertEq(bank.balances(alice), MEDIUM_DEPOSIT);
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT);
    }

    function test_Deposit_ViaFallback() public {
        vm.prank(alice);
        (bool success,) = address(bank).call{value: MEDIUM_DEPOSIT}("nonexistentFunction()");

        assertTrue(success);
        assertEq(bank.balances(alice), MEDIUM_DEPOSIT);
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT);
    }

    function test_Deposit_ViaDirectTransfer() public {
        vm.prank(alice);
        payable(address(bank)).transfer(MEDIUM_DEPOSIT);

        assertEq(bank.balances(alice), MEDIUM_DEPOSIT);
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT);
    }

    // ============================================================================
    // Withdrawal Tests
    // ============================================================================

    function test_Withdraw_Success() public {
        // First, make some deposits
        vm.prank(alice);
        bank.deposit{value: LARGE_DEPOSIT}();

        uint256 withdrawAmount = 2 ether;
        uint256 adminBalanceBefore = admin.balance;

        bank.withdraw(withdrawAmount);

        assertEq(bank.getContractBalance(), LARGE_DEPOSIT - withdrawAmount);
        assertEq(admin.balance, adminBalanceBefore + withdrawAmount);
    }

    function test_Withdraw_OnlyAdmin() public {
        vm.prank(alice);
        bank.deposit{value: LARGE_DEPOSIT}();

        vm.prank(alice);
        vm.expectRevert("Only admin can call this function");
        bank.withdraw(1 ether);
    }

    function test_Withdraw_ZeroAmount_Reverts() public {
        vm.expectRevert("Withdrawal amount must be greater than 0");
        bank.withdraw(0);
    }

    function test_Withdraw_InsufficientBalance_Reverts() public {
        vm.prank(alice);
        bank.deposit{value: SMALL_DEPOSIT}();

        vm.expectRevert("Insufficient contract balance");
        bank.withdraw(MEDIUM_DEPOSIT);
    }

    function test_Withdraw_ExactBalance() public {
        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        uint256 adminBalanceBefore = admin.balance;

        bank.withdraw(MEDIUM_DEPOSIT);

        assertEq(bank.getContractBalance(), 0);
        assertEq(admin.balance, adminBalanceBefore + MEDIUM_DEPOSIT);
    }

    // ============================================================================
    // Top Depositors Tests
    // ============================================================================

    function test_GetTopDepositors_EmptyBank() public {
        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        for (uint256 i = 0; i < 3; i++) {
            assertEq(topDepositors[i].depositor, address(0));
            assertEq(topDepositors[i].amount, 0);
        }
    }

    function test_GetTopDepositors_OneDepositor() public {
        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, MEDIUM_DEPOSIT);
        assertEq(topDepositors[1].depositor, address(0));
        assertEq(topDepositors[2].depositor, address(0));
    }

    function test_GetTopDepositors_TwoDepositors() public {
        vm.prank(alice);
        bank.deposit{value: LARGE_DEPOSIT}();

        vm.prank(bob);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        // Alice should be first (larger deposit)
        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, LARGE_DEPOSIT);

        // Bob should be second
        assertEq(topDepositors[1].depositor, bob);
        assertEq(topDepositors[1].amount, MEDIUM_DEPOSIT);

        // Third slot should be empty
        assertEq(topDepositors[2].depositor, address(0));
    }

    function test_GetTopDepositors_ThreeDepositors() public {
        vm.prank(alice);
        bank.deposit{value: LARGE_DEPOSIT}();

        vm.prank(bob);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        vm.prank(charlie);
        bank.deposit{value: SMALL_DEPOSIT}();

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, LARGE_DEPOSIT);

        assertEq(topDepositors[1].depositor, bob);
        assertEq(topDepositors[1].amount, MEDIUM_DEPOSIT);

        assertEq(topDepositors[2].depositor, charlie);
        assertEq(topDepositors[2].amount, SMALL_DEPOSIT);
    }

    function test_GetTopDepositors_MoreThanThreeDepositors() public {
        // Set up deposits in non-sorted order
        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}(); // 1 ether

        vm.prank(bob);
        bank.deposit{value: HUGE_DEPOSIT}(); // 10 ether - should be #1

        vm.prank(charlie);
        bank.deposit{value: SMALL_DEPOSIT}(); // 0.1 ether - should not be in top 3

        vm.prank(david);
        bank.deposit{value: LARGE_DEPOSIT}(); // 5 ether - should be #2

        vm.prank(eve);
        bank.deposit{value: 2 ether}(); // 2 ether - should be #3

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        // Check the ranking: Bob (10), David (5), Eve (2)
        assertEq(topDepositors[0].depositor, bob);
        assertEq(topDepositors[0].amount, HUGE_DEPOSIT);

        assertEq(topDepositors[1].depositor, david);
        assertEq(topDepositors[1].amount, LARGE_DEPOSIT);

        assertEq(topDepositors[2].depositor, eve);
        assertEq(topDepositors[2].amount, 2 ether);
    }

    function test_GetTopDepositors_UserIncreasesDeposit() public {
        // Initial deposits
        vm.prank(alice);
        bank.deposit{value: SMALL_DEPOSIT}(); // 0.1 ether

        vm.prank(bob);
        bank.deposit{value: MEDIUM_DEPOSIT}(); // 1 ether

        vm.prank(charlie);
        bank.deposit{value: LARGE_DEPOSIT}(); // 5 ether

        // Alice increases her deposit to become top depositor
        vm.prank(alice);
        bank.deposit{value: HUGE_DEPOSIT}(); // Total: 10.1 ether

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        // Alice should now be #1
        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, SMALL_DEPOSIT + HUGE_DEPOSIT);

        assertEq(topDepositors[1].depositor, charlie);
        assertEq(topDepositors[1].amount, LARGE_DEPOSIT);

        assertEq(topDepositors[2].depositor, bob);
        assertEq(topDepositors[2].amount, MEDIUM_DEPOSIT);
    }

    function test_GetTopDepositors_EqualAmounts() public {
        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        vm.prank(bob);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        vm.prank(charlie);
        bank.deposit{value: MEDIUM_DEPOSIT}();

        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();

        // All should have the same amount, order depends on when they were added
        for (uint256 i = 0; i < 3; i++) {
            assertEq(topDepositors[i].amount, MEDIUM_DEPOSIT);
            assertTrue(topDepositors[i].depositor != address(0));
        }
    }

    // ============================================================================
    // Balance Query Tests
    // ============================================================================

    function test_GetContractBalance() public {
        assertEq(bank.getContractBalance(), 0);

        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT);

        vm.prank(bob);
        bank.deposit{value: LARGE_DEPOSIT}();
        assertEq(bank.getContractBalance(), MEDIUM_DEPOSIT + LARGE_DEPOSIT);
    }

    function test_GetDepositorsCount() public {
        assertEq(bank.getDepositorsCount(), 0);

        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();
        assertEq(bank.getDepositorsCount(), 1);

        vm.prank(bob);
        bank.deposit{value: LARGE_DEPOSIT}();
        assertEq(bank.getDepositorsCount(), 2);

        // Same user deposits again - count should not increase
        vm.prank(alice);
        bank.deposit{value: SMALL_DEPOSIT}();
        assertEq(bank.getDepositorsCount(), 2);
    }

    function test_UserBalances() public {
        assertEq(bank.balances(alice), 0);

        vm.prank(alice);
        bank.deposit{value: MEDIUM_DEPOSIT}();
        assertEq(bank.balances(alice), MEDIUM_DEPOSIT);

        vm.prank(alice);
        bank.deposit{value: SMALL_DEPOSIT}();
        assertEq(bank.balances(alice), MEDIUM_DEPOSIT + SMALL_DEPOSIT);
    }

    // ============================================================================
    // Fuzz Tests
    // ============================================================================

    function testFuzz_Deposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);

        vm.deal(alice, amount);
        vm.prank(alice);
        bank.deposit{value: amount}();

        assertEq(bank.balances(alice), amount);
        assertEq(bank.getContractBalance(), amount);
        assertEq(bank.getDepositorsCount(), 1);
    }

    function testFuzz_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        vm.deal(alice, depositAmount);
        vm.prank(alice);
        bank.deposit{value: depositAmount}();

        uint256 adminBalanceBefore = admin.balance;
        bank.withdraw(withdrawAmount);

        assertEq(bank.getContractBalance(), depositAmount - withdrawAmount);
        assertEq(admin.balance, adminBalanceBefore + withdrawAmount);
    }

    // ============================================================================
    // Integration Tests
    // ============================================================================

    function test_CompleteWorkflow() public {
        // Multiple users deposit
        vm.prank(alice);
        bank.deposit{value: 3 ether}();

        vm.prank(bob);
        bank.deposit{value: 7 ether}();

        vm.prank(charlie);
        bank.deposit{value: 1 ether}();

        // Check state
        assertEq(bank.getContractBalance(), 11 ether);
        assertEq(bank.getDepositorsCount(), 3);

        // Check top depositors
        TokenBank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, bob); // 7 ether
        assertEq(topDepositors[1].depositor, alice); // 3 ether
        assertEq(topDepositors[2].depositor, charlie); // 1 ether

        // Admin withdraws partial amount
        bank.withdraw(5 ether);
        assertEq(bank.getContractBalance(), 6 ether);

        // User makes another deposit
        vm.prank(charlie);
        bank.deposit{value: 8 ether}(); // Charlie now has 9 ether total

        // Check updated rankings
        topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, charlie); // 9 ether
        assertEq(topDepositors[1].depositor, bob); // 7 ether
        assertEq(topDepositors[2].depositor, alice); // 3 ether

        assertEq(bank.getContractBalance(), 14 ether);
    }

    function test_EdgeCase_AdminWithdrawAll() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        vm.prank(bob);
        bank.deposit{value: 3 ether}();

        uint256 totalBalance = bank.getContractBalance();
        assertEq(totalBalance, 8 ether);

        uint256 adminBalanceBefore = admin.balance;
        bank.withdraw(totalBalance);

        assertEq(bank.getContractBalance(), 0);
        assertEq(admin.balance, adminBalanceBefore + totalBalance);

        // User balances should still be tracked even after withdrawal
        assertEq(bank.balances(alice), 5 ether);
        assertEq(bank.balances(bob), 3 ether);
    }
}
