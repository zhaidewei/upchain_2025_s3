// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Quiz#1
扩展 ERC20 合约 ，添加一个有hook功能的转账函数，如函数名为：transferWithCallback，
在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。

继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。

（备注：TokenBankV2 需要实现 tokensReceived 来实现存款记录工作）

请贴出代码库链接。
*/

/* 设计问题解答
1. 继承 TokenBank 编写 TokenBankV2：
   - 使用 import 导入 TokenBank 合约
   - 使用 is 关键字继承 TokenBank
   - 这样可以继承所有 public 和 internal 函数及状态变量

2. 调用目标地址的方法：
   - 推荐使用 Interface + 类型转换
   - 避免使用底层 call 方法，因为类型不安全
   - 使用 address.code.length > 0 检查是否为合约地址
*/

import { BaseERC20 } from "https://github.com/zhaidewei/upchain_2025_s3/blob/main/solidity_quiz/aa45f136/Q1_BaseERC20.sol";
import { TokenBank } from "https://github.com/zhaidewei/upchain_2025_s3/blob/main/solidity_quiz/eeb9f7d8/Q1_tokenBank.sol";

// =============================================================================
// 1. 定义接口
// =============================================================================

/**
 * @dev 代币接收者接口
 * 实现此接口的合约可以接收带有回调的代币转账
 */
interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external;
}

// =============================================================================
// 2. 扩展的 ERC20 合约
// =============================================================================

/**
 * @title ExtendedERC20
 * @dev 扩展 BaseERC20，添加带回调功能的转账函数
 */
contract ExtendedERC20 is BaseERC20 {

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) BaseERC20(name, symbol, decimals, totalSupply) {}

    // 事件：带回调的转账, 写入到日志里
    event TransferWithCallback(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 带回调功能的转账函数
     * @param to 目标地址
     * @param amount 转账金额
     * @return success 转账是否成功
     */
    function transferWithCallback(address to, uint256 amount) external returns (bool success) {
        // 执行标准转账
        require(transfer(to, amount), "Transfer failed");

        bool callbackExecuted = false;

        // 检查目标地址是否是合约（合约地址的代码长度 > 0）
        // 回调失败强制回滚， 不执行转账
        if (to.code.length > 0) {
            ITokenReceiver(to).tokensReceived(msg.sender, amount);
            callbackExecuted = true;
            emit TransferWithCallback(msg.sender, to, amount);
        }
        // 如果目标地址是EOA，则不允许使用此方法， 直接回滚
        else {
            revert("Cannot transfer to EOA");
        }

        return callbackExecuted;
    }

}

// =============================================================================
// 3. TokenBankV2 合约（继承 TokenBank）
// =============================================================================

/**
 * @title TokenBankV2
 * @dev 继承 TokenBank，支持扩展的 ERC20 Token 存入
 * 实现 tokensReceived 接口，支持直接通过 transferWithCallback 存入
 */

contract TokenBankV2 is TokenBank, ITokenReceiver {

    constructor(address _token) TokenBank(_token) {
        require(_token != address(0), "Token address cannot be zero");
    }

    /**
     * @dev 实现 ITokenReceiver 接口
     * 当用户调用 transferWithCallback 时会触发此函数
     * @param from 转账发送者
     * @param amount 转账金额
     */
    function tokensReceived(address from, uint256 amount) external override {
        // 只接受来自指定 ExtendedERC20 合约的调用
        require(msg.sender == address(token), "Only accept calls from ExtendedERC20");

        // 代币已经通过 transferWithCallback 转移到了合约
        // 更新用户余额
        balances[from] += amount;

        // 如果是新用户，添加到存款者数组
        if (!hasDeposited[from]) {
            depositors.push(from);
            hasDeposited[from] = true;
        }

        // 触发事件
        emit Deposit(from, amount);
    }
}
