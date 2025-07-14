# TokenBank 智能合约系统

## 概述

TokenBank 是一个基于以太坊的智能合约系统，允许用户存入和提取 BaseERC20 代币。该系统提供了安全的代币存储和管理功能。

## 架构设计

### 系统组件

1. **BaseERC20 合约**: 标准的 ERC20 代币合约
2. **TokenBank 合约**: 代币银行合约，管理代币的存储和提取
3. **IERC20 接口**: ERC20 标准接口，确保与任何符合标准的代币兼容

### 合约关系图

```
┌─────────────────┐      ┌─────────────────┐
│   BaseERC20     │◄────►│   TokenBank     │
│   (Token)       │      │   (Bank)        │
└─────────────────┘      └─────────────────┘
         │                         │
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│   IERC20        │      │   用户存款       │
│   (Interface)   │      │   记录系统       │
└─────────────────┘      └─────────────────┘
```

## 核心功能

### 1. 存款功能 (deposit)

- **功能**: 用户可以将自己的 BaseERC20 代币存入 TokenBank
- **前置条件**: 用户必须先调用 `approve()` 授权 TokenBank 使用代币
- **记录**: 系统会记录每个用户的存款数量

### 2. 提取功能 (withdraw)

- **功能**: 用户可以提取之前存入的代币
- **限制**: 只能提取不超过自己存款余额的代币
- **安全性**: 使用 `require` 确保操作安全

### 3. 查询功能

- **用户余额**: 查看用户在 TokenBank 中的存款余额
- **合约总余额**: 查看 TokenBank 持有的总代币数量
- **存款用户管理**: 跟踪所有存款用户

## 智能合约详细设计

### 状态变量

```solidity
// 代币合约引用
IERC20 public immutable token;

// 用户存款余额映射
mapping(address => uint256) public balances;

// 存款用户地址数组
address[] public depositors;

// 用户存款状态映射
mapping(address => bool) public hasDeposited;
```

### 核心函数

#### deposit(uint256 amount)
```solidity
function deposit(uint256 amount) external {
    require(amount > 0, "Deposit amount must be greater than 0");
    require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");

    // 执行代币转移
    require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

    // 更新用户余额
    balances[msg.sender] += amount;

    // 记录新用户
    if (!hasDeposited[msg.sender]) {
        depositors.push(msg.sender);
        hasDeposited[msg.sender] = true;
    }

    emit Deposit(msg.sender, amount);
}
```

#### withdraw(uint256 amount)
```solidity
function withdraw(uint256 amount) external {
    require(amount > 0, "Withdraw amount must be greater than 0");
    require(balances[msg.sender] >= amount, "Insufficient balance in TokenBank");

    // 更新用户余额
    balances[msg.sender] -= amount;

    // 执行代币转移
    require(token.transfer(msg.sender, amount), "Token transfer failed");

    emit Withdraw(msg.sender, amount);
}
```

## 使用指南

### 1. 部署流程

```javascript
// 1. 部署 BaseERC20 代币合约
const BaseERC20 = await ethers.getContractFactory("BaseERC20");
const token = await BaseERC20.deploy("BaseERC20", "BERC20", 18, totalSupply);

// 2. 部署 TokenBank 合约
const TokenBank = await ethers.getContractFactory("TokenBank");
const tokenBank = await TokenBank.deploy(token.address);
```

### 2. 用户操作流程

#### 存款操作
```javascript
// 步骤1: 授权 TokenBank 使用代币
await token.connect(user).approve(tokenBank.address, amount);

// 步骤2: 存入代币
await tokenBank.connect(user).deposit(amount);
```

#### 提取操作
```javascript
// 提取指定数量代币
await tokenBank.connect(user).withdraw(amount);

// 或者提取全部余额
await tokenBank.connect(user).withdrawAll();
```

### 3. 查询操作

```javascript
// 查看用户余额
const balance = await tokenBank.balanceOf(userAddress);

// 查看合约总余额
const totalBalance = await tokenBank.totalBalance();

// 查看存款用户数量
const depositorsCount = await tokenBank.getDepositorsCount();
```

## 安全特性

### 1. 代币转移安全
- 使用 `require` 确保 `transferFrom` 和 `transfer` 操作成功
- 检查用户代币余额是否足够

### 2. 存款/提取验证
- 验证存款和提取金额必须大于 0
- 验证用户在 TokenBank 中的余额足够提取

### 3. 状态管理
- 准确跟踪每个用户的存款余额
- 防止重复添加用户到 depositors 数组

### 4. 事件记录
- 所有存款和提取操作都会触发事件
- 便于链外应用监听和记录

## 测试说明

### 运行测试

```bash
cd solidity_quiz/eeb9f7d8
node test_tokenBank.js
```

### 测试覆盖

测试脚本包含以下测试用例：

1. **部署测试**: 验证合约部署成功
2. **存款测试**: 测试正常存款流程
3. **提取测试**: 测试部分提取和全部提取
4. **错误处理**: 测试各种错误情况
5. **状态查询**: 测试余额和用户查询功能

### 错误情况测试

- ❌ 存款 0 个代币
- ❌ 提取超过余额
- ❌ 未授权存款
- ❌ 无效地址操作

## 工作流程图

```
用户操作流程:
┌─────────────────┐
│   用户有代币     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ approve(TokenBank,│
│     amount)     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   deposit(amount)│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ 代币存入TokenBank│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│  withdraw(amount)│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ 代币返回用户钱包 │
└─────────────────┘
```

## 优势特点

1. **安全性**: 多重验证确保操作安全
2. **灵活性**: 支持部分提取和全部提取
3. **可扩展性**: 接口设计支持其他 ERC20 代币
4. **透明性**: 所有操作都有事件记录
5. **效率**: 优化的数据结构减少 gas 消耗

## 常见问题

### Q1: 为什么需要先调用 approve？
**A**: 这是 ERC20 标准的安全机制，用户必须明确授权合约才能转移代币。

### Q2: 存款后代币去哪了？
**A**: 代币被转移到 TokenBank 合约地址，用户可以通过 withdraw 取回。

### Q3: 可以存入其他代币吗？
**A**: 当前系统专为 BaseERC20 设计，但可以通过修改构造函数支持其他 ERC20 代币。

### Q4: 如何检查存款是否成功？
**A**: 可以通过 `balanceOf()` 函数查看用户在 TokenBank 中的余额。

---

**注意**: 该合约仅用于学习和测试目的，在生产环境中使用前请进行充分的安全审计。
