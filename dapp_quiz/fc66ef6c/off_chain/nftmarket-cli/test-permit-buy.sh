#!/bin/bash

# 完整的 permitBuy 测试流程
# 这个脚本演示从生成签名到执行 permitBuy 的完整过程

set -e

echo "=== NFTMarket permitBuy 完整测试流程 ==="
echo ""

# 设置环境变量
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # anvil-tester
export BUYER_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"  # anvil-tester2
export BUYER_ADDRESS="0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2"
export NFTMARKET_CONTRACT="0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
export ERC20_CONTRACT="0x5FbDB2315678afecb367f032d93F642f64180aa3"
export NFT_CONTRACT="0x8A791620dd6260079BF849Dc5567aDC3F2FdC318"
export CHAIN_ID="31337"  # Anvil local network
export TOKEN_ID="0"
export PRICE="100"
export DEADLINE=$(($(date +%s) + 3600))  # 1 hour from now

echo "配置信息："
echo "  Admin Private Key: $ADMIN_PRIVATE_KEY"
echo "  Buyer Private Key: $BUYER_PRIVATE_KEY"
echo "  Buyer Address: $BUYER_ADDRESS"
echo "  NFTMarket Contract: $NFTMARKET_CONTRACT"
echo "  ERC20 Contract: $ERC20_CONTRACT"
echo "  NFT Contract: $NFT_CONTRACT"
echo "  Chain ID: $CHAIN_ID"
echo "  Token ID: $TOKEN_ID"
echo "  Price: $PRICE"
echo "  Deadline: $DEADLINE ($(date -d @$DEADLINE))"
echo ""

# 步骤 1: 检查初始状态
echo "=== 步骤 1: 检查初始状态 ==="
echo "NFT 所有者:"
cast call $NFT_CONTRACT "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url http://localhost:8545

echo "买家 ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $BUYER_ADDRESS --rpc-url http://localhost:8545

echo "NFTMarket 合约的 ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $NFTMARKET_CONTRACT --rpc-url http://localhost:8545
echo ""

# 步骤 2: 买家 approve 代币给 NFTMarket
echo "=== 步骤 2: 买家 approve 代币给 NFTMarket ==="
cast send $ERC20_CONTRACT "approve(address,uint256)" $NFTMARKET_CONTRACT $PRICE \
  --private-key $BUYER_PRIVATE_KEY \
  --rpc-url http://localhost:8545

echo "买家对 NFTMarket 的授权:"
cast call $ERC20_CONTRACT "allowance(address,address)(uint256)" $BUYER_ADDRESS $NFTMARKET_CONTRACT --rpc-url http://localhost:8545
echo ""

# 步骤 3: 生成 permitBuy 签名
echo "=== 步骤 3: 生成 permitBuy 签名 ==="
SIGNATURE_OUTPUT=$(npx tsx src/index.ts sign \
  --private-key $ADMIN_PRIVATE_KEY \
  --token-id $TOKEN_ID \
  --buyer $BUYER_ADDRESS \
  --price $PRICE \
  --deadline $DEADLINE \
  --chain-id $CHAIN_ID \
  --contract-address $NFTMARKET_CONTRACT \
  --domain-name DNFT \
  --domain-version 1.0)

echo "$SIGNATURE_OUTPUT"
echo ""

# 提取签名参数
V=$(echo "$SIGNATURE_OUTPUT" | grep "v:" | awk '{print $2}')
R=$(echo "$SIGNATURE_OUTPUT" | grep "r:" | awk '{print $2}')
S=$(echo "$SIGNATURE_OUTPUT" | grep "s:" | awk '{print $2}')

echo "提取的签名参数："
echo "  v: $V"
echo "  r: $R"
echo "  s: $S"
echo ""

# 步骤 4: 执行 permitBuy
echo "=== 步骤 4: 执行 permitBuy ==="
cast send $NFTMARKET_CONTRACT "permitBuy(uint256,uint256,uint256,uint8,bytes32,bytes32)" \
  $TOKEN_ID $PRICE $DEADLINE $V $R $S \
  --private-key $BUYER_PRIVATE_KEY \
  --rpc-url http://localhost:8545

echo ""

# 步骤 5: 检查最终状态
echo "=== 步骤 5: 检查最终状态 ==="
echo "NFT 新所有者:"
cast call $NFT_CONTRACT "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url http://localhost:8545

echo "买家 ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $BUYER_ADDRESS --rpc-url http://localhost:8545

echo "卖家 ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" 0xDFa97bfe5d2b2E8169b194eAA78Fbb793346B174 --rpc-url http://localhost:8545

echo "NFTMarket 合约的 ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $NFTMARKET_CONTRACT --rpc-url http://localhost:8545

echo "NFT 是否仍在市场上架:"
cast call $NFTMARKET_CONTRACT "getListing(uint256)(address,uint256,bool)" $TOKEN_ID --rpc-url http://localhost:8545
echo ""

echo "=== 测试完成 ==="
