// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CallOptionToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public immutable strikePrice; // 行权价格（以ETH计价，单位：wei）
    uint256 public immutable expirationTime; // 到期时间
    uint256 public immutable optionFee; // 期权费（以ETH计价，单位：wei）
    uint256 public underlyingAmount; // 标的资产总量（ETH）

    mapping(address => uint256) public userOptionFee; // 用户支付的期权费

    event OptionPurchased(address indexed user, uint256 tokenAmount, uint256 ethPaid);
    event OptionExercised(address indexed user, uint256 tokenAmount, uint256 ethReceived);
    event OptionExpired(address indexed user, uint256 tokenAmount, uint256 ethRefunded);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _strikePrice,
        uint256 _optionFee,
        uint256 _durationInDays
    ) ERC20(name, symbol) Ownable(msg.sender) {
        strikePrice = _strikePrice;
        optionFee = _optionFee;
        expirationTime = block.timestamp + (_durationInDays * 1 days);
    }

    // 项目方存入ETH并发行期权Token
    function depositAndMint() external payable onlyOwner {
        require(msg.value > 0, "Must deposit ETH");
        underlyingAmount += msg.value;

        // 根据存入的ETH和行权价格计算可发行的Token数量
        uint256 tokenAmount = (msg.value * 1e18) / strikePrice;
        _mint(owner(), tokenAmount);

        emit OptionPurchased(owner(), tokenAmount, msg.value);
    }

    // 用户购买期权Token
    function purchaseOption(uint256 tokenAmount) external payable nonReentrant {
        require(block.timestamp < expirationTime, "Option expired");
        require(tokenAmount > 0, "Token amount must be positive");
        require(msg.value == (tokenAmount * optionFee) / 1e18, "Incorrect ETH amount");

        // 检查合约是否有足够的Token
        require(balanceOf(owner()) >= tokenAmount, "Insufficient tokens available");

        // 转移Token给用户
        _transfer(owner(), msg.sender, tokenAmount);

        // 记录用户支付的期权费
        userOptionFee[msg.sender] += msg.value;

        emit OptionPurchased(msg.sender, tokenAmount, msg.value);
    }

    // 用户行权
    function exerciseOption(uint256 tokenAmount) external nonReentrant {
        require(block.timestamp >= expirationTime, "Option not yet exercisable");
        require(tokenAmount > 0, "Token amount must be positive");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient tokens");

        // 计算行权可获得的ETH数量
        uint256 ethAmount = (tokenAmount * strikePrice) / 1e18;
        require(underlyingAmount >= ethAmount, "Insufficient ETH in contract");

        // 销毁用户的Token
        _burn(msg.sender, tokenAmount);

        // 减少合约中的ETH
        underlyingAmount -= ethAmount;

        // 转移ETH给用户
        (bool success,) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        emit OptionExercised(msg.sender, tokenAmount, ethAmount);
    }

    // 过期后项目方销毁剩余Token并取回ETH
    function expireAndRedeem() external onlyOwner {
        require(block.timestamp > expirationTime, "Option not yet expired");

        uint256 remainingTokens = balanceOf(owner());
        if (remainingTokens > 0) {
            _burn(owner(), remainingTokens);
        }

        uint256 remainingEth = underlyingAmount;
        if (remainingEth > 0) {
            underlyingAmount = 0;
            (bool success,) = owner().call{value: remainingEth}("");
            require(success, "ETH transfer failed");
        }

        emit OptionExpired(owner(), remainingTokens, remainingEth);
    }

    // 查看合约状态
    function getContractInfo()
        external
        view
        returns (
            uint256 _strikePrice,
            uint256 _optionFee,
            uint256 _expirationTime,
            uint256 _underlyingAmount,
            uint256 _totalSupply,
            uint256 _ownerBalance,
            bool _isExpired
        )
    {
        return (
            strikePrice,
            optionFee,
            expirationTime,
            underlyingAmount,
            totalSupply(),
            balanceOf(owner()),
            block.timestamp > expirationTime
        );
    }

    // 查看用户信息
    function getUserInfo(address user)
        external
        view
        returns (uint256 _tokenBalance, uint256 _optionFeePaid, bool _canExercise)
    {
        return (balanceOf(user), userOptionFee[user], block.timestamp >= expirationTime);
    }
}
