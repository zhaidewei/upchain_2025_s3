// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {MyErc20} from "../src/MyErc20.sol";

contract MyErc20Test is Test {
    MyErc20 public token;

    // Test accounts
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.startPrank(deployer);
        token = new MyErc20("TestToken", "TTK");
        vm.stopPrank();
    }

    function test_BasicERC20Functionality() public view {
        // Test basic token properties
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TTK");
        assertEq(token.decimals(), 18);

        // Test initial supply
        assertEq(token.totalSupply(), 1_000_000_000 ether);
        assertEq(token.balanceOf(deployer), 1_000_000_000 ether);
    }

    function test_Transfer() public {
        uint256 transferAmount = 1000 ether;

        // Transfer tokens from deployer to user1
        vm.prank(deployer);
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(deployer), 1_000_000_000 ether - transferAmount);
    }

    function test_ApproveAndTransferFrom() public {
        uint256 approveAmount = 500 ether;
        uint256 transferAmount = 200 ether;

        // Deployer approves user1 to spend tokens
        vm.prank(deployer);
        token.approve(user1, approveAmount);

        assertEq(token.allowance(deployer, user1), approveAmount);

        // User1 transfers tokens from deployer to user2
        vm.prank(user1);
        token.transferFrom(deployer, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(deployer), 1_000_000_000 ether - transferAmount);
        assertEq(token.allowance(deployer, user1), approveAmount - transferAmount);
    }

    function test_RevertWhen_InsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 1000 ether);
    }

    function test_RevertWhen_InsufficientAllowance() public {
        vm.prank(deployer);
        token.approve(user1, 100 ether);

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(deployer, user2, 200 ether);
    }
}
