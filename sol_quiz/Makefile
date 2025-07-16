# Solidity Bank Contract Makefile

.PHONY: help install compile test lint lint-fix clean deploy-local deploy-sepolia coverage

# Default target
help:
	@echo "Available targets:"
	@echo "  install      - Install dependencies"
	@echo "  compile      - Compile smart contracts"
	@echo "  test         - Run tests"
	@echo "  lint         - Run Solidity linter"
	@echo "  lint-fix     - Run Solidity linter with auto-fix"
	@echo "  clean        - Clean build artifacts"
	@echo "  coverage     - Run test coverage"
	@echo "  deploy-local - Deploy to local network"
	@echo "  deploy-sepolia - Deploy to Sepolia testnet"
	@echo "  node         - Start local Hardhat node"

# Install dependencies
install:
	npm install

# Compile contracts
compile:
	npm run compile

# Run tests
test:
	npm test

# Run tests with gas reporting
test-gas:
	REPORT_GAS=true npm test

# Run Solidity linter
lint:
	npm run lint:sol

# Run Solidity linter with auto-fix
lint-fix:
	npm run lint:sol:fix

# Clean build artifacts
clean:
	npm run clean

# Run test coverage
coverage:
	npm run test:coverage

# Deploy to local network
deploy-local:
	npm run deploy:local

# Deploy to Sepolia testnet
deploy-sepolia:
	npm run deploy:sepolia

# Start local Hardhat node
node:
	npm run node

# Run all quality checks
check: lint test

# Full development workflow
dev: install compile lint test

# CI/CD pipeline
ci: install compile lint test coverage
