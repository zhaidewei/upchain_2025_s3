// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

event NFTMarketD1Initialized(address indexed paymentToken, address indexed nftContract);

contract NFTMarketD1 {
    // ERC20 代币合约
    ERC20 public PAYMENT_TOKEN;

    // NFT 合约
    ERC721 public NFT_CONTRACT;

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

    // 构造函数
    constructor(address _paymentToken, address _nftContract) {
        // Constructor is not used in proxy pattern, but required by inheritance
    }

    // initialize
    function initialize(address _paymentToken, address _nftContract) public {
        require(msg.sender == address(this), "Only callable by proxy");
        require(address(PAYMENT_TOKEN) == address(0), "Already initialized");
        require(address(NFT_CONTRACT) == address(0), "Already initialized");
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");

        PAYMENT_TOKEN = ERC20(_paymentToken);
        NFT_CONTRACT = ERC721(_nftContract);
        emit NFTMarketD1Initialized(_paymentToken, _nftContract);
    }

    function list(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than 0");
        require(NFT_CONTRACT.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(NFT_CONTRACT.getApproved(tokenId) == address(this), "NFT not approved to market");
        require(!listings[tokenId].active, "NFT already listed");

        // 创建上架信息
        listings[tokenId] = Listing({seller: msg.sender, price: price, active: true});

        emit NFTListed(tokenId, msg.sender, price);
    }

    function buyNft(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");

        // 从买家转移代币到卖家
        require(PAYMENT_TOKEN.transferFrom(msg.sender, listing.seller, listing.price), "Payment failed");
        // 从卖家转移nft到买家
        NFT_CONTRACT.transferFrom(listing.seller, msg.sender, tokenId);

        // 标记为不活跃
        listings[tokenId].active = false;

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool active) {
        Listing memory listing = listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }
}
