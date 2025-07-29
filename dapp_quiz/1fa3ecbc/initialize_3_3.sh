#!/bin/bash

echo "🚀 开始初始化 Permit2 TokenBank 测试环境..."

# 设置账户地址变量
export ADMIN_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
export USER1_ADDRESS="0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
export USER2_ADDRESS="0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"

# 设置anvil默认私钥
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export USER1_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export USER2_PRIVATE_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

echo "📋 账户信息:"
echo "  Admin: $ADMIN_ADDRESS"
echo "  User1: $USER1_ADDRESS"
echo "  User2: $USER2_ADDRESS"

# 1. 启动anvil (如果还没有启动)
echo "🔧 检查anvil是否运行..."
if ! pgrep -f anvil > /dev/null; then
    echo "⚠️  Anvil未运行，请先运行: ~/script/start_anvil --fork"
    echo "   或者手动启动: anvil --fork-url https://mainnet.infura.io/v3/YOUR_KEY"
    exit 1
fi

echo "✅ Anvil已运行"

cd /Users/zhaidewei/upchain_2025_s3/dapp_quiz/1fa3ecbc/on_chain

# 2. 编译合约
echo "🔨 编译合约..."
forge build

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✅ 编译成功"

# 3. 部署MyPermit2合约
echo "🔐 部署MyPermit2合约..."
export PERMIT2_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/MyPermit2.sol:MyPermit2 \
    --broadcast | grep "Deployed to:" | awk '{print $3}')

echo "✅ MyPermit2合约部署到: $PERMIT2_ADDRESS"

# 4. 部署ERC20合约
echo "📦 部署ERC20合约..."
export ERC20_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/BaseErc20.sol:BaseErc20 \
    --broadcast \
    --constructor-args "TestToken" "TT" | grep "Deployed to:" | awk '{print $3}')

echo "✅ ERC20合约部署到: $ERC20_ADDRESS"

# 5. 部署TokenBank合约
echo "🏦 部署TokenBank合约..."
export TOKENBANK_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/TokenBank.sol:TokenBank \
    --broadcast \
    --constructor-args $ERC20_ADDRESS $PERMIT2_ADDRESS | grep "Deployed to:" | awk '{print $3}')

echo "✅ TokenBank合约部署到: $TOKENBANK_ADDRESS"

# 6. 检查admin的初始余额（合约部署时已经mint了1000个token）
echo "💰 检查admin的初始余额..."
ADMIN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $ADMIN_ADDRESS)

echo "✅ Admin初始余额: $ADMIN_BALANCE (应该是1000000000000000000000)"

# 7. admin给user1转账100个token
echo "💸 Admin给User1转账100个token..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    $ERC20_ADDRESS \
    "transfer(address,uint256)" \
    $USER1_ADDRESS \
    "100000000000000000000" # 100 ether

echo "✅ User1获得100个token"

# 8. admin approve permit2合约max值
echo "🔐 Admin approve Permit2合约max值..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    $ERC20_ADDRESS \
    "approve(address,uint256)" \
    $PERMIT2_ADDRESS \
    "115792089237316195423570985008687907853269984665640564039457584007913129639935" # max uint256

echo "✅ Admin已approve Permit2合约"

# 9. user1 approve permit2合约max值
echo "🔐 User1 approve Permit2合约max值..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $USER1_PRIVATE_KEY \
    $ERC20_ADDRESS \
    "approve(address,uint256)" \
    $PERMIT2_ADDRESS \
    "115792089237316195423570985008687907853269984665640564039457584007913129639935" # max uint256

echo "✅ User1已approve Permit2合约"

# 10. 验证初始状态
echo "🔍 验证初始状态..."

# 检查admin在erc20的余额
ADMIN_TOKEN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $ADMIN_ADDRESS)

echo "  Admin在ERC20余额: $ADMIN_TOKEN_BALANCE (应该是900000000000000000000)"

# 检查admin对permit2的allowance
ADMIN_PERMIT2_ALLOWANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "allowance(address,address)(uint256)" \
    $ADMIN_ADDRESS \
    $PERMIT2_ADDRESS)

echo "  Admin对Permit2的allowance: $ADMIN_PERMIT2_ALLOWANCE (应该是max值)"

# 检查user1在tokenbank的余额
USER1_BANK_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $TOKENBANK_ADDRESS \
    "balances(address)" \
    $USER1_ADDRESS)

echo "  User1在TokenBank余额: $USER1_BANK_BALANCE (应该是0)"

# 检查user1在erc20的余额
USER1_TOKEN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER1_ADDRESS)

echo "  User1在ERC20余额: $USER1_TOKEN_BALANCE (应该是100000000000000000000)"

# 检查tokenbank总余额
TOKENBANK_TOTAL_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $TOKENBANK_ADDRESS)

echo "  TokenBank总余额: $TOKENBANK_TOTAL_BALANCE (应该是0)"

# 检查user1对permit2的allowance
USER1_PERMIT2_ALLOWANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "allowance(address,address)(uint256)" \
    $USER1_ADDRESS \
    $PERMIT2_ADDRESS)

echo "  User1对Permit2的allowance: $USER1_PERMIT2_ALLOWANCE (应该是max值)"

echo ""
echo "🎉 初始化完成！"
echo ""
echo "📋 合约地址:"
echo "  ERC20: $ERC20_ADDRESS"
echo "  TokenBank: $TOKENBANK_ADDRESS"
echo "  Permit2: $PERMIT2_ADDRESS"
echo ""
echo "👥 测试账户:"
echo "  Admin: $ADMIN_ADDRESS"
echo "  User1: $USER1_ADDRESS"
echo "  User2: $USER2_ADDRESS"
echo ""
echo "💡 下一步: 使用User1构造EIP712签名进行depositWithPermit2测试"
echo ""
echo "🔧 环境变量已设置，可以在其他脚本中使用:"
echo "  export ERC20_ADDRESS=$ERC20_ADDRESS"
echo "  export TOKENBANK_ADDRESS=$TOKENBANK_ADDRESS"
echo "  export PERMIT2_ADDRESS=$PERMIT2_ADDRESS"
