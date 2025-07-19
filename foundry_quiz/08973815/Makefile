# NFT Market Makefile

.PHONY: help install build test deploy-local clean anvil

# Default target
help:
	@echo "Available targets:"
	@echo "  install      - Install dependencies"
	@echo "  build        - Build contracts"
	@echo "  test         - Run all tests"
	@echo "  test-verbose - Run tests with verbose output"
	@echo "  deploy-local - Deploy to local Anvil network"
	@echo "  anvil        - Start local Anvil network"
	@echo "  clean        - Clean build artifacts"

# Install dependencies
install:
	forge install

# Build contracts
build:
	forge build

# Run tests
test:
	forge test

# Run tests with verbose output
test-verbose:
	forge test -vvv

# Run specific test
test-match:
	forge test --match-test $(TEST)

# Deploy to local Anvil network
deploy-local:
	@echo "🚀 Deploying to local Anvil..."
	@if ! pgrep -f "anvil" > /dev/null; then \
		echo "❌ Anvil is not running! Please start it with 'make anvil' in another terminal"; \
		exit 1; \
	fi
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url local \
		--account anvil-tester \
		--password ''  \
		--broadcast

# Start local Anvil network
anvil:
	@echo "🔥 Starting Anvil local network..."
	anvil --host 0.0.0.0

# Clean build artifacts
clean:
	forge clean

# Generate gas report
gas-report:
	forge test --gas-report

# Run coverage
coverage:
	forge coverage

# Format code
fmt:
	forge fmt

# Check code formatting
fmt-check:
	forge fmt --check

# Run deployment script with full output
deploy-full:
	chmod +x deploy_local.sh
	./deploy_local.sh

# Quick deployment commands
ANVIL_RPC = http://localhost:8545
DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ALICE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
BOB_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# Example interaction commands (replace addresses with actual deployed addresses)
example-list-nft:
	@echo "Example: Alice lists NFT #1 for 100 tokens"
	@echo "Replace <NFT_ADDRESS> and <MARKET_ADDRESS> with actual addresses:"
	@echo "cast send <NFT_ADDRESS> \"approve(address,uint256)\" <MARKET_ADDRESS> 1 --rpc-url $(ANVIL_RPC) --private-key $(ALICE_KEY)"
	@echo "cast send <MARKET_ADDRESS> \"list(uint256,uint256)\" 1 100000000000000000000 --rpc-url $(ANVIL_RPC) --private-key $(ALICE_KEY)"

example-buy-nft:
	@echo "Example: Bob buys NFT #1"
	@echo "Replace <TOKEN_ADDRESS> and <MARKET_ADDRESS> with actual addresses:"
	@echo "cast send <TOKEN_ADDRESS> \"approve(address,uint256)\" <MARKET_ADDRESS> 100000000000000000000 --rpc-url $(ANVIL_RPC) --private-key $(BOB_KEY)"
	@echo "cast send <MARKET_ADDRESS> \"buyNft(uint256)\" 1 --rpc-url $(ANVIL_RPC) --private-key $(BOB_KEY)"

example-buy-callback:
	@echo "Example: Bob buys NFT #1 with callback"
	@echo "Replace <TOKEN_ADDRESS> and <MARKET_ADDRESS> with actual addresses:"
	@echo "cast send <TOKEN_ADDRESS> \"transferWithCallback(address,uint256,bytes)\" <MARKET_ADDRESS> 100000000000000000000 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url $(ANVIL_RPC) --private-key $(BOB_KEY)"
