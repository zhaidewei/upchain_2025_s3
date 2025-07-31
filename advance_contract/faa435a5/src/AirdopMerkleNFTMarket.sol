// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Erc20Eip2612Compatiable} from "./Erc20Eip2612Compatiable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTMarket
 * @dev 使用扩展 ERC20 Token 进行 NFT 交易的市场合约
 */
contract AirdopMerkleNFTMarket is Ownable {
    // 扩展的 ERC20 代币合约
    Erc20Eip2612Compatiable public immutable PAYMENT_TOKEN;

    // NFT 合约 - 使用接口而不是具体实现
    IERC721 public immutable NFT_CONTRACT;

    // 上架信息结构
    struct Listing {
        address seller; // 卖家地址
        uint256 price; // 价格（token数量）
        bool active; // 是否有效
    }

    // 存储上架信息：tokenId => Listing
    mapping(uint256 => Listing) public listings;

    // 事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event PermitBuyExecuted(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    // 构造函数
    constructor(address _paymentToken, address _nftContract) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");

        PAYMENT_TOKEN = Erc20Eip2612Compatiable(_paymentToken);
        NFT_CONTRACT = IERC721(_nftContract);
    }

    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(NFT_CONTRACT.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(NFT_CONTRACT.getApproved(tokenId) == address(this), "NFT not approved to market");
        require(!listings[tokenId].active, "NFT already listed");

        // 创建上架信息
        listings[tokenId] = Listing({seller: msg.sender, price: price, active: true});

        emit NFTListed(tokenId, msg.sender, price);
    }

    function _executeBuy(uint256 tokenId, address buyer) internal {
        Listing memory listing = listings[tokenId];
        require(buyer != listing.seller, "Cannot buy your own NFT");

        // 从买家转移代币到市场合约
        require(PAYMENT_TOKEN.transferFrom(buyer, address(this), listing.price), "Payment failed");
        // 从市场合约转移Token到卖家
        require(PAYMENT_TOKEN.transfer(listing.seller, listing.price), "Payment failed");
        // 从卖家转移nft到买家
        NFT_CONTRACT.transferFrom(listing.seller, buyer, tokenId);
        // 标记为不活跃
        listings[tokenId].active = false;

        emit NFTSold(tokenId, listing.seller, buyer, listing.price);
    }

    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool active) {
        Listing memory listing = listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }

    function permitBuy(uint256 tokenId, uint256 price, uint256 _nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        require(block.timestamp <= deadline, "PermitBuy: expired deadline");
        // 验证上架信息
        Listing memory listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(listing.price == price, "Price mismatch");

        // Try call the ERC20 permit method
        PAYMENT_TOKEN.permit(msg.sender, address(this), price, deadline, v, r, s);

        // 执行购买逻辑
        _executeBuy(tokenId, msg.sender);

        emit PermitBuyExecuted(tokenId, msg.sender, listing.seller, listing.price);
    }
}
