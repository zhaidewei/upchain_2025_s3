// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import "../src/erc721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployUpgradeable is Script {
    function run() external {
        vm.startBroadcast();

        // step 1: Deploy implementation logic
        Erc721Nft implementation = new Erc721Nft();

        // step 2: Encode initialize() call
        bytes memory data = abi.encodeCall(Erc721Nft.initialize, ("MyUpgradableNFT", "MUN")); // How to call a function with data? abi.encodeCall

        // step 3: Deploy proxy with logic + initializer
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
