# NFT Market - React Frontend

这是一个基于React和Web3Modal的NFT市场前端应用，支持使用WalletConnect进行钱包连接。

## 功能特性

- 🔗 使用WalletConnect和AppKit进行钱包连接
- 💰 显示ERC20 Token余额
- 🎨 NFT铸造和上架功能
- 🛒 NFT购买功能
- 📱 响应式设计，支持移动端

## 技术栈

- **Frontend**: React 18 + TypeScript + Vite
- **Web3**: Wagmi + Viem + Web3Modal
- **UI**: Tailwind CSS + Lucide Icons
- **State**: TanStack Query

## 安装和运行

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

复制 `.env.example` 文件为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件，配置你的WalletConnect Project ID：

```env
VITE_PROJECT_ID=your_wallet_connect_project_id
```

### 3. 启动本地Anvil网络

确保你的Anvil本地区块链网络正在运行：

```bash
anvil
```

### 4. 部署合约

确保已经部署了以下合约到本地网络：
- ExtendedERC20WithData: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- ExtendedERC721: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- NFTMarket: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`

### 5. 启动开发服务器

```bash
npm run dev
```

应用将在 `http://localhost:5173` 启动。

## 使用说明

### 1. 连接钱包

- 点击右上角"连接钱包"按钮
- 选择你的钱包（MetaMask、WalletConnect等）
- 确保切换到本地Anvil网络（Chain ID: 31337）

### 2. 查看Token余额

连接钱包后，你可以在顶部看到你的ERC20 Token余额。

### 3. 上架NFT

- 切换到"上架NFT"标签
- 输入Token ID（如果NFT不存在，可以先铸造）
- 如果你是NFT拥有者，授权市场合约
- 设置价格并上架

### 4. 购买NFT

- 在"市场"标签查看已上架的NFT
- 确保你有足够的Token余额
- 授权Token支出（如果需要）
- 点击"购买"按钮

## 项目结构

```
src/
├── components/          # React组件
│   ├── Header.tsx      # 头部组件（钱包连接）
│   ├── NFTMarket.tsx   # 主市场组件
│   ├── TokenBalance.tsx # Token余额显示
│   ├── ListNFTForm.tsx # NFT上架表单
│   └── NFTList.tsx     # NFT列表和购买
├── config/             # 配置文件
│   ├── wagmi.ts        # Web3Modal和Wagmi配置
│   └── contracts.ts    # 合约地址和ABI
├── App.tsx             # 主应用组件
└── main.tsx            # 应用入口
```

## 开发说明

这个前端应用是为了完成 [DeCert Quiz](https://decert.me/challenge/a1a9aff6-1788-4254-bc47-405cc529bbd1) 而创建的，实现了：

1. ✅ 使用AppKit和WalletConnect进行钱包连接
2. ✅ NFT上架功能
3. ✅ NFT购买功能
4. ✅ 多账号切换支持
5. ✅ 响应式UI设计

## 注意事项

- 确保Anvil本地网络正在运行
- 确保合约已正确部署到指定地址
- 需要在WalletConnect官网注册获取Project ID
- 建议使用支持自定义网络的钱包（如MetaMask）

## 许可证

MIT
