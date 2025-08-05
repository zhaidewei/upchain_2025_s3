#! /bin/bash

# Restart anvil
pkill -f anvil
anvil &

capture_address() {
    local output="$1"
    local address=$(echo "$output" | grep "Deployed to:" | awk '{print $3}')
    echo "$address"
}

source /Users/zhaidewei/script/anvil_accounts #
# This script exports the following variables:
#   ADMIN_ADDRESS, ADMIN_PRIVATE_KEY
#   USER1_ADDRESS, USER1_PRIVATE_KEY
# ..
#   USER9_ADDRESS, USER9_PRIVATE_KEY

# step-0 admin 部署一个erc20 合约 A
A_ERC20_OUTPUT=$(forge create src/A_Erc20Token.sol:Erc20Token --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
A_ERC20_ADDRESS=$(capture_address "$A_ERC20_OUTPUT")
echo "ERC20 Token deployed at: $A_ERC20_ADDRESS"
echo "ERC20_TOKEN=$A_ERC20_ADDRESS" > deployed_addresses.txt

# step-1 部署可升级的erc721合约
# 实现合约 B
B_NFT_OUTPUT=$(forge create src/B_Erc721Nft.sol:Erc721Nft --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
B_NFT_ADDRESS=$(capture_address "$B_NFT_OUTPUT")
echo "ERC721 NFT deployed at: $B_NFT_ADDRESS"
echo "ERC721_NFT=$B_NFT_ADDRESS" >> deployed_addresses.txt

# proxy合约 C (指向B，C继承 OpZ ERC1967Proxy)
# Prepare initialization data for ERC721
INIT_DATA_NFT=$(cast abi-encode "initialize(string,string)" "Erc721Nft" "ERC721Nft")

PROXY_NFT_OUTPUT=$(forge create src/C_ProxyNft.sol:ProxyNftC --rpc-url http://localhost:8545 \
--broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $B_NFT_ADDRESS $ADMIN_ADDRESS $INIT_DATA_NFT)
PROXY_NFT_ADDRESS=$(capture_address "$PROXY_NFT_OUTPUT")
echo "Proxy NFT deployed at: $PROXY_NFT_ADDRESS"
echo "PROXY_NFT=$PROXY_NFT_ADDRESS" >> deployed_addresses.txt

# step-2 部署可升级的nftmarket合约
# 部署合约D1（第一版基础功能）
NFTMARKET_D1_OUTPUT=$(forge create src/D1_NftMarket.sol:NFTMarketD1 --rpc-url http://localhost:8545 \
--broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $A_ERC20_ADDRESS $B_NFT_ADDRESS)
NFTMARKET_D1_ADDRESS=$(capture_address "$NFTMARKET_D1_OUTPUT")
echo "NFTMarketD1 deployed at: $NFTMARKET_D1_ADDRESS"
echo "NFTMARKET_D1=$NFTMARKET_D1_ADDRESS" >> deployed_addresses.txt

# proxy 合约E（指向D1，E继承OpZ ERC1967Proxy）
PROXY_NFT_MARKET_OUTPUT=$(forge create src/E_ProxyNftMarket.sol:ProxyNftMarketE --rpc-url http://localhost:8545 \
--broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $NFTMARKET_D1_ADDRESS $ADMIN_ADDRESS 0x)
PROXY_NFT_MARKET_ADDRESS=$(capture_address "$PROXY_NFT_MARKET_OUTPUT")
echo "Proxy NFT Market deployed at: $PROXY_NFT_MARKET_ADDRESS"
echo "PROXY_NFT_MARKET=$PROXY_NFT_MARKET_ADDRESS" >> deployed_addresses.txt

# step-3 admin 从 C里呼叫 mint 2个nft token给 user1
cast send $PROXY_NFT_ADDRESS "mint(address,uint256)" $USER1_ADDRESS 2 --rpc-url http://localhost:8545 --private-key $ADMIN_PRIVATE_KEY

# step-4 user1 在C上 approve all token 给E (这次解决以及下次都不用再approve了)
# step-5 user1 在 E 上架 token 0

# step-6 部署合约D2，D2有离线签名 permitList 方法（ERC721 签名）
# step-7 在E里，把implementation 从D1 指向D2（升级合约）

# step-8 user1私钥签名（使用typescript viem 从私钥钱包生成签名）
# step-9 user1去E上架nft token 1
