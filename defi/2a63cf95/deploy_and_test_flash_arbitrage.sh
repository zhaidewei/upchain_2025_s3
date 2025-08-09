#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

# 🚀 闪电套利Quiz演示 - 专注于核心原理
echo "🚀 Flash Arbitrage Quiz Demo - Core Principles..."

# Set up environment
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545
export USER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
export USER1_ADDRESS=$(cast wallet address --private-key $USER1_KEY)
export USER2_ADDRESS=$(cast wallet address --private-key $USER2_KEY)
export ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)

# Uniswap V2 addresses on mainnet (using fork)
export ROUTER_ADDRESS=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
export FACTORY_V2_ADDRESS=0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

echo "👥 Quiz Participants:"
echo "ADMIN: $ADMIN_ADDRESS (creates liquidity)"
echo "USER1: $USER1_ADDRESS (creates price imbalance)"
echo "USER2: $USER2_ADDRESS (executes flash arbitrage)"
echo ""

get_deployed_address() {
    awk '/Deployed to:/ {print $3}'
}

# Step 1: 部署MT1和MT2代币
echo "📦 Step 1: Deploying MT1 and MT2 tokens..."

MT1_ADDRESS=$(forge create --rpc-url $RPC_URL src/MyErc20.sol:MyErc20 \
    --private-key $ADMIN_PRIVATE_KEY --broadcast \
    --constructor-args "MyToken1" "MT1" | get_deployed_address)

MT2_ADDRESS=$(forge create --rpc-url $RPC_URL src/MyErc20.sol:MyErc20 \
    --private-key $ADMIN_PRIVATE_KEY --broadcast \
    --constructor-args "MyToken2" "MT2" | get_deployed_address)

echo "✅ Tokens deployed:"
echo "MT1: $MT1_ADDRESS"
echo "MT2: $MT2_ADDRESS"
echo ""

# Step 2: Mint tokens
echo "📦 Step 2: Minting tokens..."

# Admin mint大量代币
cast send $MT1_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "mint(address,uint256)" $ADMIN_ADDRESS 1000000000000000000000

cast send $MT2_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "mint(address,uint256)" $ADMIN_ADDRESS 1000000000000000000000

# USER1 mint一些代币用于制造价差
cast send $MT1_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "mint(address,uint256)" $USER1_ADDRESS 100000000000000000000

echo "✅ Balances after minting:"
echo "ADMIN MT1: $(cast call $MT1_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL)"
echo "ADMIN MT2: $(cast call $MT2_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL)"
echo "USER1 MT1: $(cast call $MT1_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL)"
echo ""

# Step 3: 创建流动性池
echo "📦 Step 3: Creating MT1/MT2 liquidity pool..."

# 授权
cast send $MT1_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)" $ROUTER_ADDRESS 1000000000000000000000

cast send $MT2_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)" $ROUTER_ADDRESS 1000000000000000000000

# 创建池子 (500 MT1 + 500 MT2)
echo "🏊 Creating pool with 500 MT1 + 500 MT2..."
cast send $ROUTER_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
    $MT1_ADDRESS $MT2_ADDRESS \
    500000000000000000000 500000000000000000000 \
    0 0 $ADMIN_ADDRESS $(($(date +%s) + 1800))

POOL_ADDRESS=$(cast call $FACTORY_V2_ADDRESS "getPair(address,address)(address)" $MT1_ADDRESS $MT2_ADDRESS --rpc-url $RPC_URL)
echo "✅ Pool created: $POOL_ADDRESS"

INITIAL_RESERVES=$(cast call $POOL_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
echo "📊 Initial reserves: $INITIAL_RESERVES"
echo ""

# Step 4: USER1制造价格失衡
echo "📦 Step 4: USER1 creates price imbalance..."

cast send $MT1_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)" $ROUTER_ADDRESS 100000000000000000000

echo "💱 USER1 swaps 50 MT1 for MT2..."
cast send $ROUTER_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" \
    50000000000000000000 0 "[$MT1_ADDRESS,$MT2_ADDRESS]" $USER1_ADDRESS $(($(date +%s) + 1800))

AFTER_SWAP_RESERVES=$(cast call $POOL_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
echo "📊 Reserves after swap: $AFTER_SWAP_RESERVES"
echo ""

# Step 5: 部署闪电套利合约
echo "📦 Step 5: Deploying Flash Arbitrage contract..."

ARBITRAGE_ADDRESS=$(forge create --rpc-url $RPC_URL src/FlashArbitrage.sol:FlashArbitrage \
    --private-key $USER2_KEY --broadcast \
    --constructor-args $FACTORY_V2_ADDRESS $MT1_ADDRESS $MT2_ADDRESS $POOL_ADDRESS $POOL_ADDRESS | get_deployed_address)

echo "✅ Flash Arbitrage contract deployed: $ARBITRAGE_ADDRESS"
echo ""

# Step 6: 给套利合约一些MT2用于演示
echo "📦 Step 6: Preparing arbitrage contract..."

# Admin给套利合约一些MT2，模拟从其他池子获得的代币
cast send $MT2_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)" $ARBITRAGE_ADDRESS 100000000000000000000

cast send $ARBITRAGE_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "depositMT2ForDemo(uint256)" 60000000000000000000

echo "✅ Arbitrage contract MT2 balance: $(cast call $ARBITRAGE_ADDRESS "getTokenBalance(address)(uint256)" $MT2_ADDRESS --rpc-url $RPC_URL)"
echo ""

# Step 7: 执行闪电套利
echo "📦 Step 7: Executing flash arbitrage..."

echo "💰 USER2 balances before arbitrage:"
echo "MT1: $(cast call $MT1_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)"
echo "MT2: $(cast call $MT2_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)"
echo ""

# 执行闪电套利 - 借出20个MT1
BORROW_AMOUNT=20000000000000000000
echo "⚡ Executing flash arbitrage (borrowing $BORROW_AMOUNT MT1)..."

cast send $ARBITRAGE_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL \
    "startFlashArbitrage(uint256)" $BORROW_AMOUNT

echo ""
echo "💰 USER2 balances after arbitrage:"
echo "MT1: $(cast call $MT1_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)"
echo "MT2: $(cast call $MT2_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)"

FINAL_RESERVES=$(cast call $POOL_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
echo "📊 Final reserves: $FINAL_RESERVES"

echo ""
echo "🎉 Flash arbitrage quiz demo completed!"
echo ""
echo "📊 Summary:"
echo "Initial pool reserves: $INITIAL_RESERVES"
echo "After price manipulation: $AFTER_SWAP_RESERVES"
echo "After flash arbitrage: $FINAL_RESERVES"
echo ""
echo "🧠 Quiz Learning Points:"
echo "1. ✅ Flash loan: Borrow without collateral via uniswapV2Call"
echo "2. ✅ Arbitrage: Profit from price differences"
echo "3. ✅ Fee calculation: Include 0.3% fee in repayment"
echo "4. ✅ Atomicity: All operations in single transaction"
echo "5. ✅ Risk-free: Transaction reverts if unprofitable"
