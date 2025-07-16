// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*

# 0. 题目
https://decert.me/challenge/063c14be-d3e6-41e0-a243-54e35b1dde58
在 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
要求存款金额 >0.001 ether（用modifier权限控制）
BigBank 合约支持转移管理员
编写一个 Admin 合约，
Admin 合约有自己的 Owner
同时有一个取款函数 adminWithdraw(IBank bank),
adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后

Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。


# 1 contract设计

需要设计的合约：
1. IBank 接口 - 定义银行合约的标准接口
2. Bank 合约 - 实现 IBank 接口的基础银行功能
3. BigBank 合约 - 继承 Bank，增加存款金额限制(>0.001 ether)和管理员转移功能
4. Admin 合约 - 管理合约，有自己的 Owner，可以从 BigBank 提取资金

合约关系：
- IBank (interface) ← Bank (implements) ← BigBank (inherits)
- Admin (interacts with) → BigBank (through IBank interface)

工作流程：
1. 部署 BigBank 合约
2. 部署 Admin 合约
3. 将 BigBank 的管理员权限转移给 Admin 合约地址
4. 用户向 BigBank 存款 (金额必须 >0.001 ether)
5. Admin 合约的 Owner 调用 adminWithdraw() 从 BigBank 提取资金到 Admin 合约

# 2. 数据设计 (Data Design)

1. IBank 接口:
   - 无状态变量 (接口只定义函数签名)

2. Bank 合约:
   存储数据:
   - address admin: 管理员地址
   - mapping(address => uint256) balances: 用户余额映射
   - address[] depositors: 存款用户地址数组

   临时数据:
   - struct TopDepositor: 前3名存款用户结构体 (memory)

3. BigBank 合约:
   继承 Bank 的所有数据，额外添加:
   - uint256 constant MIN_DEPOSIT = 0.001 ether: 最小存款金额常量

   新增功能:
   - transferAdmin() 函数用于转移管理员权限

4. Admin 合约:
   存储数据:
   - address owner: Admin合约的拥有者
   - mapping(address => bool) authorizedBanks: 授权的银行合约 (可选)

   临时数据:
   - function参数和局部变量

数据存储成本分析:
- 链上存储: admin, balances, depositors, owner
- 内存计算: TopDepositor排名, 函数参数
- 常量: MIN_DEPOSIT (编译时确定，不消耗存储slot)

# 3. 函数设计 (Function Design)

1. IBank 接口:
   - function deposit() external payable;
   - function withdraw(uint256 amount) external;
   - function getContractBalance() external view returns (uint256);

2. Bank 合约:
   基础函数:
   - constructor(): 设置部署者为admin
   - receive() external payable: 接收ETH并调用deposit()
   - fallback() external payable: 备用函数
   - deposit() public payable: 存款功能
   - withdraw(uint256 amount) external onlyAdmin: 管理员提取资金
   - getContractBalance() external view returns (uint256): 查看合约余额

   查询函数:
   - getTopDepositors() external view returns (TopDepositor[3] memory): 获取前3名存款用户
   - getDepositorsCount() external view returns (uint256): 获取存款用户总数

   修饰符:
   - modifier onlyAdmin(): 仅管理员可调用

3. BigBank 合约:
   继承Bank所有函数，额外添加:
   - modifier minDeposit(): 存款金额必须>0.001 ether
   - function transferAdmin(address newAdmin) external onlyAdmin: 转移管理员权限
   - deposit() public payable override: 重写存款函数，添加金额限制

   常量:
   - uint256 constant MIN_DEPOSIT = 0.001 ether;

4. Admin 合约:
   管理函数:
   - constructor(): 设置部署者为owner
   - adminWithdraw(IBank bank) external onlyOwner: 从银行合约提取资金
   - receive() external payable: 接收转入的ETH

   查询函数:
   - getBalance() external view returns (uint256): 查看Admin合约余额

   修饰符:
   - modifier onlyOwner(): 仅owner可调用

   状态变量:
   - address public owner;

函数调用流程:
1. 用户调用 BigBank.deposit() (金额>0.001 ether)
2. BigBank.admin 权限转移给 Admin 合约
3. Admin.owner 调用 adminWithdraw(BigBank合约地址)
4. adminWithdraw 内部调用 IBank.withdraw() 提取资金到 Admin 合约
*/

// =============================================================================
// 1. IBank 接口
// =============================================================================

/**
 * @title IBank
 * @dev 银行合约的标准接口
 */
interface IBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getContractBalance() external view returns (uint256);
}

// =============================================================================
// 2. Bank 合约
// =============================================================================

/**
 * @title Bank
 * @dev 实现IBank接口的基础银行合约
 */
contract Bank is IBank {
    // 管理员地址
    address public admin;

    // 前3名存款用户结构体
    struct TopDepositor {
        address depositor;
        uint256 amount;
    }

    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;

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
    function deposit() public payable virtual override {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // 如果是新用户，添加到存款者数组
        if (balances[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        // 更新用户余额
        balances[msg.sender] += msg.value;
    }

    // 管理员提取资金
    function withdraw(uint256 amount) external virtual override onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(admin).transfer(amount);
    }

    // 查看合约总余额
    function getContractBalance() external view virtual override returns (uint256) {
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

// =============================================================================
// 3. BigBank 合约
// =============================================================================

/**
 * @title BigBank
 * @dev 继承Bank合约，添加存款限制和管理员转移功能
 */
contract BigBank is Bank {
    // 最小存款金额常量
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    // 修饰符：存款金额必须大于最小值
    modifier minDeposit() {
        require(msg.value > MIN_DEPOSIT, "Deposit amount must be at least 0.001 ether");
        _;
    }

    // 重写存款函数，添加金额限制
    function deposit() public payable override minDeposit {
        // 调用父合约的deposit函数
        super.deposit();
    }

    // 转移管理员权限
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        require(newAdmin != admin, "New admin cannot be the same as current admin");

        admin = newAdmin;
    }

    // 重写withdraw函数，确保转账到当前admin
    function withdraw(uint256 amount) external override onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        // 转账到当前admin地址
        payable(admin).transfer(amount);
    }
}

// =============================================================================
// 4. Admin 合约
// =============================================================================

/**
 * @title Admin
 * @dev 管理合约，通过IBank接口与银行合约交互
 */
contract Admin {
    // Admin合约的拥有者
    address public owner;

    // 修饰符：仅owner可调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 构造函数：设置部署者为owner
    constructor() {
        owner = msg.sender;
    }

    // 接收ETH的函数
    receive() external payable {
        // 允许接收ETH
    }

    // 从银行合约提取资金
    function adminWithdraw(IBank bank) external onlyOwner {
        require(address(bank) != address(0), "Bank address cannot be zero");

        // 获取银行合约的余额
        uint256 bankBalance = bank.getContractBalance();
        require(bankBalance > 0, "Bank has no funds to withdraw");

        // 通过IBank接口调用withdraw方法
        bank.withdraw(bankBalance);
    }

    // 部分提取资金
    function adminWithdrawPartial(IBank bank, uint256 amount) external onlyOwner {
        require(address(bank) != address(0), "Bank address cannot be zero");
        require(amount > 0, "Amount must be greater than 0");

        // 获取银行合约的余额
        uint256 bankBalance = bank.getContractBalance();
        require(bankBalance >= amount, "Bank has insufficient funds");

        // 通过IBank接口调用withdraw方法
        bank.withdraw(amount);
    }

    // 查看Admin合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 转移owner权限
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner cannot be the same as current owner");

        owner = newOwner;
    }

    // 从Admin合约提取资金到owner
    function withdrawFromAdmin(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");

        payable(owner).transfer(amount);
    }
}
