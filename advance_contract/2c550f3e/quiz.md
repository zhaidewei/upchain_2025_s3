# [quiz](https://decert.me/challenge/2c550f3e-0c29-46f8-a9ea-6258bb01b3ff)

Quiz#1
部署自己的 Delegate 合约（需支持批量执行）到 Sepolia。
修改之前的TokenBank 前端页面，让用户能够通过 EOA 账户授权给 Delegate 合约，并在一个交易中完成授权和存款操作。

# 分解

这里涉及的角色：
admin负责部署erc20，tokenbank，delegate合约
delegate合约：负责提供multicall的方法。允许用户发起多个外部呼叫，一一执行。
eoa，负责授权并且使用delegate合约的方法
去call erc20 先approve，然后call tokenbank做deposit
tokenbank合约：标准
erc20合约：标准

最后是前端展示。



操作步骤
1 ✅部署一个erc20合约，总量1000个token，转账给user1 100 个
2 ✅部署一个tokenbank合约，可以对erc20进行操作
3 ✅eoa 向erc20approve 10个给tokenbank合约
4 ✅eoa call tokenbank 去transferFrom 10个token
5 ✅检查token余额，eoa在erc20上有90个，在tokenbank里10个，tokenbank在erc20里有10个。

6 ✅部署delegate合约

7 ✅通过脚本use_delegate.tsuser1 授权delegate合约，并且调用eoa去执行multicall
向erc20 approve 10个token，然后从tokenbank去trnasfer from 10个token
8 ✅检查余额

9 前端展示
9.1 基本前端。使用react，wagmi，前端里要配置：
前端要用metaMask登陆
erc20合约地址 -》显示登录者余额
tokenbank合约地址 -》显示登录者余额
9.2 配置multicall合约的地址，
使用ERC7702的方式经过用户签名后，调用multicall从erc20合约转账给tokenbank。具体代码使用验证过的use_delegate.ts 里的逻辑
