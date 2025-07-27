// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {BaseERC721} from "../src/BaseErc721.sol";
import {Erc20Eip2612Compatiable} from "../src/Erc20Eip2612Compatiable.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    BaseERC721 public nft;
    Erc20Eip2612Compatiable public token;

    address public owner;
    address public seller;
    address public buyer;
    address public marketAddress;

    function setUp() public {
        owner = makeAddr("owner");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        marketAddress = makeAddr("market");

        vm.startPrank(owner);

        // 部署代币合约
        token = new Erc20Eip2612Compatiable("1.0");

        // 部署 NFT 合约
        nft = new BaseERC721("TestNFT", "TNFT");

        // 部署市场合约
        market = new NFTMarket(address(token), address(nft));

        vm.stopPrank();

        // 给卖家铸造一些代币
        vm.startPrank(owner);
        token.transfer(seller, 1000);
        token.transfer(buyer, 1000);
        vm.stopPrank();

        // 验证初始余额
        assertEq(token.balanceOf(seller), 1000);
        assertEq(token.balanceOf(buyer), 1000);

        // 给卖家铸造一个 NFT
        vm.startPrank(owner);
        nft.mint(seller);
        vm.stopPrank();
    }

    function test_Constructor() public view {
        assertEq(address(market.PAYMENT_TOKEN()), address(token));
        assertEq(address(market.NFT_CONTRACT()), address(nft));
    }

    function test_ListNFT() public {
        vm.startPrank(seller);

        // 先授权市场合约操作 NFT
        nft.approve(address(market), 0);

        // 上架 NFT
        market.list(0, 100);

        // 验证上架信息
        (address listingSeller, uint256 price, bool active) = market.getListing(0);
        assertEq(listingSeller, seller);
        assertEq(price, 100);
        assertEq(active, true);

        vm.stopPrank();
    }

    function test_ListNFTWithoutApproval() public {
        vm.startPrank(seller);

        vm.expectRevert("NFT not approved to market");
        market.list(0, 100);

        vm.stopPrank();
    }

    function test_ListNFTNotOwner() public {
        vm.startPrank(buyer);

        vm.expectRevert("You don't own this NFT");
        market.list(0, 100);

        vm.stopPrank();
    }

    function test_ListNFTZeroPrice() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);

        vm.expectRevert("Price must be greater than 0");
        market.list(0, 0);

        vm.stopPrank();
    }

    function test_ListNFTAlreadyListed() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);
        market.list(0, 100);

        vm.expectRevert("NFT already listed");
        market.list(0, 200);

        vm.stopPrank();
    }

            function test_BuyNFT() public {
        // 先上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家授权市场合约使用代币
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 购买 NFT
        market.buyNft(0);

        // 验证 NFT 所有权转移
        assertEq(nft.ownerOf(0), buyer);

        // 验证代币转移
        assertEq(token.balanceOf(seller), 1100); // 1000 + 100
        assertEq(token.balanceOf(buyer), 900);   // 1000 - 100

        // 验证上架状态
        (,, bool active) = market.getListing(0);
        assertEq(active, false);

        vm.stopPrank();
    }

    function test_BuyNFTNotListed() public {
        vm.startPrank(buyer);

        vm.expectRevert("NFT not listed");
        market.buyNft(0);

        vm.stopPrank();
    }

    function test_BuyOwnNFT() public {
        // 先上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 卖家尝试购买自己的 NFT
        vm.startPrank(seller);
        token.approve(address(market), 100);

        vm.expectRevert("Cannot buy your own NFT");
        market.buyNft(0);

        vm.stopPrank();
    }

        function test_BuyNFTInsufficientAllowance() public {
        // 先上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家没有授权足够的代币
        vm.startPrank(buyer);
        token.approve(address(market), 50); // 只授权 50，但需要 100

        vm.expectRevert("ERC20InsufficientAllowance(0x72cC13426cAfD2375FFABE56498437927805d3d2, 50, 100)");
        market.buyNft(0);

        vm.stopPrank();
    }

        function test_BuyNFTInsufficientBalance() public {
        // 先上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家余额不足
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 先转移掉大部分代币
        token.transfer(owner, 950);

        vm.expectRevert("ERC20InsufficientBalance(0x0fF93eDfa7FB7Ad5E962E4C0EdB9207C03a0fe02, 50, 100)");
        market.buyNft(0);

        vm.stopPrank();
    }

    function test_GetListing() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);
        market.list(0, 100);

        (address listingSeller, uint256 price, bool active) = market.getListing(0);
        assertEq(listingSeller, seller);
        assertEq(price, 100);
        assertEq(active, true);

        vm.stopPrank();
    }

    function test_GetListingNotListed() public view {
        (address listingSeller, uint256 price, bool active) = market.getListing(0);
        assertEq(listingSeller, address(0));
        assertEq(price, 0);
        assertEq(active, false);
    }
}
