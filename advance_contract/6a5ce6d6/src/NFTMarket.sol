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

    // Custom errors for gas optimization
    error PriceMustBeGreaterThanZero();
    error NotOwnerOfNFT();
    error NFTNotApprovedToMarket();
    error NFTAlreadyListed();
    error NFTNotListed();
    error CannotBuyOwnNFT();
    error PaymentFailed();
    error PermitBuyExpiredDeadline();
    error PermitBuyInvalidSignature();
    error PriceMismatch();
    error PaymentTokenCannotBeZero();
    error NFTContractCannotBeZero();

    // EIP712 相关常量
    bytes32 public constant PERMIT_BUY_TYPEHASH =
        keccak256("PermitBuy(uint256 tokenId,address buyer,uint64 price,uint256 deadline)");

    // EIP712 域信息
    // string public DOMAIN_NAME; hard code name for gas saving
    // string public DOMAIN_VERSION;
    string public constant DOMAIN_NAME = "NFTMarket";
    string public constant DOMAIN_VERSION = "1.0";

    // 扩展的 ERC20 代币合约
    Erc20Eip2612Compatiable public immutable PAYMENT_TOKEN;

    // NFT 合约 - 使用接口而不是具体实现
    IERC721 public immutable NFT_CONTRACT;

    // Gas saving: from 1 struct to 1 mapping
    // Replace a struct object 20B+32B+1B=53B to 32 bytes
    mapping(uint256 => uint256) public listings;
    // the cost is packing and unpacking functions below, and a downgraded readbility

    function _packListing(address seller, uint64 price, bool active) internal pure returns (uint256) {
        return uint256(uint160(seller)) | (uint256(price) << 160) | (uint256(active ? 1 : 0) << 224);
    }

    function _getSeller(uint256 packed) internal pure returns (address) {
        return address(uint160(packed));
    }

    function _getPrice(uint256 packed) internal pure returns (uint64) {
        return uint64(packed >> 160);
    }

    function _getActive(uint256 packed) internal pure returns (bool) {
        return (packed >> 224) & 1 != 0;
    }

    // 事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint64 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint64 price);
    event PermitBuyExecuted(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint64 price);

    // 构造函数
    constructor(address _paymentToken, address _nftContract) Ownable(msg.sender) {
        if (_paymentToken == address(0)) revert PaymentTokenCannotBeZero();
        if (_nftContract == address(0)) revert NFTContractCannotBeZero();

        PAYMENT_TOKEN = Erc20Eip2612Compatiable(_paymentToken);
        NFT_CONTRACT = IERC721(_nftContract);
    }

    function list(uint256 tokenId, uint64 price) external {
        if (price == 0) revert PriceMustBeGreaterThanZero();
        if (NFT_CONTRACT.ownerOf(tokenId) != msg.sender) revert NotOwnerOfNFT();
        if (NFT_CONTRACT.getApproved(tokenId) != address(this)) revert NFTNotApprovedToMarket();
        // Optimized: check if listing exists by checking if packed value is non-zero
        if (listings[tokenId] != 0) revert NFTAlreadyListed();

        // 创建上架信息
        listings[tokenId] = _packListing(msg.sender, price, true);

        emit NFTListed(tokenId, msg.sender, price);
    }

    function _executeBuy(uint256 tokenId, address buyer) internal {
        address seller = _getSeller(listings[tokenId]);
        uint64 price = _getPrice(listings[tokenId]);

        // 从买家转移代币到卖家
        if (!PAYMENT_TOKEN.transferFrom(buyer, seller, price)) revert PaymentFailed();
        // 从卖家转移nft到买家
        NFT_CONTRACT.transferFrom(seller, buyer, tokenId);
        // 标记为不活跃
        listings[tokenId] = _packListing(seller, price, false);

        emit NFTSold(tokenId, seller, buyer, price);
    }

    function getListing(uint256 tokenId) external view returns (address seller, uint64 price, bool active) {
        return (_getSeller(listings[tokenId]), _getPrice(listings[tokenId]), _getActive(listings[tokenId]));
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
    function permitBuy(uint256 tokenId, uint64 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (block.timestamp > deadline) revert PermitBuyExpiredDeadline();

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
        if (signer != owner()) revert PermitBuyInvalidSignature();

        // 验证上架信息 - 只检查价格匹配，让 _executeBuy 处理其他验证
        uint64 listingPrice = _getPrice(listings[tokenId]);
        address seller = _getSeller(listings[tokenId]);
        bool active = _getActive(listings[tokenId]);

        if (!active) revert NFTNotListed();
        if (listingPrice != price) revert PriceMismatch();
        if (msg.sender == seller) revert CannotBuyOwnNFT();

        // 执行购买逻辑
        _executeBuy(tokenId, msg.sender);

        emit PermitBuyExecuted(tokenId, msg.sender, seller, price);
    }
}
