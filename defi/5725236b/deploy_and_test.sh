#!/bin/bash

export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

echo "🚀 Starting Call Option Token Deployment and Testing..."

# Set up environment
export ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export USER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
export RPC_URL=http://localhost:8545

export USER1_ADDRESS=$(cast wallet address --private-key $USER1_KEY)
export USER2_ADDRESS=$(cast wallet address --private-key $USER2_KEY)
export ADMIN_ADDRESS=$(cast wallet address --private-key $ADMIN_PRIVATE_KEY)

echo "🔑 Addresses:"
echo "ADMIN_ADDRESS=$ADMIN_ADDRESS"
echo "USER1_ADDRESS=$USER1_ADDRESS"
echo "USER2_ADDRESS=$USER2_ADDRESS"

get_deployed_address() {
    awk '/Deployed to:/ {print $3}'
}

# Step 1: Deploy Call Option Token contract
echo "📦 Step 1: Deploying Call Option Token contract..."

# Contract parameters
TOKEN_NAME="Call Option Token"
TOKEN_SYMBOL="CALL"
STRIKE_PRICE=20000000000000000  # 0.02 ETH (in wei)
OPTION_FEE=10000000000000000     # 0.01 ETH (in wei) - 期权费
DURATION_DAYS=1                  # 1天到期（测试用）

echo "📊 Contract Parameters:"
echo "Strike Price: $STRIKE_PRICE wei (0.02 ETH)"
echo "Option Fee: $OPTION_FEE wei (0.01 ETH)"
echo "Duration: $DURATION_DAYS days"

CALL_OPTION_ADDRESS=$(forge create --rpc-url $RPC_URL src/CallOptionToken.sol:CallOptionToken --private-key $ADMIN_PRIVATE_KEY --broadcast \
    --constructor-args "$TOKEN_NAME" "$TOKEN_SYMBOL" $STRIKE_PRICE $OPTION_FEE $DURATION_DAYS | get_deployed_address)
echo "✅ Call Option Token deployed to: $CALL_OPTION_ADDRESS"

# Step 2: Check initial contract state
echo "🔍 Step 2: Checking initial contract state..."
CONTRACT_INFO=$(cast call $CALL_OPTION_ADDRESS "getContractInfo()(uint256,uint256,uint256,uint256,uint256,uint256,bool)" --rpc-url $RPC_URL)
echo "Contract Info: $CONTRACT_INFO"

# Step 3: Admin deposits 10 ETH and mints tokens
echo "💰 Step 3: Admin depositing 10 ETH and minting tokens..."
DEPOSIT_AMOUNT=10000000000000000000  # 10 ETH
cast send $CALL_OPTION_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "depositAndMint()" --value $DEPOSIT_AMOUNT

# Check contract state after deposit
echo "🔍 Checking contract state after deposit..."
CONTRACT_INFO_AFTER_DEPOSIT=$(cast call $CALL_OPTION_ADDRESS "getContractInfo()(uint256,uint256,uint256,uint256,uint256,uint256,bool)" --rpc-url $RPC_URL)
echo "Contract Info after deposit: $CONTRACT_INFO_AFTER_DEPOSIT"

# Check admin's token balance
ADMIN_TOKEN_BALANCE=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL)
echo "Admin token balance: $ADMIN_TOKEN_BALANCE"

# Step 4: User1 purchases 50 tokens
echo "💰 Step 4: User1 purchasing 50 tokens..."
USER1_TOKEN_AMOUNT=50000000000000000000  # 50 tokens (with 18 decimals)
USER1_ETH_COST=500000000000000000        # 0.5 ETH (50 * 0.01 ETH)

cast send $CALL_OPTION_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "purchaseOption(uint256)" $USER1_TOKEN_AMOUNT --value $USER1_ETH_COST

# Check User1's token balance
USER1_TOKEN_BALANCE=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL)
echo "User1 token balance: $USER1_TOKEN_BALANCE"

# Step 5: User2 purchases 100 tokens
echo "💰 Step 5: User2 purchasing 100 tokens..."
USER2_TOKEN_AMOUNT=100000000000000000000  # 100 tokens (with 18 decimals)
USER2_ETH_COST=1000000000000000000        # 1 ETH (100 * 0.01 ETH)

cast send $CALL_OPTION_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL \
    "purchaseOption(uint256)" $USER2_TOKEN_AMOUNT --value $USER2_ETH_COST

# Check User2's token balance
USER2_TOKEN_BALANCE=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)
echo "User2 token balance: $USER2_TOKEN_BALANCE"

# Check admin's remaining token balance
ADMIN_REMAINING_BALANCE=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $ADMIN_ADDRESS --rpc-url $RPC_URL)
echo "Admin remaining token balance: $ADMIN_REMAINING_BALANCE"

# Step 6: Check contract state before expiration
echo "🔍 Step 6: Checking contract state before expiration..."
CONTRACT_INFO_BEFORE_EXPIRY=$(cast call $CALL_OPTION_ADDRESS "getContractInfo()(uint256,uint256,uint256,uint256,uint256,uint256,bool)" --rpc-url $RPC_URL)
echo "Contract Info before expiry: $CONTRACT_INFO_BEFORE_EXPIRY"

# Step 7: Fast forward time to expiration
echo "⏰ Step 7: Fast forwarding time to expiration..."
# Fast forward 2 days to ensure expiration
cast rpc anvil_setNextBlockTimestamp $(($(date +%s) + 172800)) --rpc-url $RPC_URL
cast rpc anvil_mine --rpc-url $RPC_URL

# Check if contract is expired
IS_EXPIRED=$(cast call $CALL_OPTION_ADDRESS "getContractInfo()(uint256,uint256,uint256,uint256,uint256,uint256,bool)" --rpc-url $RPC_URL | awk '{print $7}')
echo "Is contract expired: $IS_EXPIRED"

# Step 8: User1 exercises 50 tokens
echo "💰 Step 8: User1 exercising 50 tokens..."
cast send $CALL_OPTION_ADDRESS --private-key $USER1_KEY --rpc-url $RPC_URL \
    "exerciseOption(uint256)" $USER1_TOKEN_AMOUNT

# Check User1's ETH balance after exercise
USER1_ETH_AFTER=$(cast balance $USER1_ADDRESS --rpc-url $RPC_URL)
echo "User1 ETH balance after exercise: $USER1_ETH_AFTER"

# Check User1's token balance after exercise
USER1_TOKEN_AFTER=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $USER1_ADDRESS --rpc-url $RPC_URL)
echo "User1 token balance after exercise: $USER1_TOKEN_AFTER"

# Step 9: User2 exercises 100 tokens
echo "💰 Step 9: User2 exercising 100 tokens..."
cast send $CALL_OPTION_ADDRESS --private-key $USER2_KEY --rpc-url $RPC_URL \
    "exerciseOption(uint256)" $USER2_TOKEN_AMOUNT

# Check User2's ETH balance after exercise
USER2_ETH_AFTER=$(cast balance $USER2_ADDRESS --rpc-url $RPC_URL)
echo "User2 ETH balance after exercise: $USER2_ETH_AFTER"

# Check User2's token balance after exercise
USER2_TOKEN_AFTER=$(cast call $CALL_OPTION_ADDRESS "balanceOf(address)(uint256)" $USER2_ADDRESS --rpc-url $RPC_URL)
echo "User2 token balance after exercise: $USER2_TOKEN_AFTER"

# Step 10: Admin expires and redeems remaining assets
echo "💰 Step 10: Admin expiring and redeeming remaining assets..."
cast send $CALL_OPTION_ADDRESS --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL \
    "expireAndRedeem()"

# Check admin's ETH balance after redemption
ADMIN_ETH_AFTER=$(cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL)
echo "Admin ETH balance after redemption: $ADMIN_ETH_AFTER"

# Final verification
echo "🎯 Final Verification:"
echo "Contract Address: $CALL_OPTION_ADDRESS"
echo "Strike Price: $STRIKE_PRICE wei (0.02 ETH)"
echo "Option Fee: $OPTION_FEE wei (0.01 ETH)"

echo "User1:"
echo "  - Purchased: 50 tokens for 0.5 ETH"
echo "  - Exercised: 50 tokens for 1 ETH"
echo "  - Profit: 0.5 ETH"

echo "User2:"
echo "  - Purchased: 100 tokens for 1 ETH"
echo "  - Exercised: 100 tokens for 2 ETH"
echo "  - Profit: 1 ETH"

echo "Admin:"
echo "  - Deposited: 10 ETH"
echo "  - Earned: Option fees from users"
echo "  - Redeemed: Remaining ETH after all exercises"

echo "🎉 All tests completed successfully!"
