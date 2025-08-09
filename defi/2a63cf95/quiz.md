# [quiz](https://decert.me/challenge/2a63cf95-43ec-42ee-975f-2b41510492cd)

在测试网上部署两个自己的 ERC20 合约 MyToken ，再部署两个 Uniswap，并创建两个Uniswap V2 流动池（称为 PoolA 和 PoolB），让PoolA 和 PoolB 形成价差，创造套利条件。

编写合约执行闪电兑换，可参考 V2 的ExampleFlashSwap。
提示：你需要在 UniswapV2Call中，用从PoolA 收到的 TokenA 在PoolB 兑换为 TokenB 并还回到 uniswapV2 Pair 中。

解题要求：

贴出你的代码库链接
上传执行闪电兑换的日志，能够反应出闪电兑换成功执行。

# 分析

## 闪电贷的本质，在这个[文章](https://docs.uniswap.org/contracts/v2/concepts/core-concepts/flash-swaps)里，也就是当你调用Pair合约的swap方法的时候，
swap方法给我们需要的代币，然后会执行一个回掉函数 uniswapV2Call
我们在自己的套利合约里定义这个函数，先拿刚才获得的代币去赚钱，最后在结尾归还swap里得到的代币，记住要添加0.3%的手续费。

## [例子](https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol)

## 构造测试

网路，避免自己部署uniswap,采用anvil fork主网

admin部署两个erc20合约，MyToken1 和Mytoken2. 分别mint 出 1000 ether

admin使用500 MT1和500 MT2 创建流动性池 P1
admin使用500 MT1和500 MT2 创建流动性池 P2

此时池子内两种代币的价格相等。

admin给user1 mint 100 个token1，

user1 在P1 里使用Mtoken 1 购买 Mtoken 2，导致P1里的MToken2 价格高于 P2里的MT2.

user2 部署一个套利合约 C，C里实现了uniswapV2Call 方法。
在这个方法里，从P1里借MT1，然后它去P2里 用MT1买MT2
然后在uniswapV2Call的结尾处，计算自己需要归还多少MT2 来保持P1里的K值不变。

最后user2手上的剩余MT2就是他的套利所得。
