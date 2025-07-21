// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/*
* @dev 简化的 ERC20 接口
*/
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

