// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;

    // Test users
    address public user1 = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address public user2 = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address public user3 = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
    address public user4 = address(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);

    // Admin address
    address public admin = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {
        vm.prank(admin);
        bank = new Bank();

        // Give all test users sufficient ETH balance
        vm.deal(user1, 100 ether);
        vm.deal(user2, 200 ether);
        vm.deal(user3, 300 ether);
        vm.deal(user4, 400 ether);
    }

    function test_Admin() public {
        assertEq(bank.admin(), admin);
    }
    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。

    function testFuzz_Deposit(uint256 x) public {
        // restrict the value to be greater than 0 and smaller than 100 ether
        vm.assume(x > 0 && x < 100 ether);

        // 检查开始前的余额
        assertEq(bank.balances(user2), 0);

        vm.prank(user2);
        bank.deposit{value: x}();

        // 检查存款是否正确记录
        assertEq(bank.balances(user2), x);
    }

    function test_Top3Depositors() public {
        //检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。

        // 测试1个用户
        vm.prank(user1);
        bank.deposit{value: 10 ether}();

        Bank.TopDepositor[3] memory topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, user1);
        assertEq(topDepositors[0].amount, 10 ether);
        assertEq(topDepositors[1].depositor, address(0));
        assertEq(topDepositors[2].depositor, address(0));

        // 测试2个用户
        vm.prank(user2);
        bank.deposit{value: 20 ether}();

        topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, user2);
        assertEq(topDepositors[0].amount, 20 ether);
        assertEq(topDepositors[1].depositor, user1);
        assertEq(topDepositors[1].amount, 10 ether);
        assertEq(topDepositors[2].depositor, address(0));

        // 测试3个用户
        vm.prank(user3);
        bank.deposit{value: 30 ether}();

        topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, user3);
        assertEq(topDepositors[0].amount, 30 ether);
        assertEq(topDepositors[1].depositor, user2);
        assertEq(topDepositors[1].amount, 20 ether);
        assertEq(topDepositors[2].depositor, user1);
        assertEq(topDepositors[2].amount, 10 ether);

        // 测试4个用户（只显示前3名）
        vm.prank(user4);
        bank.deposit{value: 5 ether}();

        topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, user3);
        assertEq(topDepositors[0].amount, 30 ether);
        assertEq(topDepositors[1].depositor, user2);
        assertEq(topDepositors[1].amount, 20 ether);
        assertEq(topDepositors[2].depositor, user1);
        assertEq(topDepositors[2].amount, 10 ether);

        // 测试同一用户多次存款
        vm.prank(user4);
        bank.deposit{value: 50 ether}();

        topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].depositor, user4);
        assertEq(topDepositors[0].amount, 55 ether); // 5 + 50
        assertEq(topDepositors[1].depositor, user3);
        assertEq(topDepositors[1].amount, 30 ether);
        assertEq(topDepositors[2].depositor, user2);
        assertEq(topDepositors[2].amount, 20 ether);
    }

    function test_OnlyAdminCanWithdraw() public {
        // First, add some funds to the contract
        vm.prank(user1);
        bank.deposit{value: 20 ether}();

        // Test that non-admin cannot withdraw
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        bank.withdraw(10 ether);

        // Test that admin can withdraw
        uint256 adminBalanceBefore = admin.balance;
        vm.prank(admin);
        bank.withdraw(10 ether);

        assertEq(address(bank).balance, 10 ether);
        assertEq(admin.balance, adminBalanceBefore + 10 ether);

        // Test that non-admin still cannot withdraw after admin withdrawal
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        bank.withdraw(5 ether);
    }
}
