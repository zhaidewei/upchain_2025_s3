# Quiz#1

1 使用 EIP2612 标准（可基于 Openzepplin 库）编写一个自己名称的 Token 合约。
2 修改 TokenBank 存款合约 ,添加一个函数 permitDeposit 以支持离线签名授权（permit）进行存款, 并在TokenBank前端 加入通过签名存款。

3 修改Token 购买 NFT NTFMarket 合约，添加功能 permitBuy() 实现只有离线授权的白名单地址才可以购买 NFT （用自己的名称发行 NFT，再上架） 。
白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，在permitBuy()中判断时候是经过许可的白名单用户，如果是，才可以进行后续购买，否则 revert 。
要求：

有 Token 存款及 NFT 购买成功的测试用例
有测试用例运行日志或截图，能够看到 Token 及 NFT 转移。
请填写你的 Github 项目链接地址。

## 任务分解

1. 实现一个EIP2612的Token合约。也就是在erc20基础上添加erc2612里所要求的三个新方法

2. 用从之前的[tokenBank合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/dapp_quiz/56e455b3/contracts/src/TokenBank.sol)作为基础，添加permitDeposit功能。
首先做签名验证，其次通过验证之后，通过permit方法去修改用户的allowarence为tokenBank

3.前端，用之前的前端程序作为基础。 支持通过签名存款的功能。用户可以点击签名存款，然后前端发送这个eip712的结构化签名给用户钱包。
钱包签名后，签名返回前端。

4.发行一个[NFT合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/foundry_quiz/08973815/src/ExtendedERC721.sol)

拿来之前的[NTFMarket 合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/foundry_quiz/08973815/src/NftMarket.sol)发行一个NFTMarket合约

5 给nftmarket合约添加一个管理员地址，管理员可以修改白名单信息，也就是一个address到bool到映射，true是白，false是黑
admin可以修改值，但是不用删除记录
在合约里添加白名单地址，也就是合法买家地址。

在NFTMarket里添加permitBuy()方法，如果前端发来的签名的用户（注意，不需要是本人发送）在白名单里，那么就：
1 使用用户的签名信息去erc20里调用permit，修改从买家给卖家在erc20里转账的allowance为nft的价格。
2 在erc721合约里把nft卖给买家。
3 在erc2612的token合约里调用transferfrom 函数给卖家打款。

## 执行

1. Goal: 实现一个EIP2612的Token合约。也就是在erc20基础上添加erc2612里所要求的三个新方法

```sh
mkdir on_chain
forge init
# update foundry.toml and the lib
# copy from old code

touch src/Erc20Eip2612Compatiable.sol
# edit
forge build # success

```
