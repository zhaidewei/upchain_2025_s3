#!/bin/bash

echo "🚀 Starting TokenBank Frontend Development Environment"
echo "=================================================="

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if Anvil is running
echo "🔍 Checking if Anvil is running on localhost:8545..."
if curl -s http://localhost:8545 > /dev/null; then
    echo "✅ Anvil is running on localhost:8545"
else
    echo "⚠️  Anvil is not running on localhost:8545"
    echo "   Please start Anvil with: anvil"
    echo "   Or in another terminal: forge anvil"
fi

# Check if contracts are deployed
echo "🔍 Checking contract deployment..."
if curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0x5FbDB2315678afecb367f032d93F642f64180aa3","latest"],"id":1}' \
    http://localhost:8545 | grep -q '"result":"0x"' || curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0x5FbDB2315678afecb367f032d93F642f64180aa3","latest"],"id":1}' | grep -q '"error"'; then
    echo "⚠️  Token contract may not be deployed at 0x5FbDB2315678afecb367f032d93F642f64180aa3"
    echo "   Please deploy contracts first"
else
    echo "✅ Token contract appears to be deployed"
fi

echo ""
echo "🌐 Starting development server..."
echo "   The app will be available at: http://localhost:5173"
echo "   Make sure to:"
echo "   1. Connect MetaMask to Anvil network (Chain ID: 31337)"
echo "   2. Import an account with ETH balance"
echo "   3. Check the debug panel for detailed information"
echo ""

npm run dev
