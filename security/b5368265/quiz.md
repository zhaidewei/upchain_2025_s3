# [quiz](https://decert.me/challenge/b5368265-89b3-4058-8a57-a41bde625f5b)

Fork 代码库：
https://github.com/OpenSpace100/openspace_ctf

阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
以便运行 forge test 可以通过所有测试。

可以在 Vault.t.sol 中添加代码，或加入新合约，但不要修改已有代码。

请提交你 fork 后的代码库链接。

View Annotations


# 分析

1. 首先需要打开canWithdraw 开关， 需要获取owner权限，需要修改owner。
观察到implementation 合约里的 password 变量是slot1，而proxy合约的slot 1是 VaultLogic logic，也就是implementation合约的地址。
所以在proxy里校验地址的时候，password值是proxy合约的地址值。
可以根据这个去更改owner，从而打开开关

2. 其次需要使用重入攻击的办法去反复调用withdraw
这一点是利用withdraw函数里，vault先向msg sender使用call receive方法转账，然后才扣减余额。
如果我们在receive方法处拦截，再次进入withdraw方法，就可以循环获得转账，即重入攻击。

这一点没办法从EOA完成（除非7702，set code for EOA）太麻烦，我们构造一个攻击合约，合约里有这个特殊的receive方法。
