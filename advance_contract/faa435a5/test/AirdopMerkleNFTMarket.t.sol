// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {AirdopMerkleNFTMarket} from "../src/AirdopMerkleNFTMarket.sol";
import {Erc20Eip2612Compatiable} from "../src/Erc20Eip2612Compatiable.sol";
import {BaseErc721} from "../src/BaseErc721.sol";

contract AirdopMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket public market;
    Erc20Eip2612Compatiable public token;
    BaseErc721 public nft;

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
        nft = new BaseErc721("TestNFT", "TNFT");

        // 使用 owner 的私钥部署 AirdopMerkleNFTMarket
        vm.startPrank(owner);
        market = new AirdopMerkleNFTMarket(address(token), address(nft));
        vm.stopPrank();

        // 给卖家一些代币和 NFT
        require(token.transfer(seller, 1000), "Transfer to seller failed");
        nft.mint(seller);

        // 给买家一些代币
        require(token.transfer(buyer, 1000), "Transfer to buyer failed");
    }

    // ========== 基础功能测试 ==========

    function test_Constructor() public view {
        assertEq(address(market.PAYMENT_TOKEN()), address(token));
        assertEq(address(market.NFT_CONTRACT()), address(nft));
        assertEq(market.owner(), owner);
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

        // 设置 permit 签名 (for ERC20 permit, not EIP712)
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        // Create permit signature for ERC20
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100, // price
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        // 执行 permitBuy
        vm.startPrank(buyer);
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        // 验证结果
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1100); // 1000 + 100
        assertEq(token.balanceOf(buyer), 900); // 1000 - 100

        // 验证 listing 已关闭
        (,, bool active) = market.getListing(0);
        assertEq(active, false);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyExpiredDeadline() public {
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 时间前进超过 deadline
        vm.warp(deadline + 1);

        vm.startPrank(buyer);
        vm.expectRevert("PermitBuy: expired deadline");
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyInvalidSignature() public {
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        // 使用错误的签名 - ERC20 permit will revert
        vm.expectRevert();
        market.permitBuy(0, 100, nonce, deadline, v, r, bytes32(uint256(s) + 1));

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyPriceMismatch() public {
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        // 上架 NFT 但价格不同
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 200); // 价格是 200，但签名是 100
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("Price mismatch");
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyNFTNotListed() public {
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        vm.startPrank(buyer);
        vm.expectRevert("NFT not listed");
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitBuyInsufficientBalance() public {
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 买家余额不足
        vm.startPrank(buyer);

        // 先转移掉大部分代币
        require(token.transfer(owner, 950), "Transfer to owner failed");

        vm.expectRevert();
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        vm.stopPrank();
    }

    // ========== 事件测试 ==========

    function test_Events() public {
        // 测试 NFTListed 事件
        vm.startPrank(seller);
        nft.approve(address(market), 0);

        vm.expectEmit(true, true, false, true);
        emit AirdopMerkleNFTMarket.NFTListed(0, seller, 100);
        market.list(0, 100);
        vm.stopPrank();

        // 测试 PermitBuyExecuted 事件
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                buyer,
                address(market),
                100,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, hash);

        vm.startPrank(buyer);

        vm.expectEmit(true, true, true, true);
        emit AirdopMerkleNFTMarket.PermitBuyExecuted(0, buyer, seller, 100);
        market.permitBuy(0, 100, nonce, deadline, v, r, s);

        vm.stopPrank();
    }
}
