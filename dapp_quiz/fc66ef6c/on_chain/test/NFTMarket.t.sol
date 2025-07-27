// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {Erc20Eip2612Compatiable} from "../src/Erc20Eip2612Compatiable.sol";
import {BaseERC721} from "../src/BaseErc721.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    Erc20Eip2612Compatiable public token;
    BaseERC721 public nft;

    address public owner;
    address public seller;
    address public buyer;
    uint256 public ownerPrivateKey;
    uint256 public sellerPrivateKey;
    uint256 public buyerPrivateKey;

    function setUp() public {
        // 设置账户
        (owner, ownerPrivateKey) = makeAddrAndKey("owner");
        (seller, sellerPrivateKey) = makeAddrAndKey("seller");
        (buyer, buyerPrivateKey) = makeAddrAndKey("buyer");

        // 部署合约
        token = new Erc20Eip2612Compatiable("1.0");
        nft = new BaseERC721("TestNFT", "TNFT");

        // 使用 owner 的私钥部署 NFTMarket
        vm.startPrank(owner);
        market = new NFTMarket(address(token), address(nft), "NFTMarket", "1.0");
        vm.stopPrank();

        // 给卖家一些代币和 NFT
        token.transfer(seller, 1000);
        nft.mint(seller);

        // 给买家一些代币
        token.transfer(buyer, 1000);
    }

    // ========== 基础功能测试 ==========

    function test_Constructor() public view {
        assertEq(address(market.PAYMENT_TOKEN()), address(token));
        assertEq(address(market.NFT_CONTRACT()), address(nft));
        assertEq(market.owner(), owner);
        assertEq(market.DOMAIN_NAME(), "NFTMarket");
        assertEq(market.DOMAIN_VERSION(), "1.0");
    }

    function test_ListNFT() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);
        market.list(0, 100);

        (address listingSeller, uint256 price, bool active) = market.getListing(0);
        assertEq(listingSeller, seller);
        assertEq(price, 100);
        assertEq(active, true);

        vm.stopPrank();
    }

    function test_RevertWhen_ListNFTNotOwner() public {
        vm.startPrank(buyer);

        // 不需要 approve，因为 buyer 不是 NFT 的所有者
        vm.expectRevert("You don't own this NFT");
        market.list(0, 100);

        vm.stopPrank();
    }

    function test_RevertWhen_ListNFTNotApproved() public {
        vm.startPrank(seller);

        vm.expectRevert("NFT not approved to market");
        market.list(0, 100);

        vm.stopPrank();
    }

    function test_RevertWhen_ListNFTZeroPrice() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);
        vm.expectRevert("Price must be greater than 0");
        market.list(0, 0);

        vm.stopPrank();
    }

    function test_RevertWhen_ListNFTAlreadyListed() public {
        vm.startPrank(seller);

        nft.approve(address(market), 0);
        market.list(0, 100);

        vm.expectRevert("NFT already listed");
        market.list(0, 200);

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

    // ========== permitBuy 功能测试 ==========

    function test_PermitBuy() public {
        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 设置 permitBuy 签名
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0, // tokenId
            buyer,
            100, // price
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 买家 approve 代币给 NFTMarket
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 执行 permitBuy
        market.permitBuy(0, 100, deadline, v, r, s);

        // 验证结果
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1100); // 1000 + 100
        assertEq(token.balanceOf(buyer), 900);   // 1000 - 100

        // 验证 listing 已关闭
        (,, bool active) = market.getListing(0);
        assertEq(active, false);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyExpiredDeadline() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家 approve 代币
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 时间前进超过 deadline
        vm.warp(deadline + 1);

        vm.expectRevert("PermitBuy: expired deadline");
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyInvalidSignature() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家 approve 代币
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 使用错误的签名
        vm.expectRevert("PermitBuy: invalid signature");
        market.permitBuy(0, 100, deadline, v, r, bytes32(uint256(s) + 1));

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyPriceMismatch() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 上架 NFT 但价格不同
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 200); // 价格是 200，但签名是 100
        vm.stopPrank();

        // 买家 approve 代币
        vm.startPrank(buyer);
        token.approve(address(market), 200);

        vm.expectRevert("Price mismatch");
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyNFTNotListed() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 买家 approve 代币
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        vm.expectRevert("NFT not listed");
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyInsufficientAllowance() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家没有 approve 足够的代币
        vm.startPrank(buyer);
        token.approve(address(market), 50); // 只授权 50，但需要 100

        vm.expectRevert();
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyInsufficientBalance() public {
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家余额不足
        vm.startPrank(buyer);
        token.approve(address(market), 100);

        // 先转移掉大部分代币
        token.transfer(owner, 950);

        vm.expectRevert();
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_DOMAIN_SEPARATOR() public view {
        bytes32 expectedDomainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("NFTMarket")),
            keccak256(bytes("1.0")),
            block.chainid,
            address(market)
        ));

        assertEq(market.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    // ========== 事件测试 ==========

    function test_Events() public {
        // 测试 NFTListed 事件
        vm.startPrank(seller);
        nft.approve(address(market), 0);

        vm.expectEmit(true, true, false, true);
        emit NFTMarket.NFTListed(0, seller, 100);
        market.list(0, 100);
        vm.stopPrank();

        // 测试 PermitBuyExecuted 事件
        uint256 deadline = block.timestamp + 3600;
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)"),
            0,
            buyer,
            100,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        vm.startPrank(buyer);
        token.approve(address(market), 100);

        vm.expectEmit(true, true, true, true);
        emit NFTMarket.PermitBuyExecuted(0, buyer, seller, 100);
        market.permitBuy(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }
}
