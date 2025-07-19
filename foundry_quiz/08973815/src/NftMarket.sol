// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


import {ExtendedERC20WithData} from "./ExtendedERC20WithData.sol";
import { ITokenReceiverWithData } from "./Interfaces.sol";
import { IERC721 } from "./Interfaces.sol";



/**
 * @title NFTMarket
 * @dev 使用扩展 ERC20 Token 进行 NFT 交易的市场合约
 */
contract NFTMarket is ITokenReceiverWithData {

    // 扩展的 ERC20 代币合约
    ExtendedERC20WithData public immutable PAYMENT_TOKEN;

    // NFT 合约
    IERC721 public immutable NFT_CONTRACT;

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

        PAYMENT_TOKEN = ExtendedERC20WithData(_paymentToken);
        NFT_CONTRACT = IERC721(_nftContract);
    }

    /**
     * @dev 上架 NFT
     * @param tokenId NFT ID
     * @param price 设定价格（ERC20 token数量）
     */
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(NFT_CONTRACT.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(NFT_CONTRACT.getApproved(tokenId) == address(this), "NFT not approved to market");
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
     * @dev 内部函数：执行NFT购买逻辑，实现了成功检查和错误回滚，不用从外部再判断一次了
     * @param buyer 买家地址
     * @param seller 卖家地址
     * @param tokenId NFT tokenId
     * @param price 价格
     */
    function _safeExecuteNftPurchase(address buyer, address seller, uint256 tokenId, uint256 price) private {
        // 转移NFT给买家
        require(NFT_CONTRACT.transferFrom(seller, buyer, tokenId), "NFT transfer failed");

        // 标记为不活跃
        listings[tokenId].active = false;

        emit NFTSold(tokenId, seller, buyer, price);
    }

    /**
     * @dev 内部函数：验证购买条件
     * @param buyer 买家地址
     * @param tokenId NFT tokenId
     * @return listing NFT列表信息
     */
    function _safeValidatePurchase(address buyer, uint256 tokenId) private view returns (Listing memory listing) {
        listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(buyer != listing.seller, "Cannot buy your own NFT");
    }

    /**
     * @dev 普通购买 NFT 功能, 由购买者发起购买，按照listing price
     * @param tokenId NFT ID
     */
    function buyNft(uint256 tokenId) external {
        Listing memory listing = _safeValidatePurchase(msg.sender, tokenId);

        // 从买家转移代币到卖家
        require(PAYMENT_TOKEN.transferFrom(msg.sender, listing.seller, listing.price), "Payment failed");
        // 从卖家转移nft到买家
        _safeExecuteNftPurchase(msg.sender, listing.seller, tokenId, listing.price);
    }

    /**
     * @dev 实现 ITokenReceiverWithData 接口
     * 当用户调用 transferWithCallback 时会触发此函数
     * 买家 User 在 ERC20 合约里调用 transferWithCallback 时，携带 nftMarket 合约地址和 tokenId 作为附加数据
     * 合约呼叫 NFTMarket的tokenReceive 函数
     * @param from 转账发送者
     * @param amount 转账金额
     * @param data 附加数据（包含 tokenId）
     */
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override {
        // 只接受来自指定 ExtendedERC20WithData 合约的调用，确认当这个函数被调用之前，
        //代币已经被买家转移进入了nftmarket合约账户， 否则无法完成交易
        require(msg.sender == address(PAYMENT_TOKEN), "Only accept calls from payment token");
        require(data.length >= 32, "Invalid data length");

        // 解析 tokenId
        uint256 tokenId = abi.decode(data, (uint256));

        Listing memory listing = _safeValidatePurchase(from, tokenId);
        require(amount >= listing.price, "Incorrect payment amount"); // 允许买家支付超过listing price的代币， 多出的代币给卖家


        // 需要将代币转移给卖家
        require(PAYMENT_TOKEN.transfer(listing.seller, amount), "Payment transfer to seller failed");
        // 将NFT转移给买家
        _safeExecuteNftPurchase(from, listing.seller, tokenId, listing.price);
    }
}
