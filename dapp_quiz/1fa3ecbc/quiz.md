# [问题描述](https://decert.me/challenge/1fa3ecbc-a3cd-43ae-908e-661aac97bdc0)

在原来的 TokenBank 添加一个方法 depositWithPermit2()， 这个方式使用 permit2 进行签名授权转账来进行存款。
在本地环境需要大家先部署 Permit2 合约

修改 Token 存款前端 让用户可以在前端通过 permit2 的签名存款。

# 分析

主体来自于[第一题](https://github.com/zhaidewei/upchain_2025_s3/tree/main/dapp_quiz/fc66ef6c)

只需要保留ErC20 和tokenbank 这两块就够了

需要部署Permit2合约到本地

Permit2合约原理是你在erc20里approve all 到 p2，这样需要转账的时候，p2就可以转走你的钱。

那安全性怎么保证？P2 收到转账请求的时候，会检查签名是不是来自于你。
相当于把permit方法从erc2612（rec20）合约里拿到外面了。

这个题和[第一题](https://github.com/zhaidewei/upchain_2025_s3/tree/main/dapp_quiz/fc66ef6c)的区别就在于，第一题tokenbank用erc20的permi方法，这里用permit2的方法。

eip712 的定义从erc20转移到了permit2了。

修改前端。

# 分解

Onchain和后端部分
1 ✅ onchain部分从第一题里copy需要的代码。erc20，token bank

2 ✅ ~~本地clone permit2合约~~。使用fork anvil

使用一个主网的fork测试。
`anvil --fork-url https://mainnet.infura.io/v3/$infura_key --state ./state-db`

注意，fork是按需下载的，所以需要对permit2进行一次调用

`cast call 0x000000000022D473030F116dDEE9F6B43aC78BA3 "DOMAIN_SEPARATOR()" --rpc-url http://127.0.0.1:8545`

```sh
Wallet
==================
Mnemonic:          test test test test test test test test test test test junk
Derivation path:   m/44'/60'/0'/0/


Fork
==================
Endpoint:       https://mainnet.infura.io/v3/<my api key>
Block number:   23021117
Block hash:     0xdd1160ad8a775e81151dd1e25b0ccab1b80c2fab0c66bc5dc222c8fe6ad1e29a
Chain ID:       1
...

0
```

3 更新tokenbank方法，指向permit2

3.1 install permit2.

本地部署脚本里，增加测试用户先授权permit2 max，然后签名，把签名发给TB合约的部分。


5 前端部分
