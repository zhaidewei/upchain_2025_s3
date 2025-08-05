// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {NFTMarketD1} from "../src/D1_NftMarket.sol";
import {Erc20Token} from "../src/A_Erc20Token.sol";
import {Erc721Nft} from "../src/B_Erc721Nft.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployer);

        // 1. Deploy ERC20 Token
        Erc20Token paymentToken = new Erc20Token();
        console.log("ERC20 Token deployed at:", address(paymentToken));

        // 2. Deploy ERC721 NFT
        Erc721Nft nftContract = new Erc721Nft();
        console.log("ERC721 NFT deployed at:", address(nftContract));

        // 3. Deploy Implementation Contract
        NFTMarketD1 implementation = new NFTMarketD1();
        console.log("Implementation deployed at:", address(implementation));

        // 4. Deploy Proxy Admin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("Proxy Admin deployed at:", address(proxyAdmin));

        // 5. Prepare initialization data
        bytes memory initData =
            abi.encodeWithSelector(NFTMarketD1.initialize.selector, address(paymentToken), address(nftContract));

        // 6. Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), address(proxyAdmin), initData);
        console.log("Proxy deployed at:", address(proxy));

        // 7. Transfer proxy admin ownership to deployer
        proxyAdmin.transferOwnership(deployer);
        console.log("Proxy admin ownership transferred to:", deployer);

        vm.stopBroadcast();

        // 8. Verify deployment
        NFTMarketD2 proxyContract = NFTMarketD2(address(proxy));
        (string memory name, string memory version) = proxyContract.getDomainInfo();
        console.log("Domain name:", name);
        console.log("Domain version:", version);
    }
}
