#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

# 设置环境变量
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export USER1_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export RPC_URL=http://localhost:8545
export CHAIN_ID=1337

echo "🚀 开始执行步骤1-5的测试..."

# 获取地址
ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)
USER1_ADDRESS=$(cast wallet address --private-key $USER1_PRIVATE_KEY)

echo "ADMIN_ADDRESS=$ADMIN_ADDRESS"
echo "USER1_ADDRESS=$USER1_ADDRESS"

# 步骤1: 部署ERC20合约，总量1000个token，转账给user1 100个
echo "📦 步骤1: 部署ERC20合约..."
ERC20_ADDRESS=$(forge create --rpc-url $RPC_URL src/Erc20.sol:Erc20Impl --private-key $ADMIN_PRIVATE_KEY --broadcast | awk '/Deployed to:/ {print $3}')

echo "ERC20_ADDRESS=$ERC20_ADDRESS"

# 检查ADMIN的ERC20余额
echo "💰 检查ADMIN的ERC20余额..."
ADMIN_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "ADMIN ERC20余额: $ADMIN_BALANCE"

# 如果ADMIN余额为0，需要先mint一些代币
if [ "$ADMIN_BALANCE" = "0" ]; then
    echo "⚠️  ADMIN余额为0，需要先mint代币..."
    echo "❌ 错误：ERC20合约没有给部署者分配初始代币"
    echo "请修改ERC20合约，在构造函数中给部署者分配初始代币"
    exit 1
fi

# 给USER1转账100个token
echo "💰 给USER1转账100个token..."
cast send $ERC20_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL "transfer(address,uint256)" $USER1_ADDRESS 100000000000000000000

# 检查USER1的余额
echo "✅ 检查USER1的ERC20余额:"
USER1_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1 ERC20余额: $USER1_BALANCE (应该是100000000000000000000)"

# 步骤2: 部署TokenBank合约
echo "📦 步骤2: 部署TokenBank合约..."
TOKENBANK_ADDRESS=$(forge create --rpc-url $RPC_URL src/TokenBank.sol:TokenBank --private-key $ADMIN_PRIVATE_KEY --broadcast --constructor-args $ERC20_ADDRESS | awk '/Deployed to:/ {print $3}')

echo "TOKENBANK_ADDRESS=$TOKENBANK_ADDRESS"

# 检查TokenBank合约的TOKEN地址
echo "✅ 检查TokenBank合约的TOKEN地址:"
TOKENBANK_TOKEN=$(cast call $TOKENBANK_ADDRESS "TOKEN()(address)" --rpc-url $RPC_URL)
echo "TokenBank的TOKEN地址: $TOKENBANK_TOKEN (应该是 $ERC20_ADDRESS)"

# 步骤3: USER1向ERC20 approve 10个token给TokenBank合约
echo "📝 步骤3: USER1向ERC20 approve 10个token给TokenBank合约..."
cast send $ERC20_ADDRESS --private-key $USER1_PRIVATE_KEY --rpc-url $RPC_URL "approve(address,uint256)" $TOKENBANK_ADDRESS 10000000000000000000

# 检查approve是否成功
echo "✅ 检查approve是否成功:"
ALLOWANCE=$(cast call $ERC20_ADDRESS "allowance(address,address)(uint256)" $USER1_ADDRESS $TOKENBANK_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1给TokenBank的allowance: $ALLOWANCE (应该是10000000000000000000)"

# 步骤4: USER1调用TokenBank的deposit方法
echo "💰 步骤4: USER1调用TokenBank的deposit方法..."
cast send $TOKENBANK_ADDRESS --private-key $USER1_PRIVATE_KEY --rpc-url $RPC_URL "deposit(uint256)" 10000000000000000000

# 步骤5: 检查余额
echo "✅ 步骤5: 检查余额..."

# 检查USER1在ERC20上的余额
echo "USER1在ERC20上的余额:"
USER1_ERC20_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1 ERC20余额: $USER1_ERC20_BALANCE (应该是90000000000000000000)"

# 检查USER1在TokenBank里的余额
echo "USER1在TokenBank里的余额:"
USER1_TOKENBANK_BALANCE=$(cast call $TOKENBANK_ADDRESS "getUserBalance(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "USER1 TokenBank余额: $USER1_TOKENBANK_BALANCE (应该是10000000000000000000)"

# 检查TokenBank在ERC20里的余额
echo "TokenBank在ERC20里的余额:"
TOKENBANK_ERC20_BALANCE=$(cast call $ERC20_ADDRESS "balanceOf(address)(uint256)" $TOKENBANK_ADDRESS --rpc-url $RPC_URL | sed 's/ \[.*\]//')
echo "TokenBank ERC20余额: $TOKENBANK_ERC20_BALANCE (应该是10000000000000000000)"

# 验证结果
echo "🎯 验证结果:"
if [ "$USER1_ERC20_BALANCE" = "90000000000000000000" ] && [ "$USER1_TOKENBANK_BALANCE" = "10000000000000000000" ] && [ "$TOKENBANK_ERC20_BALANCE" = "10000000000000000000" ]; then
    echo "✅ 所有余额检查通过！"
    echo "   - USER1在ERC20上有90个token"
    echo "   - USER1在TokenBank里有10个token"
    echo "   - TokenBank在ERC20里有10个token"
else
    echo "❌ 余额检查失败！"
    echo "   - USER1 ERC20余额: $USER1_ERC20_BALANCE (期望: 90000000000000000000)"
    echo "   - USER1 TokenBank余额: $USER1_TOKENBANK_BALANCE (期望: 10000000000000000000)"
    echo "   - TokenBank ERC20余额: $TOKENBANK_ERC20_BALANCE (期望: 10000000000000000000)"
fi

echo "🎉 步骤1-5测试完成！"
echo ""
echo "📋 部署的合约地址:"
echo "ERC20_ADDRESS=$ERC20_ADDRESS"
echo "TOKENBANK_ADDRESS=$TOKENBANK_ADDRESS"
echo ""
echo "👤 用户地址:"
echo "ADMIN_ADDRESS=$ADMIN_ADDRESS"
echo "USER1_ADDRESS=$USER1_ADDRESS"
