#!/bin/bash

# 环境变量设置
export ERC20=0x5FbDB2315678afecb367f032d93F642f64180aa3
export NFT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
export NFTMARKET=0x610178dA211FEF7D417bC0e6FeD39F05609AD788
export tokenBank=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export Dewei=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
export USER2=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
export USER3=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
export adminAddress=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export ON_CHAIN_PATH=/Users/zhaidewei/upchain_2025_s3/dapp_quiz/fc66ef6c/on_chain
export OFF_CHAIN_PATH=/Users/zhaidewei/upchain_2025_s3/dapp_quiz/fc66ef6c/off_chain
export anvil="http://localhost:8545"
export VERSION="1.0"

# 私钥设置
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export USER2_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER3_PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

echo "=== Step 6: NFT Market Permit Buy Test ==="

# 1. 检查NFT合约状态
echo "1. 检查NFT合约状态..."
echo "Total supply: $(cast call --rpc-url $anvil $NFT "totalSupply()(uint256)")"
echo "Next token ID: $(cast call --rpc-url $anvil $NFT "getNextTokenId()(uint256)")"

# 2. 检查当前NFT owner
echo "2. 检查当前NFT owner..."
echo "Token 0 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "0")" # dewei
echo "Token 1 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "1")" # user3
echo "Token 2 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "2")" # user3

# 3. 如果需要，mint更多NFT给USER2
echo "3. Minting NFT for USER2..."
cast send --rpc-url $anvil --account anvil-tester --password '' $NFT "mint(address)" $USER2

# 4. 再次检查NFT owner
echo "4. 再次检查NFT owner..."
echo "Token 0 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "0")"
echo "Token 1 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "1")"
echo "Token 2 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "2")"
echo "Token 3 owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "3")" # user2

# 5. USER2 (seller) approve NFT to NFTMarket and list
echo "5. USER2 approve NFT to NFTMarket and list..."
cast send \
--rpc-url $anvil \
--private-key $USER2_PRIVATE_KEY \
$NFT \
"approve(address,uint256)" \
$NFTMARKET "3"

cast send \
--rpc-url $anvil \
--private-key $USER2_PRIVATE_KEY \
$NFTMARKET \
"list(uint256,uint256)" \
"3" "1000000000"

# 6. 检查listing状态
echo "6. 检查listing状态..."
echo "Token 3 approved to NFTMarket: $(cast call --rpc-url $anvil $NFT "getApproved(uint256)(address)" "3")"

# 7. Admin给USER3在ERC20里充值
echo "7. Admin给USER3在ERC20里充值..."
cast send \
--rpc-url $anvil \
--account anvil-tester \
--password '' \
$ERC20 \
"transfer(address,uint256)" \
$USER3 "1000000000000000000000000" # 1e24 tokens

# 8. 检查USER3的ERC20余额
echo "8. 检查USER3的ERC20余额..."
echo "USER3 ERC20 balance: $(cast call --rpc-url $anvil $ERC20 "balanceOf(address)(uint256)" $USER3)"

# 9. USER3 approve ERC20给NFTMarket
echo "9. USER3 approve ERC20给NFTMarket..."
cast send \
--rpc-url $anvil \
--private-key $USER3_PRIVATE_KEY \
$ERC20 \
"approve(address,uint256)" \
$NFTMARKET "1000000000000000000000000"

# 10. 生成admin签名
echo "10. 生成admin签名..."
export DEADLINE=$(($(date +%s) + 3600))
export PRICE=1000000000

cd $OFF_CHAIN_PATH
npx tsx nftmarket-cli/src/index.ts sign \
  --private-key $ADMIN_PRIVATE_KEY \
  --token-id "3" \
  --buyer $USER3 \
  --price $PRICE \
  --deadline $DEADLINE \
  --chain-id 31337 \
  --contract-address $NFTMARKET \
  --domain-name DNFT \
  --domain-version 1.0

#Signature generated:
#v: 27
#r: 0x42f953bf4e3fce9d23b09b699f070b8e48cf8f0f6beaabb17e8198b72e620374
#s: 0x35e99771696fb2eec6458666686a690a27b816e738c447a8efcb6ee096451e26
#Full signature: 0x42f953bf4e3fce9d23b09b699f070b8e48cf8f0f6beaabb17e8198b72e62037435e99771696fb2eec6458666686a690a27b816e738c447a8efcb6ee096451e261b

# 11. USER3调用permitBuy
echo "11. USER3调用permitBuy..."
# 这里需要从上面的签名输出中获取签名值
# 假设签名是: 0x42f953bf4e3fce9d23b09b699f070b8e48cf8f0f6beaabb17e8198b72e62037435e99771696fb2eec6458666686a690a27b816e738c447a8efcb6ee096451e261b
export SIG=0x42f953bf4e3fce9d23b09b699f070b8e48cf8f0f6beaabb17e8198b72e62037435e99771696fb2eec6458666686a690a27b816e738c447a8efcb6ee096451e261b

# 解析签名
export V=27
export R=0x42f953bf4e3fce9d23b09b699f070b8e48cf8f0f6beaabb17e8198b72e620374
export S=0x35e99771696fb2eec6458666686a690a27b816e738c447a8efcb6ee096451e26

cast send \
--rpc-url $anvil \
--private-key $USER3_PRIVATE_KEY \
$NFTMARKET \
"permitBuy(uint256,uint256,uint256,uint8,bytes32,bytes32)" \
"3" $PRICE $DEADLINE $V $R $S

# 12. 检查结果
echo "12. 检查交易结果..."
echo "Token 3 new owner: $(cast call --rpc-url $anvil $NFT "ownerOf(uint256)(address)" "3")" # 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
echo "USER3 ERC20 balance after: $(cast call --rpc-url $anvil $ERC20 "balanceOf(address)(uint256)" $USER3)" # USER3 ERC20 balance after: 999999999999999000000000 [9.999e23]
echo "NFTMarket ERC20 balance: $(cast call --rpc-url $anvil $ERC20 "balanceOf(address)(uint256)" $NFTMARKET)" # 0
echo "USER2 ERC20 balance: $(cast call --rpc-url $anvil $ERC20 "balanceOf(address)(uint256)" $USER2)" # USER2 ERC20 balance: 1000000000 [1e9]

echo "=== Step 6 Complete ==="
