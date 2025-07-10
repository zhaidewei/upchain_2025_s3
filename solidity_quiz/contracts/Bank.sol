// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// https://decert.me/challenge/c43324bc-0220-4e81-b533-668fa644c1c3
// Quiz#1
// 编写一个 Bank 合约，实现功能：

// 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
// 在 Bank 合约你几率每个地址的存款金额
// 编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
// 用数组记录存款金额的前 3 名用户
// 请提交完成项目代码或 github 仓库地址。

contract Bank {
    // 管理员地址
    address public admin;

    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;

    // 记录所有存款用户的地址
    address[] public depositors;

    // 前3名存款用户结构体
    struct TopDepositor {
        address depositor;
        uint256 amount;
    }

    // 事件
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed admin, uint256 amount);

    // 修饰符：仅管理员可调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // 构造函数：设置部署者为管理员
    constructor() {
        admin = msg.sender;
    }

    // 接收ETH存款的函数（payable）
    receive() external payable {
        deposit();
    }

    // 备用函数，当调用不存在的函数时触发
    fallback() external payable {
        deposit();
    }

    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // 如果是新用户，添加到存款者数组
        if (balances[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        // 更新用户余额
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // 管理员提取资金
    function withdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(admin).transfer(amount);
        emit Withdrawal(admin, amount);
    }

    // 查看合约总余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 获取前3名存款用户 - 按需计算，不存储
    function getTopDepositors() external view returns (TopDepositor[3] memory) {
        TopDepositor[3] memory topThree;

        // 如果没有存款用户，返回空数组
        if (depositors.length == 0) {
            return topThree;
        }

        // 遍历所有存款用户，找出前3名
        for (uint256 i = 0; i < depositors.length; i++) {
            address currentDepositor = depositors[i];
            uint256 currentAmount = balances[currentDepositor];

            // 检查是否能进入前3名
            for (uint256 j = 0; j < 3; j++) {
                if (topThree[j].depositor == address(0) || currentAmount > topThree[j].amount) {
                    // 向后移动较小的金额
                    for (uint256 k = 2; k > j; k--) {
                        topThree[k] = topThree[k-1];
                    }
                    // 插入当前用户
                    topThree[j] = TopDepositor(currentDepositor, currentAmount);
                    break;
                }
            }
        }

        return topThree;
    }

    // 获取存款用户总数
    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }
}
