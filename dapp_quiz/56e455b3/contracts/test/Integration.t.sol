// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Erc20Token} from "../src/Erc20Token.sol";
import {TokenBank} from "../src/TokenBank.sol";

/**
 * @title Integration Test Suite
 * @dev Tests the interaction between ERC20 tokens and TokenBank
 * Simulates real-world DApp scenarios where users manage both ETH and ERC20 tokens
 */
contract IntegrationTest is Test {
    Erc20Token public paymentToken;
    TokenBank public ethBank;

    // Test accounts
    address public deployer;
    address public alice;
    address public bob;
    address public charlie;

    // Token parameters
    string constant TOKEN_NAME = "Payment Token";
    string constant TOKEN_SYMBOL = "PAY";
    uint8 constant TOKEN_DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1000000 * 10**TOKEN_DECIMALS;

    // Test amounts
    uint256 constant INITIAL_ETH_BALANCE = 100 ether;
    uint256 constant INITIAL_TOKEN_BALANCE = 10000 * 10**TOKEN_DECIMALS;

    function setUp() public {
        // Set up test accounts
        deployer = address(this);
        alice = address(0x1);
        bob = address(0x2);
        charlie = address(0x3);

        // Give test accounts ETH
        vm.deal(alice, INITIAL_ETH_BALANCE);
        vm.deal(bob, INITIAL_ETH_BALANCE);
        vm.deal(charlie, INITIAL_ETH_BALANCE);

        // Deploy contracts
        paymentToken = new Erc20Token(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOTAL_SUPPLY);
        ethBank = new TokenBank();

        // Distribute tokens to test accounts
        paymentToken.transfer(alice, INITIAL_TOKEN_BALANCE);
        paymentToken.transfer(bob, INITIAL_TOKEN_BALANCE);
        paymentToken.transfer(charlie, INITIAL_TOKEN_BALANCE);
    }

    // ============================================================================
    // Basic Integration Tests
    // ============================================================================

    function test_DeploymentState() public {
        // Check token deployment
        assertEq(paymentToken.name(), TOKEN_NAME);
        assertEq(paymentToken.symbol(), TOKEN_SYMBOL);
        assertEq(paymentToken.totalSupply(), TOTAL_SUPPLY);

        // Check bank deployment
        assertEq(ethBank.admin(), deployer);
        assertEq(ethBank.getContractBalance(), 0);

        // Check token distribution
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE);
        assertEq(paymentToken.balanceOf(charlie), INITIAL_TOKEN_BALANCE);
    }

    // ============================================================================
    // Cross-Contract User Journey Tests
    // ============================================================================

    function test_UserJourney_TokenTransferAndETHDeposit() public {
        // Alice transfers tokens to Bob
        vm.prank(alice);
        paymentToken.transfer(bob, 1000 * 10**TOKEN_DECIMALS);

        // Alice deposits ETH to bank
        vm.prank(alice);
        ethBank.deposit{value: 5 ether}();

        // Bob deposits ETH to bank
        vm.prank(bob);
        ethBank.deposit{value: 3 ether}();

        // Verify final states
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE - 1000 * 10**TOKEN_DECIMALS);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE + 1000 * 10**TOKEN_DECIMALS);
        assertEq(ethBank.balances(alice), 5 ether);
        assertEq(ethBank.balances(bob), 3 ether);
        assertEq(ethBank.getContractBalance(), 8 ether);
    }

    function test_UserJourney_TokenAllowanceAndETHRanking() public {
        // Users approve each other for token spending
        vm.prank(alice);
        paymentToken.approve(bob, 2000 * 10**TOKEN_DECIMALS);

        vm.prank(bob);
        paymentToken.approve(charlie, 1500 * 10**TOKEN_DECIMALS);

        // Users deposit different amounts to ETH bank to create rankings
        vm.prank(alice);
        ethBank.deposit{value: 10 ether}(); // Should be #1

        vm.prank(bob);
        ethBank.deposit{value: 7 ether}(); // Should be #2

        vm.prank(charlie);
        ethBank.deposit{value: 3 ether}(); // Should be #3

        // Bob uses allowance to transfer Alice's tokens to Charlie
        vm.prank(bob);
        paymentToken.transferFrom(alice, charlie, 1000 * 10**TOKEN_DECIMALS);

        // Verify token balances
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE - 1000 * 10**TOKEN_DECIMALS);
        assertEq(paymentToken.balanceOf(charlie), INITIAL_TOKEN_BALANCE + 1000 * 10**TOKEN_DECIMALS);
        assertEq(paymentToken.allowance(alice, bob), 1000 * 10**TOKEN_DECIMALS); // Reduced by 1000

        // Verify ETH bank rankings
        TokenBank.TopDepositor[3] memory topDepositors = ethBank.getTopDepositors();
        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, 10 ether);
        assertEq(topDepositors[1].depositor, bob);
        assertEq(topDepositors[1].amount, 7 ether);
        assertEq(topDepositors[2].depositor, charlie);
        assertEq(topDepositors[2].amount, 3 ether);
    }

    // ============================================================================
    // DeFi-like Scenarios
    // ============================================================================

    function test_DeFiScenario_LiquidityProvider() public {
        // Simulate a user providing liquidity (tokens) and collateral (ETH)

        // Alice provides maximum token liquidity to the ecosystem
        uint256 liquidityAmount = INITIAL_TOKEN_BALANCE / 2;
        vm.prank(alice);
        paymentToken.transfer(bob, liquidityAmount); // Simulate LP token distribution

        // Alice locks ETH as collateral
        uint256 collateralAmount = 15 ether;
        vm.prank(alice);
        ethBank.deposit{value: collateralAmount}();

        // Bob and Charlie also participate with smaller amounts
        vm.prank(bob);
        paymentToken.transfer(charlie, liquidityAmount / 4);

        vm.prank(bob);
        ethBank.deposit{value: 8 ether}();

        vm.prank(charlie);
        ethBank.deposit{value: 2 ether}();

        // Verify the liquidity distribution
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE - liquidityAmount);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE + liquidityAmount - liquidityAmount / 4);
        assertEq(paymentToken.balanceOf(charlie), INITIAL_TOKEN_BALANCE + liquidityAmount / 4);

        // Verify collateral rankings (Alice should be top provider)
        TokenBank.TopDepositor[3] memory topDepositors = ethBank.getTopDepositors();
        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, collateralAmount);
    }

    function test_DeFiScenario_TokenSwapWithETHFees() public {
        // Simulate a token swap scenario where ETH is used for fees

        uint256 swapAmount = 5000 * 10**TOKEN_DECIMALS;
        uint256 feeAmount = 0.1 ether;

        // Alice wants to swap tokens with Bob
        // First, Alice approves Bob to spend her tokens
        vm.prank(alice);
        paymentToken.approve(bob, swapAmount);

        // Alice deposits ETH fee to the bank (simulating fee payment)
        vm.prank(alice);
        ethBank.deposit{value: feeAmount}();

        // Bob executes the swap (transferFrom Alice's tokens)
        vm.prank(bob);
        paymentToken.transferFrom(alice, bob, swapAmount);

        // Bob also pays a fee
        vm.prank(bob);
        ethBank.deposit{value: feeAmount}();

        // Verify the swap occurred
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE - swapAmount);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE + swapAmount);

        // Verify fees were collected
        assertEq(ethBank.balances(alice), feeAmount);
        assertEq(ethBank.balances(bob), feeAmount);
        assertEq(ethBank.getContractBalance(), feeAmount * 2);
    }

    // ============================================================================
    // Multi-User Competition Scenarios
    // ============================================================================

    function test_Competition_TokenRaceAndETHRanking() public {
        // Simulate a scenario where users compete in both token accumulation and ETH deposits

        // Round 1: Initial positioning
        vm.prank(alice);
        paymentToken.transfer(bob, 2000 * 10**TOKEN_DECIMALS);

        vm.prank(alice);
        ethBank.deposit{value: 5 ether}();

        // Round 2: Bob's counter-move
        vm.prank(bob);
        paymentToken.transfer(charlie, 3000 * 10**TOKEN_DECIMALS);

        vm.prank(bob);
        ethBank.deposit{value: 8 ether}(); // Bob takes the lead

        // Round 3: Charlie's surprise move
        vm.prank(charlie);
        paymentToken.transfer(alice, 1000 * 10**TOKEN_DECIMALS); // Give back to Alice

        vm.prank(charlie);
        ethBank.deposit{value: 12 ether}(); // Charlie takes the lead

        // Round 4: Alice's final push
        vm.prank(alice);
        ethBank.deposit{value: 10 ether}(); // Alice total: 15 ether

        // Verify final token distribution
        uint256 aliceTokens = INITIAL_TOKEN_BALANCE - 2000 * 10**TOKEN_DECIMALS + 1000 * 10**TOKEN_DECIMALS;
        uint256 bobTokens = INITIAL_TOKEN_BALANCE + 2000 * 10**TOKEN_DECIMALS - 3000 * 10**TOKEN_DECIMALS;
        uint256 charlieTokens = INITIAL_TOKEN_BALANCE + 3000 * 10**TOKEN_DECIMALS - 1000 * 10**TOKEN_DECIMALS;

        assertEq(paymentToken.balanceOf(alice), aliceTokens);
        assertEq(paymentToken.balanceOf(bob), bobTokens);
        assertEq(paymentToken.balanceOf(charlie), charlieTokens);

        // Verify final ETH rankings
        TokenBank.TopDepositor[3] memory topDepositors = ethBank.getTopDepositors();
        assertEq(topDepositors[0].depositor, alice); // 15 ether
        assertEq(topDepositors[0].amount, 15 ether);
        assertEq(topDepositors[1].depositor, charlie); // 12 ether
        assertEq(topDepositors[1].amount, 12 ether);
        assertEq(topDepositors[2].depositor, bob); // 8 ether
        assertEq(topDepositors[2].amount, 8 ether);
    }

    // ============================================================================
    // Error Handling and Edge Cases
    // ============================================================================

    function test_ErrorHandling_TokenAndETHFailures() public {
        // Test token transfer failure doesn't affect ETH operations
        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        paymentToken.transfer(bob, INITIAL_TOKEN_BALANCE + 1);

        // ETH operations should still work
        vm.prank(alice);
        ethBank.deposit{value: 1 ether}();
        assertEq(ethBank.balances(alice), 1 ether);

        // Test ETH withdrawal failure doesn't affect token operations
        vm.prank(alice);
        vm.expectRevert("Only admin can call this function");
        ethBank.withdraw(1 ether);

        // Token operations should still work
        vm.prank(alice);
        paymentToken.transfer(bob, 1000 * 10**TOKEN_DECIMALS);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE + 1000 * 10**TOKEN_DECIMALS);
    }

    function test_EdgeCase_ZeroBalanceOperations() public {
        // Test operations with zero balances

        // Alice transfers all her tokens away
        vm.prank(alice);
        paymentToken.transfer(bob, INITIAL_TOKEN_BALANCE);
        assertEq(paymentToken.balanceOf(alice), 0);

        // Alice can still deposit ETH
        vm.prank(alice);
        ethBank.deposit{value: 5 ether}();
        assertEq(ethBank.balances(alice), 5 ether);

        // Alice cannot transfer tokens she doesn't have
        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        paymentToken.transfer(charlie, 1);

        // But she can still interact with ETH bank
        TokenBank.TopDepositor[3] memory topDepositors = ethBank.getTopDepositors();
        assertEq(topDepositors[0].depositor, alice);
        assertEq(topDepositors[0].amount, 5 ether);
    }

    // ============================================================================
    // Admin Operations Integration
    // ============================================================================

    function test_AdminOperations_WithActiveUsers() public {
        // Users are actively using both systems
        vm.prank(alice);
        paymentToken.transfer(bob, 1000 * 10**TOKEN_DECIMALS);

        vm.prank(alice);
        ethBank.deposit{value: 10 ether}();

        vm.prank(bob);
        ethBank.deposit{value: 5 ether}();

        // Admin withdraws some ETH (simulating fee collection)
        uint256 adminBalanceBefore = deployer.balance;
        ethBank.withdraw(3 ether);
        assertEq(deployer.balance, adminBalanceBefore + 3 ether);

        // User operations should continue normally
        vm.prank(bob);
        paymentToken.approve(charlie, 500 * 10**TOKEN_DECIMALS);

        vm.prank(charlie);
        paymentToken.transferFrom(bob, charlie, 500 * 10**TOKEN_DECIMALS);

        // Bank should still track user deposits correctly
        assertEq(ethBank.balances(alice), 10 ether);
        assertEq(ethBank.balances(bob), 5 ether);
        assertEq(ethBank.getContractBalance(), 12 ether); // 15 - 3 withdrawn
    }

    // ============================================================================
    // Fuzz Testing Integration
    // ============================================================================

    function testFuzz_TokenAndETHOperations(uint256 tokenAmount, uint256 ethAmount) public {
        // Bound the inputs to reasonable ranges
        tokenAmount = bound(tokenAmount, 1, INITIAL_TOKEN_BALANCE);
        ethAmount = bound(ethAmount, 0.001 ether, INITIAL_ETH_BALANCE);

        // Alice performs both operations
        vm.startPrank(alice);

        paymentToken.transfer(bob, tokenAmount);
        ethBank.deposit{value: ethAmount}();

        vm.stopPrank();

        // Verify both operations succeeded
        assertEq(paymentToken.balanceOf(alice), INITIAL_TOKEN_BALANCE - tokenAmount);
        assertEq(paymentToken.balanceOf(bob), INITIAL_TOKEN_BALANCE + tokenAmount);
        assertEq(ethBank.balances(alice), ethAmount);
        assertEq(ethBank.getContractBalance(), ethAmount);
    }

    // ============================================================================
    // Gas Optimization Tests
    // ============================================================================

    function test_GasUsage_CombinedOperations() public {
        // Measure gas usage for combined operations
        uint256 gasBefore = gasleft();

        vm.startPrank(alice);

        // Perform multiple operations in sequence
        paymentToken.approve(bob, 1000 * 10**TOKEN_DECIMALS);
        paymentToken.transfer(charlie, 500 * 10**TOKEN_DECIMALS);
        ethBank.deposit{value: 2 ether}();

        vm.stopPrank();

        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for analysis (in actual testing, you might want to assert limits)
        console.log("Gas used for combined operations:", gasUsed);

        // Verify all operations succeeded
        assertEq(paymentToken.allowance(alice, bob), 1000 * 10**TOKEN_DECIMALS);
        assertEq(paymentToken.balanceOf(charlie), INITIAL_TOKEN_BALANCE + 500 * 10**TOKEN_DECIMALS);
        assertEq(ethBank.balances(alice), 2 ether);
    }
}
