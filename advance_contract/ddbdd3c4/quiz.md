# [quiz](https://decert.me/challenge/ddbdd3c4-a633-49d7-adf9-34a6292ce3a8)
Quiz#1
编写一个可升级的 ERC721 合约.
实现⼀个可升级的 NFT 市场合约：
• 实现合约的第⼀版本和这个挑战 的逻辑一致。
• 逻辑合约的第⼆版本，加⼊离线签名上架 NFT 功能⽅法（签名内容：tokenId， 价格），实现⽤户⼀次性使用 setApproveAll 给 NFT 市场合约，每个 NFT 上架时仅需使⽤签名上架。
部署到测试⽹，并开源到区块链浏览器，在你的Github的 Readme.md 中备注代理合约及两个实现的合约地址。

要求：

包含升级的测试用例（升级前后的状态保持一致）
包含运行测试用例的日志。
请提交你的 Github 仓库地址。



# 思路

[参考OpenZeppelin的ERC1967实现](https://docs.openzeppelin.com/contracts/5.x/api/proxy)

参考[ NFTMarket 合约](https://github.com/zhaidewei/upchain_2025_s3/tree/main/foundry_quiz/08973815)

首先 在Anvil上，从anvil测试账号给我的私有账号打1eth支付gasfee，
做admin地址

0 部署一个erc20 合约 A

1 部署可升级的erc721合约
- 实现合约 B
- proxy合约 C (指向B，C继承 OpZ ERC1967Proxy)

2 部署可升级的nftmarket合约
- 部署合约D1（第一版基础功能）
- proxy 合约E（指向D1，E继承OpZ ERC1967Proxy）

3 admin 从 C里呼叫 mint 2个nft token给 user1

4 user1 在C上 approve all token 给E (这次解决以及下次都不用再approve了)
5 user1 在 E 上架 token 0

6 部署合约D2，D2有离线签名 permitList 方法（ERC721 签名）
7 在E里，把implementation 从D1 指向D2（升级合约）

8 user1私钥签名（使用typescript viem 从私钥钱包生成签名）
9 user1去E上架nft token 1

10 以上1-9 在sepolia上进行同样的部署。
可以继续使用anvil 测试账号，唯一需要注意的是使用我的真实账号做admin账号
