// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev 这个合约将被部署到 EOA 地址上，通过 EIP-7702 机制执行
 * 它提供 multicall 功能来批量调用其他合约
 */
contract Delegator {
    /**
     * @dev 批量执行多个合约调用
     * @param targets 目标合约地址数组
     * @param data 对应的调用数据数组
     */
    function multicall(address[] calldata targets, bytes[] calldata data) external returns (bytes[] memory results) {
        require(targets.length == data.length, "Length mismatch");

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // 使用 call 在目标合约的上下文中执行调用
            // msg.sender 是当前合约（EOA）
            (bool success, bytes memory result) = targets[i].call(data[i]);
            require(success, "Call failed");
            results[i] = result;
        }
        return results;
    }
}
