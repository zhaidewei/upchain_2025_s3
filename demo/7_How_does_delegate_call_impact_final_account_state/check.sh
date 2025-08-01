#!/bin/bash
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
echo "🚀 Running Delegate Call Demo"
echo "=============================="

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry is not installed. Please install it first."
    exit 1
fi

# Install dependencies if needed
echo "📦 Installing dependencies..."

# Deploy CounterA and ProxyB
export private_key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy CounterA and capture its address
echo "Deploying CounterA..."
COUNTERA_ADDRESS=$(forge create src/CounterA.sol:CounterA --rpc-url http://localhost:8545 --private-key $private_key --broadcast | grep "Deployed to:" | awk '{print $3}')
echo "CounterA deployed at: $COUNTERA_ADDRESS"

# Deploy ProxyB with the actual CounterA address
echo "Deploying ProxyB..."
PROXYB_ADDRESS=$(forge create src/ProxyB.sol:ProxyB --rpc-url http://localhost:8545 --broadcast --private-key $private_key --constructor-args $COUNTERA_ADDRESS | grep "Deployed to:" | awk '{print $3}')
echo "ProxyB deployed at: $PROXYB_ADDRESS"

# Get initial counters
echo "Initial state:"
echo "CounterA counter:"
cast call $COUNTERA_ADDRESS "getCounter()(uint256)" --rpc-url http://localhost:8545

echo "ProxyB counter:"
cast call $PROXYB_ADDRESS "getCounter()(uint256)" --rpc-url http://localhost:8545

# Call increment via delegate call
echo "Calling incrementViaDelegateCall()..."
cast send $PROXYB_ADDRESS "incrementViaDelegateCall(address)" $COUNTERA_ADDRESS --rpc-url http://localhost:8545 --private-key $private_key

# Get counters after delegate call
echo "After delegate call:"
echo "CounterA counter:"
cast call $COUNTERA_ADDRESS "getCounter()(uint256)" --rpc-url http://localhost:8545

# echo "ProxyB counter:"
# cast call $PROXYB_ADDRESS "getCounter()(uint256)" --rpc-url http://localhost:8545

# echo "ProxyB targetContract:"
# cast call $PROXYB_ADDRESS "gettargetContract()(address)" --rpc-url http://localhost:8545
