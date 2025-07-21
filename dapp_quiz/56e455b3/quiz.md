# Quiz#1
给 Token Bank 添加前端界面：

显示当前 Token 的余额，并且可以存款(点击按钮存款)到 TokenBank

存款后显示用户存款金额，同时支持用户取款(点击按钮取款)。

提交的 github 仓库需要包含一个存款后的截图。
## [URL](https://decert.me/challenge/56e455b3-901c-415d-90c0-a20759469cf9)

### Q: 项目布局应该是怎样的？

**回答：**

项目应该采用 **Monorepo** 结构，包含两个主要部分：

```
token-bank-dapp/
├── contracts/                  # Solidity 合约项目
│   ├── src/
│   │   ├── TokenBank.sol      # 主要的存款合约
│   │   └── MyToken.sol        # ERC20 代币合约
│   ├── test/
│   │   ├── TokenBank.t.sol    # TokenBank 测试
│   │   └── MyToken.t.sol      # ERC20 测试
│   ├── script/
│   │   └── Deploy.s.sol       # 部署脚本
│   ├── foundry.toml           # Foundry 配置
│   └── README.md
├── frontend/                   # Node.js 前端项目
│   ├── src/
│   │   ├── components/
│   │   │   ├── TokenBalance.tsx    # 代币余额组件
│   │   │   ├── DepositForm.tsx     # 存款表单组件
│   │   │   ├── WithdrawForm.tsx    # 取款表单组件
│   │   │   └── UserDeposits.tsx    # 用户存款显示组件
│   │   ├── hooks/
│   │   │   ├── useTokenBank.ts     # TokenBank 合约交互 Hook
│   │   │   ├── useToken.ts         # ERC20 合约交互 Hook
│   │   │   └── useWallet.ts        # 钱包连接 Hook
│   │   ├── utils/
│   │   │   ├── contracts.ts        # 合约地址和 ABI
│   │   │   └── config.ts          # 配置文件
│   │   ├── App.tsx               # 主应用组件
│   │   └── main.tsx              # 入口文件
│   ├── package.json              # 依赖管理
│   ├── vite.config.ts           # Vite 配置
│   └── README.md
├── deployments/                # 部署记录
│   ├── localhost.json          # 本地部署地址
│   └── sepolia.json           # 测试网部署地址
└── README.md                   # 项目总体说明
```

**技术栈选择：**

1. **合约部分 (contracts/)**：
   - **Foundry**: 用于合约开发、测试、部署
   - **Solidity 0.8.25**: 合约语言
   - **OpenZeppelin**: 标准 ERC20 实现

2. **前端部分 (frontend/)**：
   - **React + TypeScript**: UI 框架
   - **Vite**: 构建工具
   - **Viem**: 以太坊交互库（替代 ethers.js）
   - **Wagmi**: React Hooks for Ethereum
   - **ConnectKit/RainbowKit**: 钱包连接组件
   - **Tailwind CSS**: 样式框架

**关键功能模块：**

1. **TokenBank.sol**：
   - `deposit(uint256 amount)`: 存款功能
   - `withdraw(uint256 amount)`: 取款功能
   - `balanceOf(address user)`: 查询用户存款
   - 事件：`Deposit`, `Withdraw`

2. **前端核心组件**：
   - **TokenBalance**: 显示用户代币余额
   - **DepositForm**: 存款表单（输入金额 + 按钮）
   - **WithdrawForm**: 取款表单（输入金额 + 按钮）
   - **UserDeposits**: 显示用户在 TokenBank 中的存款

3. **状态管理**：
   - 使用 Wagmi 的 `useContractRead` 读取余额
   - 使用 `useContractWrite` 执行存款/取款交易
   - 使用 `useWaitForTransaction` 等待交易确认

**部署流程**：
1. 使用 Foundry 部署合约到本地/测试网
2. 将合约地址和 ABI 更新到前端配置
3. 启动前端开发服务器
4. 连接 MetaMask 进行交互测试
