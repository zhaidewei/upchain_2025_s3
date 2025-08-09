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
export USER3_KEY=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
export USER1_ADDRESS=$(cast wallet address --private-key $USER1_KEY)
export USER2_ADDRESS=$(cast wallet address --private-key $USER2_KEY)
export USER3_ADDRESS=$(cast wallet address --private-key $USER3_KEY)
export ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)

echo "ADMIN_PRIVATE_KEY=$ADMIN_PRIVATE_KEY"
echo "USER1_KEY=$USER1_KEY"
echo "USER2_KEY=$USER2_KEY"
echo "USER3_KEY=$USER3_KEY"


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

echo "USER3 balance:"
cast balance $USER3_ADDRESS --rpc-url $RPC_URL

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

                # Read cumulative prices directly from the pair BEFORE buyMeme
        echo "📈 Reading cumulative prices BEFORE buyMeme..."
        PRICE0_BEFORE_RAW=$(cast call $PAIR_ADDRESS "price0CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        PRICE1_BEFORE_RAW=$(cast call $PAIR_ADDRESS "price1CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        RESERVES_BEFORE=$(cast call $PAIR_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
        TIMESTAMP_BEFORE_RAW=$(echo $RESERVES_BEFORE | cut -d' ' -f3)
        BLOCK_BEFORE=$(cast block-number --rpc-url $RPC_URL)

        # Extract numeric values (remove scientific notation part)
        PRICE0_BEFORE=$(echo $PRICE0_BEFORE_RAW | cut -d' ' -f1)
        PRICE1_BEFORE=$(echo $PRICE1_BEFORE_RAW | cut -d' ' -f1)
        TIMESTAMP_BEFORE=$(echo $TIMESTAMP_BEFORE_RAW | cut -d' ' -f1)

    echo "Price0 cumulative before: $PRICE0_BEFORE"
    echo "Price1 cumulative before: $PRICE1_BEFORE"
    echo "Block timestamp before: $TIMESTAMP_BEFORE"
    echo "Block number before: $BLOCK_BEFORE"

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

        # Add some delay to ensure time passes for TWAP calculation
        echo "⏳ Waiting a moment for time to pass..."
        sleep 2

                # Mine a new block to update timestamps
        cast send $USER2_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL --value 0 > /dev/null 2>&1

        # Read cumulative prices directly from the pair AFTER buyMeme
        echo "📈 Reading cumulative prices AFTER buyMeme..."
        PRICE0_AFTER_RAW=$(cast call $PAIR_ADDRESS "price0CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        PRICE1_AFTER_RAW=$(cast call $PAIR_ADDRESS "price1CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        RESERVES_AFTER=$(cast call $PAIR_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
        TIMESTAMP_AFTER_RAW=$(echo $RESERVES_AFTER | cut -d' ' -f3)
        BLOCK_AFTER=$(cast block-number --rpc-url $RPC_URL)

        # Extract numeric values (remove scientific notation part)
        PRICE0_AFTER=$(echo $PRICE0_AFTER_RAW | cut -d' ' -f1)
        PRICE1_AFTER=$(echo $PRICE1_AFTER_RAW | cut -d' ' -f1)
        TIMESTAMP_AFTER=$(echo $TIMESTAMP_AFTER_RAW | cut -d' ' -f1)

        echo "Price0 cumulative after: $PRICE0_AFTER"
        echo "Price1 cumulative after: $PRICE1_AFTER"
        echo "Block timestamp after: $TIMESTAMP_AFTER"
        echo "Block number after: $BLOCK_AFTER"

                # Calculate TWAP price manually using cumulative price differences
        echo "🧮 Calculating TWAP price manually..."

        # Determine which token is the meme token in the pair
        TOKEN0=$(cast call $PAIR_ADDRESS "token0()(address)" --rpc-url $RPC_URL)
        TOKEN1=$(cast call $PAIR_ADDRESS "token1()(address)" --rpc-url $RPC_URL)

        echo "Token0 in pair: $TOKEN0"
        echo "Token1 in pair: $TOKEN1"
        echo "Meme token: $PROXY_ADDRESS"

        # Calculate time elapsed
        TIME_ELAPSED=$((TIMESTAMP_AFTER - TIMESTAMP_BEFORE))
        echo "Time elapsed: $TIME_ELAPSED seconds"
        echo "Blocks elapsed: $((BLOCK_AFTER - BLOCK_BEFORE))"

                if [ "$TIME_ELAPSED" -gt 0 ]; then
            # Show price changes (using bc for large number arithmetic)
            echo "📊 Price Changes:"
            PRICE0_CHANGE=$(echo "$PRICE0_AFTER - $PRICE0_BEFORE" | bc -l)
            PRICE1_CHANGE=$(echo "$PRICE1_AFTER - $PRICE1_BEFORE" | bc -l)
            echo "Price0 cumulative change: $PRICE0_CHANGE"
            echo "Price1 cumulative change: $PRICE1_CHANGE"

            if [ "$TOKEN0" = "$PROXY_ADDRESS" ]; then
                echo "Meme token is token0, calculating TWAP..."
                # TWAP = (price0CumulativeAfter - price0CumulativeBefore) / timeElapsed
                TWAP_RESULT=$(echo "scale=0; $PRICE0_CHANGE / $TIME_ELAPSED" | bc -l)
                echo "🎯 TWAP Price for meme token (as token0): $TWAP_RESULT"
                echo "   (This is the average price of token0 in terms of token1 over the time period)"
            elif [ "$TOKEN1" = "$PROXY_ADDRESS" ]; then
                echo "Meme token is token1, calculating TWAP..."
                # TWAP = (price1CumulativeAfter - price1CumulativeBefore) / timeElapsed
                TWAP_RESULT=$(echo "scale=0; $PRICE1_CHANGE / $TIME_ELAPSED" | bc -l)
                echo "🎯 TWAP Price for meme token (as token1): $TWAP_RESULT"
                echo "   (This is the average price of token1 in terms of token0 over the time period)"
            else
                echo "⚠️ Meme token not found in pair"
            fi

            echo ""
            echo "📋 TWAP Explanation:"
            echo "   - Cumulative prices accumulate over time in Uniswap V2"
            echo "   - TWAP = (CumulativePriceEnd - CumulativePriceStart) / TimeElapsed"
            echo "   - This gives us the time-weighted average price over the period"
            echo "   - The price is in UQ112x112 format (fixed point with 112 fractional bits)"
        else
            echo "⚠️ No time elapsed, cannot calculate TWAP"
        fi

                # Additional trading activity to demonstrate multiple transactions at different times
        echo ""
        echo "🔄 Performing additional trades to show price changes over time..."

        # Wait and mine blocks to simulate time passing
        echo "⏳ Waiting for time to pass..."
        sleep 3
        cast send $USER3_ADDRESS --private-key $USER3_KEY --rpc-url $RPC_URL --value 0 > /dev/null 2>&1

        # Read prices before USER3 trade
        echo "📈 Prices before USER3 trade:"
        PRICE0_BEFORE_USER3_RAW=$(cast call $PAIR_ADDRESS "price0CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        PRICE1_BEFORE_USER3_RAW=$(cast call $PAIR_ADDRESS "price1CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        RESERVES_BEFORE_USER3=$(cast call $PAIR_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
        TIMESTAMP_BEFORE_USER3_RAW=$(echo $RESERVES_BEFORE_USER3 | cut -d' ' -f3)

        # Extract numeric values
        PRICE0_BEFORE_USER3=$(echo $PRICE0_BEFORE_USER3_RAW | cut -d' ' -f1)
        PRICE1_BEFORE_USER3=$(echo $PRICE1_BEFORE_USER3_RAW | cut -d' ' -f1)
        TIMESTAMP_BEFORE_USER3=$(echo $TIMESTAMP_BEFORE_USER3_RAW | cut -d' ' -f1)

        # USER3 makes a trade
        echo "🛒 USER3 buying meme tokens..."
        BUY_AMOUNT_USER3=5000000000 # 0.005 ETH
        cast send $PROXY_ADDRESS --private-key $USER3_KEY --rpc-url $RPC_URL \
            "buyMeme(address)()" $ROUTER_ADDRESS --value $BUY_AMOUNT_USER3

        echo "💰 USER3 token balance after trade:"
        cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER3_ADDRESS --rpc-url $RPC_URL

        # Wait again and mine more blocks
        echo "⏳ Waiting for more time to pass..."
        sleep 2
        cast send $USER1_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL --value 0 > /dev/null 2>&1

        # USER2 makes another trade
        echo "🛒 USER2 making second trade..."
        BUY_AMOUNT_USER2_2=15000000000 # 0.015 ETH
        cast send $PROXY_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL \
            "buyMeme(address)()" $ROUTER_ADDRESS --value $BUY_AMOUNT_USER2_2

        echo "💰 USER2 final token balance:"
        cast call $PROXY_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL

        # Read final prices after all trades
        echo "📈 Final cumulative prices after all trades:"
        PRICE0_FINAL_RAW=$(cast call $PAIR_ADDRESS "price0CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        PRICE1_FINAL_RAW=$(cast call $PAIR_ADDRESS "price1CumulativeLast()(uint256)" --rpc-url $RPC_URL)
        RESERVES_FINAL=$(cast call $PAIR_ADDRESS "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL)
        TIMESTAMP_FINAL_RAW=$(echo $RESERVES_FINAL | cut -d' ' -f3)

        # Extract numeric values
        PRICE0_FINAL=$(echo $PRICE0_FINAL_RAW | cut -d' ' -f1)
        PRICE1_FINAL=$(echo $PRICE1_FINAL_RAW | cut -d' ' -f1)
        TIMESTAMP_FINAL=$(echo $TIMESTAMP_FINAL_RAW | cut -d' ' -f1)

        # Calculate TWAP for the entire period (from first observation to final)
        echo ""
        echo "🧮 Calculating TWAP for the entire trading period..."
        TOTAL_TIME_ELAPSED=$((TIMESTAMP_FINAL - TIMESTAMP_BEFORE))
        echo "Total time elapsed: $TOTAL_TIME_ELAPSED seconds"

                 if [ "$TOTAL_TIME_ELAPSED" -gt 0 ]; then
             TOTAL_PRICE0_CHANGE=$(echo "$PRICE0_FINAL - $PRICE0_BEFORE" | bc -l)
             TOTAL_PRICE1_CHANGE=$(echo "$PRICE1_FINAL - $PRICE1_BEFORE" | bc -l)

             echo "📊 Total Price Changes Over Entire Period:"
             echo "Price0 total cumulative change: $TOTAL_PRICE0_CHANGE"
             echo "Price1 total cumulative change: $TOTAL_PRICE1_CHANGE"

             if [ "$TOKEN0" = "$PROXY_ADDRESS" ]; then
                 TOTAL_TWAP=$(echo "scale=0; $TOTAL_PRICE0_CHANGE / $TOTAL_TIME_ELAPSED" | bc -l)
                 echo "🎯 Overall TWAP for meme token (entire period): $TOTAL_TWAP"

                 # Convert to human-readable price
                 UQ112_DIVISOR="5192296858534827628530496329220096"
                 READABLE_PRICE=$(echo "scale=18; $TOTAL_TWAP / $UQ112_DIVISOR" | bc -l)
                 echo "   💰 Human-readable: 1 MEME = $READABLE_PRICE ETH"

             elif [ "$TOKEN1" = "$PROXY_ADDRESS" ]; then
                 TOTAL_TWAP=$(echo "scale=0; $TOTAL_PRICE1_CHANGE / $TOTAL_TIME_ELAPSED" | bc -l)
                 echo "🎯 Overall TWAP for meme token (entire period): $TOTAL_TWAP"

                 # Convert to human-readable price (token1 TWAP gives ETH price in meme tokens, need inverse)
                 UQ112_DIVISOR="5192296858534827628530496329220096"
                 ETH_IN_MEME=$(echo "scale=18; $TOTAL_TWAP / $UQ112_DIVISOR" | bc -l)
                 if [ "$ETH_IN_MEME" != "0" ]; then
                     MEME_PRICE_IN_ETH=$(echo "scale=18; 1 / $ETH_IN_MEME" | bc -l)
                     echo "   💰 Human-readable: 1 MEME = $MEME_PRICE_IN_ETH ETH"
                 fi
             fi

                                      echo ""
             echo "📊 Summary of all price readings:"
             echo "Initial: Price0=$PRICE0_BEFORE, Price1=$PRICE1_BEFORE, Time=$TIMESTAMP_BEFORE"
             echo "After 1st trade: Price0=$PRICE0_AFTER, Price1=$PRICE1_AFTER, Time=$TIMESTAMP_AFTER"
             echo "Final: Price0=$PRICE0_FINAL, Price1=$PRICE1_FINAL, Time=$TIMESTAMP_FINAL"
         fi

    else
        echo "❌ buyMeme failed:"
        echo "$BUY_RESULT"
    fi
else
    echo "⚠️ No liquidity pool exists yet, skipping buyMeme test"
fi

echo "🎉 All tests completed successfully!"
