// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import {MyToken} from "../src/Erc20Token.sol";

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast();
        MyToken token = new MyToken("MyToken", "MTK");
        vm.stopBroadcast();
        console.log("Token deployed at:", address(token));
    }
}
