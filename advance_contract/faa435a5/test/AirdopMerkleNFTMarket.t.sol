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

    // Merkle root for testing - represents a simple merkle tree
    bytes32 public merkleRoot;

    function setUp() public {
        // 设置账户
        (owner, ownerPrivateKey) = makeAddrAndKey("owner");
        (seller, sellerPrivateKey) = makeAddrAndKey("seller");
        (buyer, buyerPrivateKey) = makeAddrAndKey("buyer");

        // 部署合约
        token = new Erc20Eip2612Compatiable("1.0");
        nft = new BaseErc721("TestNFT", "TNFT");

        // Create a simple merkle root for testing
        // For testing purposes, we'll use a simple hash
        merkleRoot = keccak256(abi.encodePacked(buyer, uint256(1)));

        // 使用 owner 的私钥部署 AirdopMerkleNFTMarket
        vm.startPrank(owner);
        market = new AirdopMerkleNFTMarket(address(token), address(nft), merkleRoot);
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
        assertEq(market.merkleRoot(), merkleRoot);
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

    // ========== permitPrePay 功能测试 ==========

    function test_PermitPrePay() public {
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

        // 执行 permitPrePay
        vm.startPrank(buyer);
        market.permitPrePay(0, 100, deadline, v, r, s);

        // 验证 permit 成功 - 检查 allowance
        assertEq(token.allowance(buyer, address(market)), 100);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitPrePayExpiredDeadline() public {
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

        // 时间前进超过 deadline
        vm.warp(deadline + 1);

        vm.startPrank(buyer);
        vm.expectRevert("permitPrePay: expired deadline");
        market.permitPrePay(0, 100, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_RevertWhen_PermitPrePayInvalidSignature() public {
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
        // 使用错误的签名 - ERC20 permit will revert
        vm.expectRevert();
        market.permitPrePay(0, 100, deadline, v, r, bytes32(uint256(s) + 1));

        vm.stopPrank();
    }

    // ========== claimNFT 功能测试 ==========

    function test_ClaimNFTWithDiscount() public {
        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 先执行 permitPrePay
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

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

        vm.startPrank(buyer);
        market.permitPrePay(0, 100, deadline, v, r, s);

        // 创建 merkle proof (for testing, we'll use empty proof since our merkle root is simple)
        bytes32[] memory merkleProof = new bytes32[](0);

        // 执行 claimNFT
        market.claimNFT(0, merkleProof);

        // 验证结果 - 应该享受50%折扣
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1050); // 1000 + 50 (50% discount)
        assertEq(token.balanceOf(buyer), 950); // 1000 - 50

        // 验证 listing 已关闭
        (,, bool active) = market.getListing(0);
        assertEq(active, false);

        vm.stopPrank();
    }

    function test_ClaimNFTWithoutDiscount() public {
        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 先执行 permitPrePay
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(buyer);

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

        vm.startPrank(buyer);
        market.permitPrePay(0, 100, deadline, v, r, s);

        // 使用错误的 merkle proof (should not get discount)
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = bytes32(0x1234567890123456789012345678901234567890123456789012345678901234);

        // 执行 claimNFT
        market.claimNFT(0, merkleProof);

        // 验证结果 - 应该支付全价
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1100); // 1000 + 100 (full price)
        assertEq(token.balanceOf(buyer), 900); // 1000 - 100

        // 验证 listing 已关闭
        (,, bool active) = market.getListing(0);
        assertEq(active, false);

        vm.stopPrank();
    }

    function test_RevertWhen_ClaimNFTNotListed() public {
        vm.startPrank(buyer);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.expectRevert("NFT not listed");
        market.claimNFT(0, merkleProof);

        vm.stopPrank();
    }

    function test_RevertWhen_ClaimNFTInsufficientAllowance() public {
        // 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        vm.startPrank(buyer);

        // 没有执行 permitPrePay，直接尝试 claimNFT
        bytes32[] memory merkleProof = new bytes32[](0);
        // ERC20 will revert with its own error when allowance is insufficient
        vm.expectRevert();
        market.claimNFT(0, merkleProof);

        vm.stopPrank();
    }

    // ========== 完整流程测试 ==========

    function test_CompleteFlowWithDiscount() public {
        // 1. 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 2. 买家执行 permitPrePay
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
        market.permitPrePay(0, 100, deadline, v, r, s);

        // 3. 买家执行 claimNFT 获得折扣
        bytes32[] memory merkleProof = new bytes32[](0);
        market.claimNFT(0, merkleProof);

        // 4. 验证最终状态
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1050); // 1000 + 50 (50% discount)
        assertEq(token.balanceOf(buyer), 950); // 1000 - 50

        vm.stopPrank();
    }

    function test_CompleteFlowWithoutDiscount() public {
        // 1. 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, 100);
        vm.stopPrank();

        // 2. 买家执行 permitPrePay
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
        market.permitPrePay(0, 100, deadline, v, r, s);

        // 3. 买家执行 claimNFT 不获得折扣
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = bytes32(0x1234567890123456789012345678901234567890123456789012345678901234);
        market.claimNFT(0, merkleProof);

        // 4. 验证最终状态
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 1100); // 1000 + 100 (full price)
        assertEq(token.balanceOf(buyer), 900); // 1000 - 100

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

        // 测试 NFTSold 事件 (通过 claimNFT)
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
        market.permitPrePay(0, 100, deadline, v, r, s);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.expectEmit(true, true, true, true);
        emit AirdopMerkleNFTMarket.NFTSold(0, seller, buyer, 50); // 50% discount
        market.claimNFT(0, merkleProof);

        vm.stopPrank();
    }
}
