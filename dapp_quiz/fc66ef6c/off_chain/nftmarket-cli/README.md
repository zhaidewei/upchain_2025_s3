# NFTMarket CLI 工具

这是一个用于 NFTMarket 合约 `permitBuy` 功能的 TypeScript CLI 工具。它允许管理员（admin）为买家（buyer）生成 EIP-712 签名，使买家能够通过 `permitBuy` 函数购买 NFT。

## 功能特性

- ✅ 生成 EIP-712 格式的 `permitBuy` 签名
- ✅ 验证签名有效性
- ✅ 支持自定义域名和版本
- ✅ 生成可直接使用的 `cast` 命令
- ✅ 完整的测试脚本

## 安装

```bash
npm install
```

## 使用方法

### 1. 生成签名

```bash
npx tsx src/index.ts sign \
  --private-key <ADMIN_PRIVATE_KEY> \
  --token-id <TOKEN_ID> \
  --buyer <BUYER_ADDRESS> \
  --price <PRICE> \
  --deadline <DEADLINE> \
  --chain-id <CHAIN_ID> \
  --contract-address <NFTMARKET_CONTRACT> \
  --domain-name <DOMAIN_NAME> \
  --domain-version <DOMAIN_VERSION>
```

### 2. 验证签名

```bash
npx tsx src/index.ts verify \
  --token-id <TOKEN_ID> \
  --buyer <BUYER_ADDRESS> \
  --price <PRICE> \
  --deadline <DEADLINE> \
  --chain-id <CHAIN_ID> \
  --contract-address <NFTMARKET_CONTRACT> \
  --v <V> \
  --r <R> \
  --s <S>
```

## 参数说明

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `--private-key` | string | ✅ | 管理员的私钥 |
| `--token-id` | number | ✅ | NFT 的 token ID |
| `--buyer` | address | ✅ | 买家地址 |
| `--price` | number | ✅ | 价格（wei） |
| `--deadline` | number | ✅ | 签名过期时间戳 |
| `--chain-id` | number | ✅ | 链 ID |
| `--contract-address` | address | ✅ | NFTMarket 合约地址 |
| `--domain-name` | string | ❌ | 域名（默认：DNFT） |
| `--domain-version` | string | ❌ | 版本（默认：1.0） |

## 示例

### 基本用法

```bash
# 生成签名
npx tsx src/index.ts sign \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --token-id 0 \
  --buyer 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2 \
  --price 100 \
  --deadline 1753627891 \
  --chain-id 31337 \
  --contract-address 0x610178dA211FEF7D417bC0e6FeD39F05609AD788
```

### 使用测试脚本

```bash
# 运行完整测试流程
./test-permit-buy.sh

# 运行示例脚本
./example.sh
```

## 完整流程

1. **准备阶段**：
   - 确保 NFT 已经上架到 NFTMarket
   - 买家需要 approve 足够的代币给 NFTMarket 合约

2. **生成签名**：
   - 管理员使用 CLI 工具生成 EIP-712 签名
   - 签名包含 tokenId、buyer、price、deadline 等信息

3. **执行购买**：
   - 买家使用生成的签名调用 `permitBuy` 函数
   - 合约验证签名并执行 NFT 转移

## 合约地址（Anvil 本地网络）

- **ERC20 Token**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **NFT Contract**: `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`
- **NFTMarket**: `0x610178dA211FEF7D417bC0e6FeD39F05609AD788`

## 开发

```bash
# 构建
npm run build

# 开发模式运行
npm run dev

# 生产模式运行
npm start
```

## 注意事项

1. **私钥安全**：请确保私钥的安全性，不要在公共环境中暴露
2. **deadline**：签名有过期时间，请确保在有效期内使用
3. **权限**：只有合约的 owner 才能生成有效签名
4. **余额**：买家需要有足够的代币余额和授权

## 技术细节

- 使用 EIP-712 标准进行结构化数据签名
- 支持自定义域名和版本
- 使用 ethers.js 进行签名和验证
- 支持多种网络（通过 chainId 参数）
