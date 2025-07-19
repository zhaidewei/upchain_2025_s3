// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "../src/ExtendedERC20WithData.sol";
import "../src/BaseERC721.sol";
import "../src/NFTMarket.sol";

contract DeployScript is Script {

    // Deployed contract addresses
    ExtendedERC20WithData public paymentToken;
    BaseERC721 public nft;
    NFTMarket public market;

    // Test accounts (Anvil default accounts)
    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public alice = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public bob = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public charlie = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    function run() external {
        // Start broadcasting with deployer's private key
        vm.startBroadcast();

        console.log("=== Starting Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Network: Local Anvil");

        // 1. Deploy ExtendedERC20WithData
        console.log("\n1. Deploying ExtendedERC20WithData...");
        paymentToken = new ExtendedERC20WithData();
        console.log("ExtendedERC20WithData deployed at:", address(paymentToken));
        console.log("Token Name:", paymentToken.name());
        console.log("Token Symbol:", paymentToken.symbol());
        console.log("Total Supply:", paymentToken.totalSupply());

        // 2. Deploy BaseERC721
        console.log("\n2. Deploying BaseERC721...");
        nft = new BaseERC721(
            "TestNFT",
            "TNFT",
            "https://api.testnft.com/metadata/"
        );
        console.log("BaseERC721 deployed at:", address(nft));
        console.log("NFT Name:", nft.name());
        console.log("NFT Symbol:", nft.symbol());

        // 3. Deploy NFTMarket
        console.log("\n3. Deploying NFTMarket...");
        market = new NFTMarket(address(paymentToken), address(nft));
        console.log("NFTMarket deployed at:", address(market));

        // 4. Setup initial state for testing
        console.log("\n4. Setting up initial state...");

        // Distribute tokens to test users
        paymentToken.transfer(alice, 10000 * 10**18);
        paymentToken.transfer(bob, 10000 * 10**18);
        paymentToken.transfer(charlie, 5000 * 10**18);

        console.log("Tokens distributed:");
        console.log("- Alice:", paymentToken.balanceOf(alice) / 10**18, "tokens");
        console.log("- Bob:", paymentToken.balanceOf(bob) / 10**18, "tokens");
        console.log("- Charlie:", paymentToken.balanceOf(charlie) / 10**18, "tokens");

        // Mint some NFTs to Alice for testing
        nft.mint(alice, 1);
        nft.mint(alice, 2);
        nft.mint(alice, 3);
        nft.mint(bob, 4);
        nft.mint(bob, 5);

        console.log("NFTs minted:");
        console.log("- Alice owns NFTs: 1, 2, 3");
        console.log("- Bob owns NFTs: 4, 5");

        vm.stopBroadcast();

        // 5. Display deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("ExtendedERC20WithData:", address(paymentToken));
        console.log("BaseERC721:", address(nft));
        console.log("NFTMarket:", address(market));

        console.log("\n=== Next Steps ===");
        console.log("1. Alice can approve and list her NFTs:");
        console.logString("   cast send [NFT_ADDRESS] \"approve(address,uint256)\" [MARKET_ADDRESS] 1 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");
        console.logString("   cast send [MARKET_ADDRESS] \"list(uint256,uint256)\" 1 100000000000000000000 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");

        console.log("\n2. Bob can buy NFT with regular method:");
        console.logString("   cast send [TOKEN_ADDRESS] \"approve(address,uint256)\" [MARKET_ADDRESS] 100000000000000000000 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a");
        console.logString("   cast send [MARKET_ADDRESS] \"buyNft(uint256)\" 1 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a");

        console.log("\n3. Or use transferWithCallback method:");
        console.logString("   cast send [TOKEN_ADDRESS] \"transferWithCallback(address,uint256,bytes)\" [MARKET_ADDRESS] 100000000000000000000 0x0000000000000000000000000000000000000000000000000000000000000001 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a");
    }

    // Helper function to get deployment info
    function getDeploymentInfo() external view returns (address, address, address) {
        return (address(paymentToken), address(nft), address(market));
    }
}
