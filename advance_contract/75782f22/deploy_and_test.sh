#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

# Step 1: Deploy implementation
echo "🚀 Deploying Meme Token Factory..."

# Set up environment
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545
export CHAIN_ID=1337
export USER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

echo "ADMIN_PRIVATE_KEY=$ADMIN_PRIVATE_KEY"
echo "USER1_KEY=$USER1_KEY"
echo "USER2_KEY=$USER2_KEY"

# Deploy contracts
echo "📦 Deploying implementation and factory..."
ERC20_IMPL_ADDRESS=$(forge create --rpc-url http://localhost:8545 src/Erc20Impl.sol:Erc20Impl --private-key $ADMIN_PRIVATE_KEY --broadcast | awk '/Deployed to:/ {print $3}')

echo "ERC20_IMPL_ADDRESS=$ERC20_IMPL_ADDRESS"

# Step 2: Deploy factory
echo "📦 Deploying factory..."
FACTORY_ADDRESS=$(forge create --rpc-url http://localhost:8545 src/Factory.sol:Factory --private-key $ADMIN_PRIVATE_KEY --broadcast \
--constructor-args $ERC20_IMPL_ADDRESS | awk '/Deployed to:/ {print $3}')

echo "FACTORY_ADDRESS=$FACTORY_ADDRESS"

# Step 3: Deploy proxy using factory
echo "📦 Deploying proxy using factory..."
cast send $FACTORY_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "deployMeme(string, string, uint256, uint256)(address)" "Meme1" "MEME1" 10 100000000000

# Get the deployed proxy address from the transaction receipt
echo "📦 Getting deployed proxy address..."
PROXY_ADDRESS=$(cast call $FACTORY_ADDRESS "allMemes(uint256)(address)" 0 --rpc-url $RPC_URL)

echo "PROXY_ADDRESS=$PROXY_ADDRESS"

# Test the deployed proxy
echo "🧪 Testing the deployed proxy..."
echo "Calling decimals() on proxy:"
cast call $PROXY_ADDRESS "decimals()(uint8)" --rpc-url $RPC_URL

echo "Calling name() on proxy:"
cast call $PROXY_ADDRESS "name()(string)" --rpc-url $RPC_URL

echo "Calling symbol() on proxy:"
cast call $PROXY_ADDRESS "symbol()(string)" --rpc-url $RPC_URL

echo "Calling perMint() on proxy:"
cast call $PROXY_ADDRESS "perMint()(uint256)" --rpc-url $RPC_URL

echo "Calling price() on proxy:"
cast call $PROXY_ADDRESS "price()(uint256)" --rpc-url $RPC_URL

echo "Calling factory() on proxy:"
cast call $PROXY_ADDRESS "factory()(address)" --rpc-url $RPC_URL

echo "Calling owner() on proxy:"
cast call $PROXY_ADDRESS "owner()(address)" --rpc-url $RPC_URL

echo "Calling totalSupply() on proxy (should be 0 initially):"
cast call $PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL

# Get user addresses
USER1_ADDRESS=$(cast wallet address --private-key $USER1_KEY)
USER2_ADDRESS=$(cast wallet address --private-key $USER2_KEY)
ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)

echo "USER1_ADDRESS=$USER1_ADDRESS"
echo "USER2_ADDRESS=$USER2_ADDRESS"
echo "ADMIN_ADDRESS=$ADMIN_ADDRESS"

# Check initial balances
echo "💰 Checking initial balances..."
echo "USER1 balance:"
cast balance $USER1_ADDRESS --rpc-url $RPC_URL

echo "USER2 balance:"
cast balance $USER2_ADDRESS --rpc-url $RPC_URL

echo "ADMIN balance:"
cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL

# Test minting with USER2
echo "🪙 Testing minting with USER2..."
echo "USER2 mints tokens from the deployed meme token..."

# Get the price for minting
TOKEN_PRICE=$(cast call $PROXY_ADDRESS "price()(uint256)" --rpc-url $RPC_URL)
echo "Token price: $TOKEN_PRICE wei"

# Check token state before minting
echo "Token state before minting:"
echo "Total supply: $(cast call $PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)"
echo "Per mint amount: $(cast call $PROXY_ADDRESS "perMint()(uint256)" --rpc-url $RPC_URL)"
echo "Factory address: $(cast call $PROXY_ADDRESS "factory()(address)" --rpc-url $RPC_URL)"
echo "Expected factory: $FACTORY_ADDRESS"

# USER2 mints tokens with better error handling
echo "Attempting to mint tokens..."
MINT_RESULT=$(cast send $FACTORY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "mintMeme(address)()" $PROXY_ADDRESS --value $TOKEN_PRICE 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ USER2 successfully minted tokens!"
else
    echo "❌ Minting failed:"
    echo "$MINT_RESULT"
fi

# Check balances after minting
echo "💰 Checking balances after minting..."
echo "USER2 token balance:"
cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL

echo "Total supply after minting:"
cast call $PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL

echo "USER2 ETH balance after minting:"
cast balance $USER2_ADDRESS --rpc-url $RPC_URL

echo "ADMIN ETH balance after minting (should have received 1% fee):"
cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL

echo "USER1 ETH balance after minting (should have received 99% fee):"
cast balance $USER1_ADDRESS --rpc-url $RPC_URL

# Test direct minting (this should fail since only factory can mint)
echo "🧪 Testing direct minting (should fail)..."
DIRECT_MINT_RESULT=$(cast send $PROXY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "mint(address)()" $USER2_ADDRESS 2>&1)

if [ $? -eq 0 ]; then
    echo "❌ Direct minting succeeded (should have failed)"
else
    echo "✅ Direct minting correctly failed:"
    echo "$DIRECT_MINT_RESULT"
fi

# Test minting from factory (this should work)
echo "🧪 Testing minting from factory with correct parameters..."
echo "Checking if factory can mint directly..."

# Get the perMint amount
PER_MINT=$(cast call $PROXY_ADDRESS "perMint()(uint256)" --rpc-url $RPC_URL)
echo "Per mint amount: $PER_MINT"

# Test direct mint call from factory (this should work)
echo "Testing direct mint call from factory..."
echo "Factory address: $FACTORY_ADDRESS"
echo "Token factory: $(cast call $PROXY_ADDRESS "factory()(address)" --rpc-url $RPC_URL)"

# Try calling mint through the factory's mintMeme function but with 0 value
FACTORY_MINT_RESULT=$(cast send $FACTORY_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL "mintMeme(address)()" $PROXY_ADDRESS --value $TOKEN_PRICE 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Factory direct mint succeeded!"
    echo "ADMIN token balance after factory mint:"
    cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL
    echo "Total supply after factory mint:"
    cast call $PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL
else
    echo "❌ Factory direct mint failed:"
    echo "$FACTORY_MINT_RESULT"
fi

# Test the second mint
echo "🪙 Testing second mint by USER2..."
echo "Testing mintMeme with correct parameters..."

# Test mintMeme with correct payment
echo "Testing mintMeme with correct parameters..."
echo "USER2 address: $USER2_ADDRESS"
echo "Token address: $PROXY_ADDRESS"
echo "Factory address: $FACTORY_ADDRESS"
echo "Token price: $TOKEN_PRICE"

# Test mintMeme and capture the full result
MINT_MEME_RESULT=$(cast send $FACTORY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "mintMeme(address)()" $PROXY_ADDRESS --value $TOKEN_PRICE 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ USER2 mintMeme transaction sent successfully!"
    echo "Result: $MINT_MEME_RESULT"

    # Wait a moment for the transaction to be processed
    sleep 2

    echo "USER2 token balance after mintMeme:"
    cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL
    echo "Total supply after mintMeme:"
    cast call $PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL
else
    echo "❌ USER2 mintMeme failed:"
    echo "$MINT_MEME_RESULT"
fi

# Test error cases
echo "🧪 Testing error cases..."

echo "Testing minting with wrong price (should fail):"
cast send $FACTORY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "mintMeme(address)()" $PROXY_ADDRESS --value 50000000000 || echo "✅ Correctly failed with wrong price"

echo "Testing minting from wrong factory (should fail):"
# Deploy a different factory
WRONG_FACTORY=$(forge create --rpc-url http://localhost:8545 src/Factory.sol:Factory --private-key $ADMIN_PRIVATE_KEY --broadcast \
--constructor-args $ERC20_IMPL_ADDRESS | awk '/Deployed to:/ {print $3}')

cast send $WRONG_FACTORY --private-key $USER2_KEY --rpc-url $RPC_URL "mintMeme(address)()" $PROXY_ADDRESS --value $TOKEN_PRICE || echo "✅ Correctly failed with wrong factory"

echo "🎉 All tests completed successfully!"
