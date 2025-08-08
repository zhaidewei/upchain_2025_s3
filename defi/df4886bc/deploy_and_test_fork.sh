#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

# Step 1: Deploy implementation
echo "🚀 Deploying Meme Token Factory..."

# Set up environment
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545
export CHAIN_ID=1 # use fork
export USER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
export USER1_ADDRESS=$(cast wallet address --private-key $USER1_KEY)
export USER2_ADDRESS=$(cast wallet address --private-key $USER2_KEY)
export ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)

echo "ADMIN_PRIVATE_KEY=$ADMIN_PRIVATE_KEY"
echo "USER1_KEY=$USER1_KEY"
echo "USER2_KEY=$USER2_KEY"


get_deployed_address() {
    awk '/Deployed to:/ {print $3}'
}

# Deploy contracts
echo "📦 Deploying implementation and factory..."

ERC20_IMPL_ADDRESS=$(forge create --rpc-url http://localhost:8545 src/Erc20Impl.sol:Erc20Impl --private-key $ADMIN_PRIVATE_KEY --broadcast | get_deployed_address)

echo "ERC20_IMPL_ADDRESS=$ERC20_IMPL_ADDRESS"

export ROUTER_ADDRESS=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

# Step 2: Deploy factory
echo "📦 Deploying factory..."
FACTORY_ADDRESS=$(forge create --rpc-url http://localhost:8545 src/Factory.sol:Factory --private-key $ADMIN_PRIVATE_KEY --broadcast \
--constructor-args $ERC20_IMPL_ADDRESS $ROUTER_ADDRESS | get_deployed_address)

echo "FACTORY_ADDRESS=$FACTORY_ADDRESS"

# Step 3: Deploy proxy using factory
echo "📦 Deploying proxy using factory..."
cast send $FACTORY_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "deployMeme(string, string, uint256, uint256)(address)" "Meme1" "MEME1" 10000000000000000000 100000000000

# Get the deployed proxy address from the transaction receipt
echo "📦 Getting deployed proxy address..."
PROXY_ADDRESS=$(cast call $FACTORY_ADDRESS "allMemes(uint256)(address)" 0 --rpc-url $RPC_URL)

echo "PROXY_ADDRESS=$PROXY_ADDRESS"

# Step 3.5: Authorize Router to spend tokens (for liquidity provision)
echo "🔐 Authorizing Router to spend tokens for liquidity provision..."
echo "Token owner (USER1) authorizes Router to spend tokens..."
cast send $PROXY_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)(bool)" $ROUTER_ADDRESS 1000000000000000000000000

echo "Router authorization completed"

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

# Token owner (USER1) authorizes Factory to spend tokens for liquidity provision
echo "🔐 Token owner (USER1) authorizes Factory to spend tokens for liquidity provision..."
cast send $PROXY_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "approve(address,uint256)(bool)" $FACTORY_ADDRESS 1000000000000000000000000

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

echo "ADMIN ETH balance after minting (should have received 5% fee):"
cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL

echo "USER1 ETH balance after minting (should have received 95% fee):"
cast balance $USER1_ADDRESS --rpc-url $RPC_URL


# Test buyMeme functionality
echo "🧪 Testing buyMeme functionality..."

# Get WETH address from router
WETH_ADDRESS=$(cast call $ROUTER_ADDRESS "WETH()(address)" --rpc-url $RPC_URL)
echo "WETH_ADDRESS=$WETH_ADDRESS"

# Get Uniswap V2 Factory address from router
FACTORY_V2_ADDRESS=$(cast call $ROUTER_ADDRESS "factory()(address)" --rpc-url $RPC_URL)
echo "FACTORY_V2_ADDRESS=$FACTORY_V2_ADDRESS"

echo "Checking if liquidity pool exists..."
# Check if there's a pair for this token
PAIR_ADDRESS=$(cast call $FACTORY_V2_ADDRESS "getPair(address,address)(address)" $WETH_ADDRESS $PROXY_ADDRESS --rpc-url $RPC_URL)
echo "Pair address: $PAIR_ADDRESS"

if [ "$PAIR_ADDRESS" != "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ Liquidity pool exists, testing buyMeme..."

    # Test buyMeme with a small amount
    BUY_AMOUNT=10000000000 # 0.01 ETH
    echo "Testing buyMeme with $BUY_AMOUNT wei..."

    # Print USER2 token balance before buyMeme
    echo "💰 USER2 token balance BEFORE buyMeme:"
    USER2_BALANCE_BEFORE=$(cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)
    echo "$USER2_BALANCE_BEFORE"

    BUY_RESULT=$(cast send $PROXY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "buyMeme(address)()" $ROUTER_ADDRESS --value $BUY_AMOUNT 2>&1)

    if [ $? -eq 0 ]; then
        echo "✅ buyMeme transaction sent successfully!"

        # Print USER2 token balance after buyMeme
        echo "💰 USER2 token balance AFTER buyMeme:"
        USER2_BALANCE_AFTER=$(cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)
        echo "$USER2_BALANCE_AFTER"

        # Calculate the difference
        echo "📈 Tokens gained from buyMeme:"
        echo "$USER2_BALANCE_AFTER - $USER2_BALANCE_BEFORE"
    else
        echo "❌ buyMeme failed:"
        echo "$BUY_RESULT"

        # Try to understand why it failed by checking the current price
        echo "🔍 Analyzing price comparison..."
        echo "Mint price: $(cast call $PROXY_ADDRESS "price()(uint256)" --rpc-url $RPC_URL)"
        echo "Per mint amount: $(cast call $PROXY_ADDRESS "perMint()(uint256)" --rpc-url $RPC_URL)"

        # Calculate what we would get from minting
        MINT_PRICE=$(cast call $PROXY_ADDRESS "price()(uint256)" --rpc-url $RPC_URL | cut -d'[' -f1)
        PER_MINT=$(cast call $PROXY_ADDRESS "perMint()(uint256)" --rpc-url $RPC_URL | cut -d'[' -f1)
        echo "Mint price (raw): $MINT_PRICE"
        echo "Per mint amount (raw): $PER_MINT"

        # Use bc for precise arithmetic with large numbers
        MINT_TOKENS=$(echo "scale=0; $BUY_AMOUNT * $PER_MINT / $MINT_PRICE" | bc)
        echo "If we minted with $BUY_AMOUNT wei, we would get $MINT_TOKENS tokens"

        # Try to get Uniswap price (this might fail if no liquidity)
        echo "Trying to get Uniswap price..."
        UNISWAP_PRICE_RESULT=$(cast call $ROUTER_ADDRESS "getAmountsOut(uint256,address[])(uint256[])" $BUY_AMOUNT "[$WETH_ADDRESS, $PROXY_ADDRESS]" --rpc-url $RPC_URL 2>&1)
        echo "Uniswap price result: $UNISWAP_PRICE_RESULT"

        # Let's also try a smaller amount to see if that works
        echo "Trying with a smaller amount..."
        SMALLER_AMOUNT=1000000000 # 0.001 ETH
        echo "Testing buyMeme with $SMALLER_AMOUNT wei..."

        SMALLER_BUY_RESULT=$(cast send $PROXY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "buyMeme(address)()" $ROUTER_ADDRESS --value $SMALLER_AMOUNT 2>&1)

        if [ $? -eq 0 ]; then
            echo "✅ buyMeme with smaller amount succeeded!"
        else
            echo "❌ buyMeme with smaller amount also failed:"
            echo "$SMALLER_BUY_RESULT"
        fi

        # Let's try with a much larger amount to see if that makes the Uniswap price better
        echo "Trying with a much larger amount to test price improvement..."
        LARGER_AMOUNT=100000000000000 # 0.1 ETH (same as mint price)
        echo "Testing buyMeme with $LARGER_AMOUNT wei (same as mint price)..."

        LARGER_BUY_RESULT=$(cast send $PROXY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL "buyMeme(address)()" $ROUTER_ADDRESS --value $LARGER_AMOUNT 2>&1)

        if [ $? -eq 0 ]; then
            echo "✅ buyMeme with larger amount succeeded!"
        else
            echo "❌ buyMeme with larger amount also failed:"
            echo "$LARGER_BUY_RESULT"
        fi
    fi
else
    echo "⚠️ No liquidity pool exists yet, skipping buyMeme test"
fi

echo "🎉 All tests completed successfully!"
