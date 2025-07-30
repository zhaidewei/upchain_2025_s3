# NFTMarket 事件监听器

这是一个使用 TypeScript 和 viem 库实现的 NFTMarket 合约事件监听脚本。

## 功能

监听 NFTMarket 合约的以下事件：
- `NFTListed`: NFT上架事件
- `NFTSold`: NFT售出事件

## 前置条件

1. 确保本地 Anvil 节点正在运行 (ws://127.0.0.1:8545)
2. NFTMarket 合约已部署到地址: `0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0`

## 安装依赖

```bash
npm install
```

## 运行监听器

```bash
# 直接运行
npm start

# 开发模式 (自动重启)
npm run dev
```

## 合约地址

- NFTMarket: `0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0`
- ExtendedERC20WithData: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- ExtendedERC721: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`

## 事件格式

### NFTListed 事件
```
🏷️  NFT上架事件 (NFTListed)
   Token ID: 1
   卖家地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   价格: 100.0 Token
   区块号: 123
   交易哈希: 0x...
```

### NFTSold 事件
```
💰 NFT售出事件 (NFTSold)
   Token ID: 1
   卖家地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   买家地址: 0x70997970c51812dc3a010c7d01b50e0d17dc79c8
   成交价格: 100.0 Token
   区块号: 124
   交易哈希: 0x...
```

## 停止监听

按 `Ctrl+C` 可以优雅地停止监听器。
