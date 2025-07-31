#!/bin/bash
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
echo "🚀 开始初始化 Airdop Merkle NFT Market 测试环境..."

# 设置anvil账户地址变量
export ADMIN_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
export USER1_ADDRESS="0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
export USER2_ADDRESS="0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"

# 设置anvil默认私钥
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" #pragma: allowlist secret
export USER1_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" #pragma: allowlist secret
export USER2_PRIVATE_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a" #pragma: allowlist secret

echo "📋 账户信息:"
echo "  Admin: $ADMIN_ADDRESS"
echo "  User1: $USER1_ADDRESS"
echo "  User2: $USER2_ADDRESS"

# 1. 启动anvil (如果还没有启动)
echo "🔧 检查anvil是否运行..."
if ! pgrep -f anvil > /dev/null; then
    echo "⚠️  Anvil未运行，请先运行: ~/script/start_anvil"
    echo "   或者手动启动: anvil"
    exit 1
fi

echo "✅ Anvil已运行"

cd /Users/zhaidewei/upchain_2025_s3/advance_contract/faa435a5

# 2. 编译合约
echo "🔨 编译合约..."
forge build

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✅ 编译成功"


# 3. 部署ERC20合约
echo "📦 部署ERC20合约..."
export ERC20_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/Erc20Eip2612Compatiable.sol:Erc20Eip2612Compatiable \
    --broadcast \
    --constructor-args "1.0" | grep "Deployed to:" | awk '{print $3}')

echo "✅ ERC20合约部署到: $ERC20_ADDRESS"

# 4. 部署NFT合约
echo "📦 部署NFT合约..."
export NFT_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/BaseErc721.sol:BaseErc721 \
    --broadcast \
    --constructor-args "Dewei NFT" "DWNFT" | grep "Deployed to:" | awk '{print $3}')

echo "✅ NFT合约部署到: $NFT_ADDRESS"

# 5. 部署NFTMarket合约
echo "🏦 部署NFTMarket合约..."
export NFTMARKET_ADDRESS=$(forge create --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    src/AirdopMerkleNFTMarket.sol:AirdopMerkleNFTMarket \
    --broadcast \
    --constructor-args $ERC20_ADDRESS $NFT_ADDRESS "DeweiERC2612" "1.0" | grep "Deployed to:" | awk '{print $3}')

# Note that, domain name and version must align with the Erc20Eip2612Compatiable contract.
# It is used in the signarture.

echo "✅ NFTMarket合约部署到: $NFTMARKET_ADDRESS"

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

# 8. admin给user2转账10个token
echo "💸 Admin给User2转账10个token..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    $ERC20_ADDRESS \
    "transfer(address,uint256)" \
    $USER2_ADDRESS \
    "10000000000000000000" # 10 ether

echo "✅ User2获得10个token"

# 9. admin mint 2 nft to user1
echo "🎁 Admin给User1铸造第一个NFT..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    $NFT_ADDRESS \
    "mint(address)" \
    $USER1_ADDRESS

echo "🎁 Admin给User1铸造第二个NFT..."
cast send --rpc-url http://127.0.0.1:8545 \
    --private-key $ADMIN_PRIVATE_KEY \
    $NFT_ADDRESS \
    "mint(address)" \
    $USER1_ADDRESS

echo "✅ User1获得两个NFT"


# 10. 验证初始状态
echo "🔍 验证初始状态..."

# 检查admin在erc20的余额
ADMIN_TOKEN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $ADMIN_ADDRESS)

echo "  Admin在ERC20余额: $ADMIN_TOKEN_BALANCE (应该是890000000000000000000)" # 890 ether

# 检查user1在erc20的余额
USER1_TOKEN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER1_ADDRESS)

echo "  User1在ERC20余额: $USER1_TOKEN_BALANCE (应该是 100000000000000000000)" # 100 ether

# 检查user2在erc20的余额
USER2_TOKEN_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER2_ADDRESS)

echo "  User2在ERC20余额: $USER2_TOKEN_BALANCE (应该是 10000000000000000000)" # 10 ether

# 检查user1的nft
USER1_NFT_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $NFT_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER1_ADDRESS)

echo "  User1在NFT余额: $USER1_NFT_BALANCE (应该是 2)" # 2 nft

# 检查nft tokenid 的owner
NFT_TOKENID_1_OWNER=$(cast call --rpc-url http://127.0.0.1:8545 \
    $NFT_ADDRESS \
    "ownerOf(uint256)(address)" \
    0)

echo "  NFT tokenid 1 的owner: $NFT_TOKENID_1_OWNER (应该是 User1: $USER1_ADDRESS)"

NFT_TOKENID_2_OWNER=$(cast call --rpc-url http://127.0.0.1:8545 \
    $NFT_ADDRESS \
    "ownerOf(uint256)(address)" \
    1)

echo "  NFT tokenid 2 的owner: $NFT_TOKENID_2_OWNER (应该是 User1: $USER1_ADDRESS)"

# 检查user2的nft
USER2_NFT_BALANCE=$(cast call --rpc-url http://127.0.0.1:8545 \
    $NFT_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER2_ADDRESS)

echo "  User2在NFT余额: $USER2_NFT_BALANCE (应该是 0)" # 0 nft


echo ""
echo "🎉 初始化完成！"
echo ""
echo "📋 合约地址:"
echo "  ERC20: $ERC20_ADDRESS"
echo "  NFT: $NFT_ADDRESS"
echo "  NFTMarket: $NFTMARKET_ADDRESS"
echo ""
echo "👥 测试账户:"
echo "  Admin: $ADMIN_ADDRESS"
echo "  User1: $USER1_ADDRESS"
echo "  User2: $USER2_ADDRESS"
