#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

# 设置环境变量
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export USER1_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export RPC_URL=http://localhost:8545
export CHAIN_ID=1337

echo "🚀 开始执行步骤7-9的测试..."

# 获取地址
ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)
USER1_ADDRESS=$(cast wallet address --private-key $USER1_PRIVATE_KEY)

echo "ADMIN_ADDRESS=$ADMIN_ADDRESS"
echo "USER1_ADDRESS=$USER1_ADDRESS"

# 从步骤1-6获取合约地址（这里需要手动设置，或者从环境变量读取）
# 你可以从之前的脚本输出中获取这些地址
if [ -z "$ERC20_ADDRESS" ]; then
    echo "❌ 错误：请设置ERC20_ADDRESS环境变量"
    exit 1
fi

if [ -z "$TOKENBANK_ADDRESS" ]; then
    echo "❌ 错误：请设置TOKENBANK_ADDRESS环境变量"
    exit 1
fi

if [ -z "$DELEGATOR_ADDRESS" ]; then
    echo "❌ 错误：请设置DELEGATOR_ADDRESS环境变量"
    exit 1
fi

echo "📋 使用的合约地址:"
echo "ERC20_ADDRESS=$ERC20_ADDRESS"
echo "TOKENBANK_ADDRESS=$TOKENBANK_ADDRESS"
echo "DELEGATOR_ADDRESS=$DELEGATOR_ADDRESS"

# 检查USER1当前的ERC20余额
echo "✅ 检查USER1当前的ERC20余额:"
USER1_CURRENT_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1当前ERC20余额: $USER1_CURRENT_BALANCE"

# 检查USER1当前的TokenBank余额
echo "✅ 检查USER1当前的TokenBank余额:"
USER1_CURRENT_TOKENBANK_BALANCE=$(cast call $TOKENBANK_ADDRESS "getUserBalance(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1当前TokenBank余额: $USER1_CURRENT_TOKENBANK_BALANCE"

# 调用use_delegate.ts,生成授权并且执行multicall
npx tsx use_delegate.ts

# 检查USER1在ERC20上的余额
echo "USER1在ERC20上的余额:"
USER1_ERC20_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1 ERC20余额: $USER1_ERC20_BALANCE"

# 检查USER1在TokenBank里的余额
echo "USER1在TokenBank里的余额:"
USER1_TOKENBANK_BALANCE=$(cast call $TOKENBANK_ADDRESS "getUserBalance(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1 TokenBank余额: $USER1_TOKENBANK_BALANCE"

# 检查TokenBank在ERC20里的余额
echo "TokenBank在ERC20里的余额:"
TOKENBANK_ERC20_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $TOKENBANK_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "TokenBank ERC20余额: $TOKENBANK_ERC20_BALANCE"

# 检查USER1给TokenBank的allowance
echo "USER1给TokenBank的allowance:"
USER1_TOKENBANK_ALLOWANCE=$(cast call $ERC20_ADDRESS "allowance(address,address)(uint256)" $USER1_ADDRESS $TOKENBANK_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1给TokenBank的allowance: $USER1_TOKENBANK_ALLOWANCE"

# 验证结果
echo "🎯 验证结果:"
echo "   - USER1 ERC20余额变化: $USER1_CURRENT_BALANCE -> $USER1_ERC20_BALANCE"
echo "   - USER1 TokenBank余额变化: $USER1_CURRENT_TOKENBANK_BALANCE -> $USER1_TOKENBANK_BALANCE"
echo "   - TokenBank ERC20余额: $TOKENBANK_ERC20_BALANCE"
echo "   - USER1给TokenBank的allowance: $USER1_TOKENBANK_ALLOWANCE"

# 计算预期的余额变化
EXPECTED_ERC20_DECREASE="10000000000000000000"  # 10个token
EXPECTED_TOKENBANK_INCREASE="10000000000000000000"  # 10个token

# 使用 bc 计算实际变化（处理大整数）
ACTUAL_ERC20_DECREASE=$(echo "$USER1_CURRENT_BALANCE - $USER1_ERC20_BALANCE" | bc)
ACTUAL_TOKENBANK_INCREASE=$(echo "$USER1_TOKENBANK_BALANCE - $USER1_CURRENT_TOKENBANK_BALANCE" | bc)

echo "📊 余额变化分析:"
echo "   - ERC20余额减少: $ACTUAL_ERC20_DECREASE (期望: $EXPECTED_ERC20_DECREASE)"
echo "   - TokenBank余额增加: $ACTUAL_TOKENBANK_INCREASE (期望: $EXPECTED_TOKENBANK_INCREASE)"

if [ "$ACTUAL_ERC20_DECREASE" = "$EXPECTED_ERC20_DECREASE" ] && [ "$ACTUAL_TOKENBANK_INCREASE" = "$EXPECTED_TOKENBANK_INCREASE" ]; then
    echo "✅ multicall操作成功！"
    echo "   - 通过一个交易完成了approve和deposit操作"
    echo "   - 余额变化符合预期"
else
    echo "❌ multicall操作可能失败或余额变化不符合预期"
fi

echo "🎉 步骤7-9测试完成！"
