// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Erc20Impl} from "./Erc20Impl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Factory is Ownable {
    using Clones for address;

    address public immutable ERC20_IMPLEMENTATION;
    address[] public allMemes;
    address public router; // Uniswap V2 Router address
    address public WETH_ADDRESS; // WETH address for Uniswap

    // Fee distribution: 5% to project, 95% to meme creator
    uint8 public constant PROJECT_FEE_PERCENTAGE = 5;
    uint8 public constant CREATOR_FEE_PERCENTAGE = 95;
    uint8 public constant FEE_DENOMINATOR = 100;

    constructor(address _erc20Implementation, address _router) Ownable(msg.sender) {
        ERC20_IMPLEMENTATION = _erc20Implementation;
        router = _router;
        // Get WETH address from router
        WETH_ADDRESS = IUniswapV2Router02(_router).WETH();
    }

    function deployMeme(string memory name, string memory symbol, uint256 perMint, uint256 price)
        external
        returns (address memeAddress)
    {
        memeAddress = ERC20_IMPLEMENTATION.clone();
        Erc20Impl(memeAddress).initialize(name, symbol, perMint, price, address(this), msg.sender);
        allMemes.push(memeAddress);
        return memeAddress;
    }

    function mintMeme(address tokenAddr) external payable {
        Erc20Impl token = Erc20Impl(tokenAddr);

        // 1. 验证和mint代币给用户
        require(token.factory() == address(this), "Token not from this factory");
        require(msg.value == token.price(), "Incorrect payment amount");
        require(token.totalSupply() + token.perMint() <= type(uint256).max, "Would exceed max supply");

        // 1.5 计算代币分配
        uint256 totalTokens = token.perMint(); // 总共mint的代币数量
        uint256 liquidityTokens = (totalTokens * PROJECT_FEE_PERCENTAGE) / FEE_DENOMINATOR; // 5%用于流动性
        uint256 userTokens = totalTokens - liquidityTokens; // 95%给用户

        emit DebugInfo("Starting mint", totalTokens, liquidityTokens, userTokens);

        // 2. 先mint代币给用户
        token.mint(msg.sender, userTokens);
        emit DebugInfo("User tokens minted", userTokens, 0, 0);

        // 3. 为流动性mint额外代币
        token.mint(address(this), liquidityTokens); // Factory合约获得代币用于流动性
        emit DebugInfo("Liquidity tokens minted", liquidityTokens, 0, 0);

        // 4. 计算费用分配
        uint256 projectFee = (msg.value * PROJECT_FEE_PERCENTAGE) / FEE_DENOMINATOR; // 5 ETH
        uint256 creatorFee = msg.value - projectFee; // 95 ETH

        emit DebugInfo("Fee calculation", projectFee, creatorFee, msg.value);

        // 5. 授权Router使用Factory的代币
        token.approve(router, liquidityTokens);
        emit DebugInfo("Router approved", liquidityTokens, 0, 0);

        // 6. 调用Uniswap添加流动性
        {
            (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IUniswapV2Router02(router).addLiquidityETH{
                value: projectFee
            }(
                tokenAddr,
                liquidityTokens,
                0, // minToken - 设置为0以允许任何滑点
                0, // minETH - 设置为0以允许任何滑点
                address(owner()), // LP Token接收者 是工厂合约的owner
                block.timestamp + 24 hours
            );
            // 流动性添加成功
            emit LiquidityAdded(tokenAddr, projectFee, liquidityTokens);
            emit DebugInfo("Liquidity added successfully", amountToken, amountETH, liquidity);
        }

        // 7. 发送费用给代币owner
        (bool creatorFeeSent,) = token.owner().call{value: creatorFee}("");
        require(creatorFeeSent, "Failed to send creator fee");
        emit DebugInfo("Creator fee sent", creatorFee, 0, 0);
    }

    function getAllMemes() external view returns (address[] memory) {
        return allMemes;
    }

    receive() external payable {}

    // Events for debugging
    event LiquidityAdded(address token, uint256 ethAmount, uint256 tokenAmount);
    event LiquidityAddFailed(address token, uint256 ethAmount, uint256 tokenAmount);
    event DebugInfo(string message, uint256 value1, uint256 value2, uint256 value3);
}
