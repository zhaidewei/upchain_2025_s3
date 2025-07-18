// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// forge create --rpc-url local --account anvil-tester --password '' src/Bank.sol:Bank --broadcast

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Bank} from "../src/Bank.sol";

contract BankScript is Script {
    Bank public bank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        bank = new Bank();

        vm.stopBroadcast();
        console.log("Bank deployed at:", address(bank));
    }
}
