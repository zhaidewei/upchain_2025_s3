# [quiz](https://decert.me/challenge/b5368265-89b3-4058-8a57-a41bde625f5b)

Fork 代码库：
https://github.com/OpenSpace100/openspace_ctf

阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
以便运行 forge test 可以通过所有测试。

可以在 Vault.t.sol 中添加代码，或加入新合约，但不要修改已有代码。

请提交你 fork 后的代码库链接。

View Annotations


# 分析

1首先需要打开canWithdraw 开关， 需要获取owner权限，需要修改owner。
观察到代码里password没有初始化，所以是uint256 0

2其次需要 使用重入攻击的办法去反复调用withdraw

思路1，构建一个合约X，X里有receive方法，这个方法可以呼叫withdraw
