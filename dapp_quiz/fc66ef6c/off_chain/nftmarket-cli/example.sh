#!/bin/bash

# NFTMarket CLI 工具使用示例
# 这个脚本演示如何使用 CLI 工具为 permitBuy 生成签名

# 设置环境变量
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # anvil-tester
export BUYER_ADDRESS="0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2"
export NFTMARKET_CONTRACT="0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
export CHAIN_ID="31337"  # Anvil local network
export TOKEN_ID="0"
export PRICE="100"
export DEADLINE=$(($(date +%s) + 3600))  # 1 hour from now

echo "=== NFTMarket CLI 工具示例 ==="
echo "Admin Private Key: $ADMIN_PRIVATE_KEY"
echo "Buyer Address: $BUYER_ADDRESS"
echo "NFTMarket Contract: $NFTMARKET_CONTRACT"
echo "Chain ID: $CHAIN_ID"
echo "Token ID: $TOKEN_ID"
echo "Price: $PRICE"
echo "Deadline: $DEADLINE ($(date -d @$DEADLINE))"
echo ""

# 生成签名
echo "=== 生成 permitBuy 签名 ==="
npm run dev sign \
  --private-key $ADMIN_PRIVATE_KEY \
  --token-id $TOKEN_ID \
  --buyer $BUYER_ADDRESS \
  --price $PRICE \
  --deadline $DEADLINE \
  --chain-id $CHAIN_ID \
  --contract-address $NFTMARKET_CONTRACT \
  --domain-name "DNFT" \
  --domain-version "1.0"

echo ""
echo "=== 使用说明 ==="
echo "1. 上面的命令会生成一个 EIP712 签名"
echo "2. 复制生成的 cast 命令"
echo "3. 将 <BUYER_PRIVATE_KEY> 替换为买家的私钥"
echo "4. 执行 cast 命令来调用 permitBuy 函数"
echo ""
echo "注意：买家需要先 approve 足够的代币给 NFTMarket 合约"
