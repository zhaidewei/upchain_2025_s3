// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyErc20 is ERC20, Ownable {
    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= type(uint256).max, "Would exceed max supply");
        _mint(to, amount);
    }
}
