// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Quiz#2
编写一个简单的 NFTMarket 合约，
使用自己发行的ERC20 扩展 Token 来买卖 NFT，
NFTMarket 的函数有：

list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）
并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。

buyNFT() : 普通的购买 NFT 功能，
用户转入所定价的 token 数量，获得对应的 NFT。

实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived，
在 tokensReceived 中实现NFT 购买功能(注意扩展的转账需要添加一个额外数据参数)。
*/

import {ExtendedERC20} from "https://github.com/zhaidewei/upchain_2025_s3/blob/main/solidity_quiz/4df553df/Q1_ERC20_with_hook.sol";

/**
 * @dev 扩展的代币接收者接口，支持额外数据参数
 */
interface ITokenReceiverWithData {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}

/**
 * @dev 简化的 ERC721 接口
 */
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
}

/**
 * @title ExtendedERC20WithData
 * @dev 扩展 ExtendedERC20，添加支持数据参数的转账函数
 */
contract ExtendedERC20WithData is ExtendedERC20 {

    constructor() ExtendedERC20() {}

    // 事件：带数据的回调转账
    event TransferWithCallbackAndData(address indexed from, address indexed to, uint256 value, bytes data);

    /**
     * @dev 带回调和数据功能的转账函数
     * @param to 目标地址
     * @param amount 转账金额
     * @param data 附加数据
     * @return success 转账是否成功
     */
    function transferWithCallback(address to, uint256 amount, bytes calldata data) external returns (bool success) {
        // 执行标准转账
        require(transfer(to, amount), "Transfer failed");

        bool callbackExecuted = false;

        // 检查目标地址是否是合约（合约地址的代码长度 > 0）
        if (to.code.length > 0) {
            ITokenReceiverWithData(to).tokensReceived(msg.sender, amount, data);
            callbackExecuted = true;
            emit TransferWithCallbackAndData(msg.sender, to, amount, data);
        }
        // 如果目标地址是EOA，则不允许使用此方法
        else {
            revert("Cannot transfer to EOA");
        }

        return callbackExecuted;
    }
}

/**
 * @title NFTMarket
 * @dev 使用扩展 ERC20 Token 进行 NFT 交易的市场合约
 */
contract NFTMarket is ITokenReceiverWithData {

    // 扩展的 ERC20 代币合约
    ExtendedERC20WithData public immutable paymentToken;

    // NFT 合约
    IERC721 public immutable nftContract;

    // 上架信息结构
    struct Listing {
        address seller;     // 卖家地址
        uint256 price;      // 价格（token数量）
        bool active;        // 是否有效
    }

    // 存储上架信息：tokenId => Listing
    mapping(uint256 => Listing) public listings;

    // 事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    // 构造函数
    constructor(address _paymentToken, address _nftContract) {
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");

        paymentToken = ExtendedERC20WithData(_paymentToken);
        nftContract = IERC721(_nftContract);
    }

    /**
     * @dev 上架 NFT
     * @param tokenId NFT ID
     * @param price 设定价格（token数量）
     */
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(nftContract.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(nftContract.getApproved(tokenId) == address(this), "NFT not approved to market");
        require(!listings[tokenId].active, "NFT already listed");

        // 创建上架信息
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /**
     * @dev 普通购买 NFT 功能
     * @param tokenId NFT ID
     */
    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");

        // 从买家转移代币到卖家
        require(paymentToken.transferFrom(msg.sender, listing.seller, listing.price), "Payment failed");

        // 转移NFT给买家
        nftContract.transferFrom(listing.seller, msg.sender, tokenId);

        // 标记为不活跃
        listings[tokenId].active = false;

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    /**
     * @dev 实现 ITokenReceiverWithData 接口
     * 当用户调用 transferWithCallback 时会触发此函数
     * @param from 转账发送者
     * @param amount 转账金额
     * @param data 附加数据（包含 tokenId）
     */
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override {
        // 只接受来自指定 ExtendedERC20WithData 合约的调用
        require(msg.sender == address(paymentToken), "Only accept calls from payment token");
        require(data.length >= 32, "Invalid data length");

        // 解析 tokenId
        uint256 tokenId;
        assembly {
            tokenId := calldataload(data.offset)
        }

        Listing memory listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(from != listing.seller, "Cannot buy your own NFT");
        require(amount == listing.price, "Incorrect payment amount");

        // 代币已经通过 transferWithCallback 转移到了合约
        // 需要将代币转移给卖家
        require(paymentToken.transfer(listing.seller, listing.price), "Payment transfer to seller failed");

        // 转移NFT给买家
        nftContract.transferFrom(listing.seller, from, tokenId);

        // 标记为不活跃
        listings[tokenId].active = false;

        emit NFTSold(tokenId, listing.seller, from, listing.price);
    }
}







