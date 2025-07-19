
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BaseERC20 } from "./BaseERC20.sol";
import { ITokenReceiverWithData } from "./Interfaces.sol";

/**
 * @title ExtendedERC20WithData
 * @dev 扩展 ExtendedERC20，添加支持数据参数的转账函数
 */
contract ExtendedERC20WithData is BaseERC20 {

    constructor() BaseERC20("ExtendedToken", "EXT", 18, 10**7 * 10**18) {}

    // 事件：带数据的回调转账
    event TransferWithCallbackAndData(address indexed from, address indexed to, uint256 value, bytes data);

    /**
     * @dev 带回调和数据功能的转账函数
     * @param to 目标地址, 在本例子里，是NFTMarket合约地址
     * @param amount 转账金额
     * @param data 附加数据， 在本例里，是TokenID，uint256
     * @return success 转账是否成功
     */
    function transferWithCallback(address to, uint256 amount, bytes calldata data) external returns (bool success) {
        // 执行标准转账
        require(transfer(to, amount), "Transfer failed");

        bool callbackExecuted = false;

        // 检查目标地址是否是合约（合约地址的代码长度 > 0）
        if (to.code.length > 0) {
            // 这个函数失败会自动回滚， 所以不需要再检查返回值
            ITokenReceiverWithData(to).tokensReceived(msg.sender, amount, data);
            //在本例子里，这个callback函数要实现从NFT（ERC721）中完成交易对象（Token ID）的转移
            callbackExecuted = true;
            emit TransferWithCallbackAndData(msg.sender, to, amount, data);
        }
        // 如果目标地址是EOA，则不允许使用此方法
        else {
            revert("Cannot transfer to EOA");
        }

        return callbackExecuted;
    }
}
