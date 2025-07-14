// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Quiz#1
编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。
(自己的 Token 是 BaseERC20里的)
TokenBank 有两个方法：

deposit() : 需要记录每个地址的存入数量；
withdraw（）: 用户可以提取自己的之前存入的 token。
在回答框内输入你的代码或者 github 链接。

## 设计：

TokenBank 合约设计用于管理 BaseERC20 代币的存储和提取，主要功能：
1. 用户可以存入指定数量的 BaseERC20 代币
2. 用户可以提取之前存入的代币
3. 记录每个用户的存款余额
4. 支持安全的代币转移操作

工作流程：
1. 用户首先调用 BaseERC20.approve(tokenBank.address, amount) 授权
2. 用户调用 TokenBank.deposit(amount) 存入代币
3. 用户可以调用 TokenBank.withdraw(amount) 提取代币
*/

// 导入BaseERC20合约接口
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenBank {
    // BaseERC20代币合约地址
    IERC20 public immutable token;

    // 记录每个用户在TokenBank中的存款余额
    mapping(address => uint256) public balances;

    // 记录所有存款用户的地址
    address[] public depositors;

    // 记录用户是否已经存过款(避免重复添加到depositors数组)
    mapping(address => bool) public hasDeposited;

    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // 构造函数，设置代币合约地址
    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
    }

    /**
     * @dev 存款函数
     * @param amount 存入的代币数量
     *
     * 使用说明：
     * 1. 用户首先需要调用 BaseERC20.approve(tokenBank.address, amount) 授权
     * 2. 然后调用此函数存入代币
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");

        // 检查用户是否有足够的代币余额
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // 从用户地址转移代币到TokenBank合约
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        // 更新用户在TokenBank中的余额
        balances[msg.sender] += amount;

        // 如果是新用户，添加到depositors数组
        if (!hasDeposited[msg.sender]) {
            depositors.push(msg.sender);
            hasDeposited[msg.sender] = true;
        }

        // 触发存款事件
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev 提取函数
     * @param amount 提取的代币数量
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance in TokenBank");

        // 更新用户余额
        balances[msg.sender] -= amount;

        // 从TokenBank合约转移代币到用户地址
        require(
            token.transfer(msg.sender, amount),
            "Token transfer failed"
        );

        // 触发提取事件
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev 查看用户在TokenBank中的余额
     * @param user 用户地址
     * @return 用户的存款余额
     */
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev 查看TokenBank合约的总代币余额
     * @return 合约持有的总代币数量
     */
    function totalBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev 获取存款用户总数
     * @return 存款用户数量
     */
    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }
}
