# [quiz](https://decert.me/challenge/ff20bbfe-0345-4f32-8ca3-fa77b3a0d6cb)
编写一个合约去获取 LaunchPad 发行的 Meme 的TWAP 价格， 请在测试中模拟不同时间的多个交易。
提交你的 github

# 分析

这道题可以在[这个作业](https://github.com/zhaidewei/upchain_2025_s3/tree/main/defi/df4886bc)的基础上完成。

目的是了解 用uniswap交易池去做币价Oracle的方法和原理，
参考文档:
[基于Uniswap v2的Oracle预言机](https://docs.uniswap.org/contracts/v2/concepts/core-concepts/oracles)
最重要的是理解



首先，第一步是执行上一个作业的所有操作。
即用户2 发行了meme token，然后利用uniswapv2创建一个交易池子 P。
去做代币的买卖。

我们添加一笔买卖，让user3 也从这个池子里买卖。

然后做一个合约，这个合约去uniswap读取P的当前累积token价格，从anvil的交易记录里读取2个区块之前的价格，然后计算这段时间的平均价格。

# 细节

1. 怎么从pair里读取token的价格？查询pair合约的方法可以找到。这个可以读取到当前区块下的累积价格

```solidity
function price0CumulativeLast() external view returns (uint);
function price1CumulativeLast() external view returns (uint);
```

2. 怎么从之前的区块里读取价格？

这个涉及扫块操作

给定起点区块高度blockA = 12345678

终点区块高度

然后对每个区块去读取 pair合约里的price0CumulativeLast()值pair合约里的price1CumulativeLast（）值

然后再读取每个区块头的timestamp
用价格差除以时间差。


3. anvil测试里，怎么获取main net上的uniswapv2的地址？

[文档里提供的链上地址](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/v2-deployments)

4. 关于UQ112x112 格式
UQ112x112 其实就是 一种定点数（fixed-point number）编码格式，在 Uniswap V2 里用来表示价格，精度很高，但本质上还是一个整数（uint224）

# 操作

1 复制之前的代码过来

2 在创建交易池子的时候记录区块高度和区块时间timestamp

创建池子之后，读取交易对儿的累积价格

3 用uer2 和user3构造若干次交易

4 再次读取价格

5 计算这段时间的平均价格。
