# BigBank 系统使用指南

## 🚀 快速开始

### 1. 安装依赖
```bash
cd solidity_quiz
npm install
```

### 2. 编译合约
```bash
npm run compile
```

### 3. 运行测试
```bash
# 运行所有测试
npm test

# 只运行BigBank系统测试
npm run test:bigbank

# 运行测试并查看gas使用情况
npm run test:gas

# 详细输出
npm run test:verbose
```

### 4. 部署和演示
```bash
# 运行完整演示 (包括部署和测试流程)
npm run demo
```

## 📋 系统架构

### 合约结构
- **IBank**: 银行接口
- **Bank**: 基础银行合约
- **BigBank**: 扩展银行合约 (继承Bank)
- **Admin**: 管理合约

### 主要功能
- ✅ 存款限制 (最小0.001 ETH)
- ✅ 管理员权限转移
- ✅ 前3名存款用户排行
- ✅ 通过接口的资金提取
- ✅ 多层权限控制

## 🔧 使用示例

### 部署合约
```javascript
// 部署BigBank
const BigBank = await ethers.getContractFactory("BigBank");
const bigBank = await BigBank.deploy();

// 部署Admin
const Admin = await ethers.getContractFactory("Admin");
const admin = await Admin.deploy();

// 转移权限
await bigBank.transferAdmin(admin.address);
```

### 用户存款
```javascript
// 存款 (最小0.001 ETH)
await bigBank.connect(user).deposit({
    value: ethers.utils.parseEther("0.005")
});

// 或通过直接转账
await user.sendTransaction({
    to: bigBank.address,
    value: ethers.utils.parseEther("0.005")
});
```

### 管理员提取
```javascript
// Admin合约提取BigBank资金
await admin.adminWithdraw(bigBank.address);

// 部分提取
await admin.adminWithdrawPartial(bigBank.address, amount);
```

### 查询功能
```javascript
// 查看合约余额
const balance = await bigBank.getContractBalance();

// 查看前3名存款用户
const topDepositors = await bigBank.getTopDepositors();

// 查看存款用户数量
const count = await bigBank.getDepositorsCount();
```

## 📊 测试覆盖

测试套件包含50+个测试用例，覆盖：
- 合约部署
- 存款功能 (包括最小金额限制)
- 管理员权限转移
- 前3名存款用户排序
- Admin合约功能
- 完整工作流程
- 错误处理

## 🛡️ 安全特性

- **权限控制**: 多层权限验证
- **输入验证**: 防止零金额和无效地址
- **接口隔离**: 通过IBank接口确保解耦
- **存款限制**: 防止垃圾存款攻击

## 🔍 Gas优化

- 前3名排行按需计算 (不占用存储)
- 使用常量定义最小存款金额
- 高效的数据结构设计

## 📈 可扩展性

- 模块化设计，易于扩展
- 接口标准化，便于集成
- 事件日志记录 (可选)

## 🐛 问题排查

### 常见错误
1. **"Deposit amount must be at least 0.001 ether"**
   - 确保存款金额 >= 0.001 ETH

2. **"Only admin can call this function"**
   - 确保使用正确的管理员账户

3. **"Only owner can call this function"**
   - 确保使用Admin合约的owner账户

### 调试技巧
```bash
# 查看详细错误信息
npm run test:verbose

# 检查gas使用情况
npm run test:gas

# 重新编译
npm run clean && npm run compile
```

## 📝 开发建议

1. **测试先行**: 在修改合约前先编写测试
2. **Gas优化**: 关注存储操作的gas消耗
3. **安全审计**: 重点检查权限控制逻辑
4. **接口设计**: 保持接口的向后兼容性

## 🚀 进一步扩展

可以考虑的扩展功能：
- 添加存款利息计算
- 实现分级管理员权限
- 添加存款锁定期
- 支持多种代币存款
- 实现DAO治理功能

---

💡 **提示**: 运行 `npm run demo` 查看完整的系统演示！
