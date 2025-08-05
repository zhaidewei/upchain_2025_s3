#!/bin/bash

# Set environment variables
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" # pragma: allowlist secret
export ADMIN_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo "🚀 Starting deployment and address capture..."

# Create output file for addresses
echo "# Deployed Contract Addresses" > deployed_addresses.txt
echo "Deployment Date: $(date)" >> deployed_addresses.txt
echo "" >> deployed_addresses.txt

# 1. Deploy ERC20 Token
echo "📦 Deploying ERC20 Token..."
ERC20_OUTPUT=$(forge create src/A_Erc20Token.sol:Erc20Token --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
ERC20_ADDRESS=$(echo "$ERC20_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "ERC20 Token deployed at: $ERC20_ADDRESS"
echo "ERC20_TOKEN=$ERC20_ADDRESS" >> deployed_addresses.txt

# 2. Deploy ERC721 NFT
echo "🎨 Deploying ERC721 NFT..."
ERC721_OUTPUT=$(forge create src/B_Erc721Nft.sol:Erc721Nft --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
ERC721_ADDRESS=$(echo "$ERC721_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "ERC721 NFT deployed at: $ERC721_ADDRESS"
echo "ERC721_NFT=$ERC721_ADDRESS" >> deployed_addresses.txt

# 3. Deploy NFTMarketD1 Implementation (with constructor args)
echo "🏪 Deploying NFTMarketD1 Implementation..."
D1_OUTPUT=$(forge create src/D1_NftMarket.sol:NFTMarketD1 --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000)
D1_ADDRESS=$(echo "$D1_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "NFTMarketD1 Implementation deployed at: $D1_ADDRESS"
echo "NFTMARKET_D1_IMPL=$D1_ADDRESS" >> deployed_addresses.txt

# 4. Deploy NFTMarketD2 Implementation (with constructor args)
echo "🔧 Deploying NFTMarketD2 Implementation..."
D2_OUTPUT=$(forge create src/D2_NftMarket.sol:NFTMarketD2 --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000)
D2_ADDRESS=$(echo "$D2_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "NFTMarketD2 Implementation deployed at: $D2_ADDRESS"
echo "NFTMARKET_D2_IMPL=$D2_ADDRESS" >> deployed_addresses.txt

# 5. Deploy Proxy Admin
echo "👑 Deploying Proxy Admin..."
ADMIN_OUTPUT=$(forge create @openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
ADMIN_ADDRESS=$(echo "$ADMIN_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "Proxy Admin deployed at: $ADMIN_ADDRESS"
echo "PROXY_ADMIN=$ADMIN_ADDRESS" >> deployed_addresses.txt

# 6. Deploy TransparentUpgradeableProxy with D1
echo "🔗 Deploying TransparentUpgradeableProxy with D1..."
# Prepare initialization data for D1
INIT_DATA=$(cast abi-encode "initialize(address,address)" $ERC20_ADDRESS $ERC721_ADDRESS)

PROXY_OUTPUT=$(forge create @openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $D1_ADDRESS $ADMIN_ADDRESS $INIT_DATA)
PROXY_ADDRESS=$(echo "$PROXY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "TransparentUpgradeableProxy deployed at: $PROXY_ADDRESS"
echo "PROXY_D1=$PROXY_ADDRESS" >> deployed_addresses.txt

# 7. Deploy TransparentUpgradeableProxy with D2
echo "🔗 Deploying TransparentUpgradeableProxy with D2..."
# Prepare initialization data for D2
INIT_DATA_D2=$(cast abi-encode "initialize(address,address,string,string)" $ERC20_ADDRESS $ERC721_ADDRESS "NFTMarket" "1.0.0")

PROXY_D2_OUTPUT=$(forge create @openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $D2_ADDRESS $ADMIN_ADDRESS $INIT_DATA_D2)
PROXY_D2_ADDRESS=$(echo "$PROXY_D2_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "TransparentUpgradeableProxy (D2) deployed at: $PROXY_D2_ADDRESS"
echo "PROXY_D2=$PROXY_D2_ADDRESS" >> deployed_addresses.txt

# 8. Deploy ERC721 Proxy with initialization
echo "🎨 Deploying ERC721 Proxy with initialization..."
# Prepare initialization data for ERC721
INIT_DATA_ERC721=$(cast abi-encode "initialize(string,string)" "Erc721Nft" "ERC721Nft")

PROXY_ERC721_OUTPUT=$(forge create @openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY --constructor-args $ERC721_ADDRESS $ADMIN_ADDRESS $INIT_DATA_ERC721)
PROXY_ERC721_ADDRESS=$(echo "$PROXY_ERC721_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
echo "ERC721 Proxy deployed at: $PROXY_ERC721_ADDRESS"
echo "PROXY_ERC721=$PROXY_ERC721_ADDRESS" >> deployed_addresses.txt

echo ""
echo "✅ Deployment complete! Addresses saved to deployed_addresses.txt"
echo ""
echo "📋 Summary of deployed contracts:"
echo "=================================="
cat deployed_addresses.txt
echo ""
echo "🎯 To use these addresses in your scripts:"
echo "source deployed_addresses.txt"
