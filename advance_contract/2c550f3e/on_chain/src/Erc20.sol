// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Erc20Impl is ERC20 {
    constructor() ERC20("DwErc20", "DWT") {
        // 给部署者分配1000个代币作为初始供应
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
