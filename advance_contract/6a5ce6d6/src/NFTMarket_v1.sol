// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Erc20Eip2612Compatiable} from "./Erc20Eip2612Compatiable.sol";
import {IERC721} from "./Interfaces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFTMarket
 * @dev 使用扩展 ERC20 Token 进行 NFT 交易的市场合约
 */
contract NFTMarket is Ownable {
    using ECDSA for bytes32;

    // EIP712 相关常量
    bytes32 public constant PERMIT_BUY_TYPEHASH =
        keccak256("PermitBuy(uint256 tokenId,address buyer,uint256 price,uint256 deadline)");

    // EIP712 域信息
    string public DOMAIN_NAME;
    string public DOMAIN_VERSION;

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
    constructor(address _paymentToken, address _nftContract, string memory _domainName, string memory _domainVersion)
        Ownable(msg.sender)
    {
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");
        require(bytes(_domainName).length > 0, "Domain name cannot be empty");
        require(bytes(_domainVersion).length > 0, "Domain version cannot be empty");

        PAYMENT_TOKEN = Erc20Eip2612Compatiable(_paymentToken);
        NFT_CONTRACT = IERC721(_nftContract);
        DOMAIN_NAME = _domainName;
        DOMAIN_VERSION = _domainVersion;
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
        require(listing.active, "NFT not listed");
        require(buyer != listing.seller, "Cannot buy your own NFT");

        // 从买家转移代币到卖家
        require(PAYMENT_TOKEN.transferFrom(buyer, listing.seller, listing.price), "Payment failed");
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

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev 通过 EIP712 签名购买 NFT（仅限白名单用户）
     * @param tokenId NFT ID
     * @param price 价格
     * @param deadline 签名过期时间
     * @param v, r, s 签名参数
     */
    function permitBuy(uint256 tokenId, uint256 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "PermitBuy: expired deadline");

        // 构建 EIP712 消息
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_BUY_TYPEHASH,
                tokenId,
                msg.sender, // buyer
                price,
                deadline
            )
        );

        bytes32 hash = keccak256(abi.encodePacked(hex"1901", DOMAIN_SEPARATOR(), structHash));

        // 验证签名
        address signer = hash.recover(v, r, s);
        require(signer == owner(), "PermitBuy: invalid signature");

        // 验证上架信息
        Listing memory listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(listing.price == price, "Price mismatch");

        // 执行购买逻辑
        _executeBuy(tokenId, msg.sender);

        emit PermitBuyExecuted(tokenId, msg.sender, listing.seller, listing.price);
    }
}
