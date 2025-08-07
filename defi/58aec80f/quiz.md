# [quiz](https://decert.me/challenge/58aec80f-8980-434a-b549-566003367694)

编写一个 Vesting 合约（可参考 OpenZepplin Vesting 相关合约）， 相关的参数有：

beneficiary： 受益人
锁定的 ERC20 地址
Cliff：12 个月
线性释放：从 第 13 个月起开始每月解锁 1/24 的 ERC20
Vesting 合约包含的方法 release() 用来释放当前解锁的 ERC20 给受益人，Vesting 合约部署后，开始计算 Cliff ，并转入 100 万 ERC20 资产。

要求在 Foundry 包含时间模拟测试， 请贴出你的 githu 代码库。


# 分解

1 admin账户 部署一个erc20 合约，要求mint 100万token

2 部署一个OZ的Oppenzeppelin 的 [Vesting Wallet](https://docs.openzeppelin.com/contracts/5.x/api/finance)做vesting合约

区别是oz里没有实现cliff，需要用startTimestamp去计算

3 做一个测试用例，使用vm的作弊方式去快进时间。
beneficiary使用一个不同的用户，比如anvil里的用户1
