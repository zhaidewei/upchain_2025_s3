# [Quiz](https://decert.me/challenge/e76599d5-a30c-4678-ba92-fe43c56df1db)

编写 StakingPool 合约，实现 Stake 和 Unstake 方法，允许任何人质押ETH来赚钱 KK Token。其中 KK Token 是每一个区块产出 10 个，产出的 KK Token 需要根据质押时长和质押数量来公平分配。

（加分项）用户质押 ETH 的可存入的一个借贷市场赚取利息.

参考思路：找到 借贷市场 进行一笔存款，然后查看调用的方法，在 Stake 中集成该方法

下面是合约接口信息

```solidity
/**
 * @title KK Token
 */
interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @title Staking Interface
 */
interface IStaking {
    /**
     * @dev 质押 ETH 到合约
     */
    function stake()  payable external;

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external;

    /**
     * @dev 领取 KK Token 收益
     */
    function claim() external;

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view returns (uint256);
}
```

# 分析

1.基本上这道题是sushi swap的 质押LP Token赚取 Sushi Token这部分的模仿。

SushiSwap [MasterChef](https://github.com/sushiswap/masterchef/blob/master/contracts/MasterChef.sol)（V1/V2/MiniChef）

其中的关键点是KK Token的分配方式
[一个参考文档](https://medium.com/coinmonks/analysis-of-the-billion-dollar-algorithm-sushiswaps-masterchef-smart-contract-81bb4e479eb6)

这道题，我要做的pool合约 选择不做ERC20合约，而是调用一个外部的ERC20合约，KKToken来自这个ERC20
Pool实现了IStaking 接口。
为了实现它的接口，我要参考MasterChef合约里对pool合约的管理变量和方法。

2.关于加分项。用户质押的ETH可以存入一个借贷市场赚取利息。也就是说，我们这个staking合约里的钱不要死死的躺着，我们可以把一定比例的钱（可以设置）随时存入借贷市场去吃利息。只要保证我们的用户提取ETH的时候，我们先从灵活的ETH部分去找，如果不够，那么我们就从借贷市场里赎回。
理想的借贷市场是Compound合约，参考这个文档
https://medium.com/compound-finance/supplying-assets-to-the-compound-protocol-ec2cf5df5aa

## 重要关系

跟踪用户的奖励KK Token数量的方法：
记录每个用户提供的ETH 的 amount。这个用一个用户名下的amount参数去记录。
amount表示了用户提供的ETH的多少，但是我们还需要记录用户质押ETH的时间累积量。

它采取这样的算法：
首先在pool合约里记录一个参数，它表示从合约开始到现在，如果你质押了一个ETH，应当获得多少KK Token奖励。
因为你的Token不是从第一个区块到现在始终都在的，所以相当于你的数量乘以单位奖励后，你欠了pool一笔奖励，这个就是
你添加ETH的时候，那么多的ETH可以获得的创建奖励。
这个总额是不变的，叫做rewardDebt。
那么每次你改变ETH的时候，结算一次，然后更新这个值就行了。

因为要做奖励的分配和提取分离的逻辑，所以在Pool里先记录每个用户获得的KKToken奖励，但是这些token依然是保存在Pool名下。
只有当用户申请claim方法去提取token的时候，我们才把token做erc20转账

几个细节：
1. 1e12 避免精度损失 -  需要做除法的内部数字，先乘以1e12放大，然后做除法。这样可以保证数字没有被清零，然后在最后返回之前再除以1e12

2. `if (block.number <= pool.lastRewardBlock)` 在MasterChef里，有多次进行区块号检查。防止奖励在一个区块上被重复释放

重要区别，
1. Sushi Token要求质押的是一个LP Token（Erc20代币），这里是ETH
2. MasterChef合约会生成并且管理多个Pool，我们只要做一个pool就行了。
3. 我们不需要migrator合约
4. 我们不需要bonus
5. 只需要接口里的方法，Master Chef 的其他方法，比如EmergencyWithdraw
