#!/bin/bash

# Set environment variables
export ADMIN_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" # pragma: allowlist secret
export ADMIN_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Load deployed addresses
source deployed_addresses.txt

echo "🔍 Debugging contract state..."

# 1. Check if NFTMarketD2 is initialized
echo "📋 Checking NFTMarketD2 initialization..."
DOMAIN_INFO=$(cast call $NFTMARKET_D2_IMPL "getDomainInfo()" --rpc-url http://localhost:8545 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ NFTMarketD2 is initialized"
    echo "Domain info: $DOMAIN_INFO"
else
    echo "❌ NFTMarketD2 is not initialized or has no getDomainInfo function"
fi

# 2. Check NFT contract address
echo "🎨 Checking NFT contract address..."
NFT_CONTRACT=$(cast call $NFTMARKET_D2_IMPL "NFT_CONTRACT()" --rpc-url http://localhost:8545 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ NFT contract address: $NFT_CONTRACT"
else
    echo "❌ Could not get NFT contract address"
fi

# 3. Check if NFT contract has mint function
echo "🔧 Checking NFT contract mint function..."
MINT_CHECK=$(cast call $ERC721_NFT "mint(address,uint256)" $ADMIN_ADDRESS 1 --rpc-url http://localhost:8545 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ NFT contract has mint function"
else
    echo "❌ NFT contract does not have mint function or call failed"
fi

echo ""
echo "🎯 Correct way to mint NFTs:"
echo "============================="
echo "# Mint NFT to admin address"
echo "cast send $ERC721_NFT \"mint(address,uint256)\" $ADMIN_ADDRESS 1 --rpc-url http://localhost:8545 --private-key $ADMIN_PRIVATE_KEY"
echo ""
echo "# Mint NFT to user address"
echo "cast send $ERC721_NFT \"mint(address,uint256)\" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 2 --rpc-url http://localhost:8545 --private-key $ADMIN_PRIVATE_KEY"
echo ""
echo "❌ WRONG: Don't call mint on NFTMarket contract"
echo "✅ RIGHT: Call mint on ERC721 NFT contract"
