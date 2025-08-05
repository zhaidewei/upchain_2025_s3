#!/bin/bash

# Function to capture deployed address from forge create output
capture_address() {
    local output="$1"
    local address=$(echo "$output" | grep "Deployed to:" | awk '{print $3}')
    echo "$address"
}

# Example usage:
# ERC20_OUTPUT=$(forge create src/A_Erc20Token.sol:Erc20Token --rpc-url http://localhost:8545 --broadcast --private-key $ADMIN_PRIVATE_KEY)
# ERC20_ADDRESS=$(capture_address "$ERC20_OUTPUT")
# echo "ERC20 deployed at: $ERC20_ADDRESS"

# For your current deployment:
echo "📦 Capturing deployed address..."
echo "Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3"
echo "Transaction hash: 0x4be7f0855b17a601bed7c037d1d2505d8d348678ca07fa19e9f8d37f31fb6d3a" # pragma: allowlist secret

# Save to file
echo "ERC20_TOKEN=0x5FbDB2315678afecb367f032d93F642f64180aa3" > deployed_addresses.txt # pragma: allowlist secret
echo "Deployment captured at: $(date)" >> deployed_addresses.txt

echo "✅ Address captured and saved to deployed_addresses.txt"
