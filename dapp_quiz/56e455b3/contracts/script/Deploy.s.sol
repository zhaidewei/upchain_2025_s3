// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Erc20Token} from "../src/Erc20Token.sol";
import {TokenBank} from "../src/TokenBank.sol";

/**
 * @title Deployment Script
 * @dev Deploys ERC20Token and TokenBank contracts
 *
 * Usage:
 * 1. Local deployment (Anvil):
 *    forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
 *
 * 2. Testnet deployment (e.g., Sepolia):
 *    forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * 3. Mainnet deployment:
 *    forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract DeployScript is Script {
    // Token configuration
    string constant TOKEN_NAME = "DApp Quiz Token";
    string constant TOKEN_SYMBOL = "DQT";
    uint8 constant TOKEN_DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1000000 * 10**TOKEN_DECIMALS; // 1M tokens

    // Deployment addresses (will be set after deployment)
    Erc20Token public token;
    TokenBank public bank;

    function run() external {
        // Get deployer private key from environment or use default for local testing
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get deployer address
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deployment Configuration ===");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance / 1e18, "ETH");
        console.log("Chain ID:", block.chainid);
        console.log("");

        // Deploy ERC20 Token
        console.log("=== Deploying ERC20 Token ===");
        token = new Erc20Token(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOTAL_SUPPLY);

        console.log("Token deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token decimals:", token.decimals());
        console.log("Total supply:", token.totalSupply() / 10**TOKEN_DECIMALS, "tokens");
        console.log("Deployer token balance:", token.balanceOf(deployer) / 10**TOKEN_DECIMALS, "tokens");
        console.log("");

        // Deploy TokenBank
        console.log("=== Deploying TokenBank ===");
        bank = new TokenBank();

        console.log("TokenBank deployed at:", address(bank));
        console.log("TokenBank admin:", bank.admin());
        console.log("TokenBank balance:", bank.getContractBalance());
        console.log("TokenBank depositors count:", bank.getDepositorsCount());
        console.log("");

        // Stop broadcasting
        vm.stopBroadcast();

        // Post-deployment verification
        console.log("=== Post-Deployment Verification ===");
        verifyDeployment();

        // Print deployment summary
        printDeploymentSummary();
    }

    /**
     * @dev Verify that contracts are deployed correctly
     */
    function verifyDeployment() internal view {
        // Verify token deployment
        require(address(token) != address(0), "Token deployment failed");
        require(keccak256(bytes(token.name())) == keccak256(bytes(TOKEN_NAME)), "Token name mismatch");
        require(keccak256(bytes(token.symbol())) == keccak256(bytes(TOKEN_SYMBOL)), "Token symbol mismatch");
        require(token.decimals() == TOKEN_DECIMALS, "Token decimals mismatch");
        require(token.totalSupply() == TOTAL_SUPPLY, "Token total supply mismatch");

        // Verify bank deployment
        require(address(bank) != address(0), "Bank deployment failed");
        require(bank.admin() != address(0), "Bank admin not set");
        require(bank.getContractBalance() == 0, "Bank should start with zero balance");
        require(bank.getDepositorsCount() == 0, "Bank should start with zero depositors");

        console.log(unicode"✅ All deployment verifications passed!");
        console.log("");
    }

    /**
     * @dev Print a summary of deployed contracts
     */
    function printDeploymentSummary() internal view {
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log(unicode"📄 Contracts deployed:");
        console.log(unicode"├─ ERC20Token:", address(token));
        console.log(unicode"└─ TokenBank:  ", address(bank));
        console.log("");
        console.log(unicode"🔧 Configuration:");
        console.log(unicode"├─ Token Name:    ", TOKEN_NAME);
        console.log(unicode"├─ Token Symbol:  ", TOKEN_SYMBOL);
        console.log(unicode"├─ Token Decimals:", TOKEN_DECIMALS);
        console.log(unicode"├─ Total Supply:  ", TOTAL_SUPPLY / 10**TOKEN_DECIMALS, "tokens");
        console.log(unicode"└─ Bank Admin:    ", bank.admin());
        console.log("");
        console.log(unicode"🌐 Network Info:");
        console.log(unicode"├─ Chain ID:", block.chainid);
        console.log(unicode"└─ Block Number:", block.number);
        console.log("");
        console.log(unicode"💡 Next steps:");
        console.log("1. Verify contracts on block explorer (if using --verify flag)");
        console.log("2. Test token transfers and bank deposits");
        console.log("3. Set up frontend integration with these addresses");
        console.log("");
        console.log(unicode"🔗 Add these to your .env file:");
        console.log("TOKEN_ADDRESS=", address(token));
        console.log("BANK_ADDRESS=", address(bank));
    }
}
