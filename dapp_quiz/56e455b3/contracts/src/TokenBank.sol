// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TokenBank {
    // 管理员地址
    address public admin;

    // 前3名存款用户结构体
    struct TopDepositor {
        address depositor;
        uint256 amount;
    }

    // 记录每个地址的存款金额
    mapping(address user => uint256 balance) public balances;

    // 记录所有存款用户的地址
    address[] public depositors;

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
    }

    // 用户提取自己的存款
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient user balance");
        require(address(this).balance >= amount, "Insufficient contract balance");

        // 更新用户余额
        balances[msg.sender] -= amount;

        // 发送ETH给用户
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 管理员提取资金（管理员专用）
    function adminWithdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        (bool success, ) = payable(admin).call{value: amount}("");
        require(success, "Transfer failed");
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
