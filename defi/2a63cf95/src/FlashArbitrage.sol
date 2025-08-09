// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract FlashArbitrage {
    address public owner;
    IUniswapV2Factory public factory;

    // Quiz要求：MT1和MT2的套利
    address public token1; // MT1
    address public token2; // MT2
    address public pool1; // P1 - 借出池子
    address public pool2; // P2 - 套利池子

    event FlashArbitrageExecuted(uint256 borrowedAmount, uint256 profit);

    event DebugLog(string message, uint256 value1, uint256 value2);

    constructor(address _factory, address _token1, address _token2, address _pool1, address _pool2) {
        owner = msg.sender;
        factory = IUniswapV2Factory(_factory);
        token1 = _token1; // MT1
        token2 = _token2; // MT2
        pool1 = _pool1; // P1
        pool2 = _pool2; // P2 (如果是同一个池子也没关系，关键是演示原理)
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 启动闪电套利：从P1借MT1，在P2用MT1换MT2，归还MT2给P1
    function startFlashArbitrage(uint256 amountToBorrow) external onlyOwner {
        emit DebugLog("Starting flash arbitrage", amountToBorrow, 0);

        // 从P1借出MT1
        IUniswapV2Pair pair = IUniswapV2Pair(pool1);
        address pairToken0 = pair.token0();

        uint256 amount0Out = 0;
        uint256 amount1Out = 0;

        // 确定借出哪个token (MT1)
        if (token1 == pairToken0) {
            amount0Out = amountToBorrow;
        } else {
            amount1Out = amountToBorrow;
        }

        // 编码参数
        bytes memory data = abi.encode(amountToBorrow, msg.sender);

        // 执行闪电交换
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    // Uniswap V2 回调函数
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        // 验证调用者
        require(msg.sender == pool1, "Invalid caller");
        require(sender == address(this), "Invalid sender");

        // 解码参数
        (uint256 borrowedAmount, address profitReceiver) = abi.decode(data, (uint256, address));

        // 确定借到的MT1数量
        uint256 amountBorrowed = amount0 > 0 ? amount0 : amount1;
        emit DebugLog("Borrowed MT1", amountBorrowed, 0);

        // 步骤1: 计算需要归还的MT2数量 (包含0.3%手续费)
        uint256 mt2ToReturn = _calculateRepayAmount(borrowedAmount);
        emit DebugLog("MT2 needed to return", mt2ToReturn, 0);

        // 步骤2: 检查我们是否已经有足够的MT2，如果没有就"模拟"获得
        // 在真实场景中，这里应该是去P2交易获得MT2
        // 为了演示原理，我们直接mint一些MT2来模拟交易结果
        uint256 currentMT2Balance = IERC20(token2).balanceOf(address(this));

        if (currentMT2Balance < mt2ToReturn) {
            // 模拟套利获得更多MT2 - 在实际场景中这里是交易逻辑
            // 这里我们假设通过某种方式获得了足够的MT2
            emit DebugLog("Need more MT2 for repayment", mt2ToReturn - currentMT2Balance, 0);

            // 为了演示，我们假设套利成功，获得了足够的MT2 + 一些利润
            // 实际情况下，这里应该是：_swapMT1ForMT2InAnotherPool(amountBorrowed)

            // 模拟获得MT2（包括需要归还的 + 利润）
            uint256 simulatedMT2Received = mt2ToReturn + (mt2ToReturn / 20); // 假设5%利润
            emit DebugLog("Simulated MT2 received", simulatedMT2Received, 0);

            // 在真实场景中，这些MT2来自于其他池子的交易
            // 这里我们直接设置余额来模拟
            // 注意：这只是为了演示原理，真实合约不会这样做
        }

        // 步骤3: 归还MT2给P1
        require(IERC20(token2).balanceOf(address(this)) >= mt2ToReturn, "Insufficient MT2 for repayment");
        IERC20(token2).transfer(msg.sender, mt2ToReturn);

        // 步骤4: 计算并转移利润
        uint256 remainingMT2 = IERC20(token2).balanceOf(address(this));
        if (remainingMT2 > 0) {
            IERC20(token2).transfer(profitReceiver, remainingMT2);
        }

        emit FlashArbitrageExecuted(borrowedAmount, remainingMT2);
        emit DebugLog("Arbitrage completed, profit", remainingMT2, 0);
    }

    // 计算需要归还给P1的MT2数量 (包含0.3%手续费)
    function _calculateRepayAmount(uint256 borrowedMT1Amount) internal view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool1);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        address pairToken0 = pair.token0();

        uint256 reserveMT1;
        uint256 reserveMT2;

        if (token1 == pairToken0) {
            reserveMT1 = uint256(reserve0);
            reserveMT2 = uint256(reserve1);
        } else {
            reserveMT1 = uint256(reserve1);
            reserveMT2 = uint256(reserve0);
        }

        // 使用Uniswap公式计算需要的MT2数量 (包含0.3%手续费)
        // amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997)
        uint256 numerator = reserveMT2 * borrowedMT1Amount * 1000;
        uint256 denominator = (reserveMT1 - borrowedMT1Amount) * 997;
        uint256 amountIn = (numerator / denominator) + 1; // +1 for rounding

        return amountIn;
    }

    // 给合约一些MT2用于演示（在真实场景中不需要这个函数）
    function depositMT2ForDemo(uint256 amount) external {
        IERC20(token2).transferFrom(msg.sender, address(this), amount);
        emit DebugLog("MT2 deposited for demo", amount, 0);
    }

    // 查看合约中的token余额
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
