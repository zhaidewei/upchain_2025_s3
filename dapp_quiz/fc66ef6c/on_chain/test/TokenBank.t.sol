// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {Erc20Eip2612Compatiable} from "../src/Erc20Eip2612Compatiable.sol";

contract TokenBankTest is Test {
    TokenBank public bank;
    Erc20Eip2612Compatiable public token;

    // Test accounts
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public caller = address(4); // Someone who calls permitDeposit for another user

    // Private key for user1 (for signing)
    uint256 private user1PrivateKey = 0xA11CE;

    function setUp() public {
        // Set user1's address based on private key
        user1 = vm.addr(user1PrivateKey);

        vm.startPrank(deployer);

        // Deploy token
        token = new Erc20Eip2612Compatiable("1");

        // Deploy bank
        bank = new TokenBank(address(token));

        // Transfer some tokens to users for testing
        token.transfer(user1, 1000);
        token.transfer(user2, 1000);

        vm.stopPrank();
    }

    function test_BasicSetup() public {
        assertEq(address(bank.token()), address(token));
        assertEq(token.balanceOf(user1), 1000);
        assertEq(token.balanceOf(user2), 1000);
        assertEq(bank.getDepositorsCount(), 0);
    }

    function test_RegularDeposit() public {
        uint256 depositAmount = 100;

        // User1 approves and deposits
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // Check balances
        assertEq(bank.balances(user1), depositAmount);
        assertEq(token.balanceOf(user1), 1000 - depositAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount);
        assertEq(bank.getDepositorsCount(), 1);
    }

    function test_PermitDeposit() public {
        uint256 depositAmount = 200;
        uint256 deadline = block.timestamp + 3600; // 1 hour from now
        uint256 nonce = token.nonces(user1);

        // Create the hash exactly as the token contract does - use nonce + 1
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                depositAmount,
                nonce + 1, // Use next nonce as expected by contract
                deadline))
        ));

        // Sign the hash with user1's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);

        // Execute permit deposit - anyone can call this for user1
        vm.prank(caller);
        bank.permitDeposit(user1, depositAmount, deadline, v, r, s);

        // Check balances
        assertEq(bank.balances(user1), depositAmount);
        assertEq(token.balanceOf(user1), 1000 - depositAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount);
        assertEq(bank.getDepositorsCount(), 1);
        assertEq(token.nonces(user1), 1); // Nonce should increment
    }

    function test_MultipleDeposits() public {
        uint256 depositAmount1 = 100;
        uint256 depositAmount2 = 150;

        // User1 regular deposit
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount1);
        bank.deposit(depositAmount1);
        vm.stopPrank();

        // User2 regular deposit
        vm.startPrank(user2);
        token.approve(address(bank), depositAmount2);
        bank.deposit(depositAmount2);
        vm.stopPrank();

        // Check balances
        assertEq(bank.balances(user1), depositAmount1);
        assertEq(bank.balances(user2), depositAmount2);
        assertEq(bank.getDepositorsCount(), 2);
    }

    function test_Withdraw() public {
        uint256 depositAmount = 300;
        uint256 withdrawAmount = 100;

        // User1 deposits
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        // User1 withdraws
        bank.withdraw(withdrawAmount);
        vm.stopPrank();

        // Check balances
        assertEq(bank.balances(user1), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(user1), 1000 - depositAmount + withdrawAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount - withdrawAmount);
    }

    function test_ContractBalance() public {
        uint256 depositAmount = 500;

        // User1 deposits
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // Check contract balance
        assertEq(bank.getContractBalance(), depositAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount);
    }

    function test_UserBalance() public {
        uint256 depositAmount = 250;

        // User1 deposits
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // Check user balance
        assertEq(bank.getUserBalance(user1), depositAmount);
        assertEq(bank.balances(user1), depositAmount);
    }

        function test_RevertWhen_PermitDepositExpired() public {
        uint256 depositAmount = 200;
        uint256 deadline = block.timestamp - 1; // Expired deadline
        uint256 nonce = token.nonces(user1);

        // Create the hash - use nonce + 1
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                depositAmount,
                nonce + 1, // Use next nonce as expected by contract
                deadline))
        ));

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);

        // This should fail due to expired deadline
        vm.expectRevert("ERC20Permit: expired deadline");
        vm.prank(caller);
        bank.permitDeposit(user1, depositAmount, deadline, v, r, s);
    }

        function test_RevertWhen_PermitDepositZeroAmount() public {
        uint256 depositAmount = 0;
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(user1);

        // Create the hash
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                depositAmount,
                nonce + 1,
                deadline))
        ));

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);

        // This should fail due to zero amount
        vm.expectRevert("Deposit amount must be greater than 0");
        vm.prank(caller);
        bank.permitDeposit(user1, depositAmount, deadline, v, r, s);
    }

        function test_RevertWhen_PermitDepositZeroOwner() public {
        uint256 depositAmount = 100;
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(user1);

        // Create the hash
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                depositAmount,
                nonce + 1,
                deadline))
        ));

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);

        // This should fail due to zero owner
        vm.expectRevert("Owner cannot be zero address");
        vm.prank(caller);
        bank.permitDeposit(address(0), depositAmount, deadline, v, r, s);
    }

        function test_RevertWhen_DepositInsufficientAllowance() public {
        uint256 depositAmount = 100;

        // User1 tries to deposit without approval
        vm.expectRevert("Insufficient allowance, please approve first");
        vm.prank(user1);
        bank.deposit(depositAmount);
    }

        function test_RevertWhen_DepositZeroAmount() public {
        uint256 depositAmount = 0;

        // User1 tries to deposit zero amount
        vm.expectRevert("Deposit amount must be greater than 0");
        vm.prank(user1);
        bank.deposit(depositAmount);
    }

        function test_RevertWhen_WithdrawInsufficientBalance() public {
        uint256 withdrawAmount = 100;

        // User1 tries to withdraw without depositing
        vm.expectRevert("Insufficient user balance");
        vm.prank(user1);
        bank.withdraw(withdrawAmount);
    }

        function test_RevertWhen_WithdrawZeroAmount() public {
        uint256 withdrawAmount = 0;

        // User1 tries to withdraw zero amount
        vm.expectRevert("Withdrawal amount must be greater than 0");
        vm.prank(user1);
        bank.withdraw(withdrawAmount);
    }

    function test_Events() public {
        uint256 depositAmount = 100;

        // Test Deposit event
        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);

        vm.expectEmit(true, false, false, true);
        emit TokenBank.Deposit(user1, depositAmount);
        bank.deposit(depositAmount);

        // Test Withdraw event
        vm.expectEmit(true, false, false, true);
        emit TokenBank.Withdraw(user1, depositAmount);
        bank.withdraw(depositAmount);
        vm.stopPrank();

        // Test PermitDeposit event
        uint256 permitAmount = 50;
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(user1);

        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                permitAmount,
                nonce + 1,
                deadline))
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);

        vm.expectEmit(true, false, false, true);
        emit TokenBank.PermitDeposit(user1, permitAmount);
        vm.prank(caller);
        bank.permitDeposit(user1, permitAmount, deadline, v, r, s);
    }
}
