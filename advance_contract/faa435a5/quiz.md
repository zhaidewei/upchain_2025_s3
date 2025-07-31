#[quiz](https://decert.me/challenge/faa435a5-f462-4f92-a209-3a7e8fdc4d81)

Quiz#1
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

permitPrePay() : 调用token的 permit 进行授权
claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。
请贴出你的代码 github ，代码需包含合约，multicall 调用封装，Merkel 树的构建以及测试用例。

## Analysis

1. Get the base from previsou [project](https://decert.me/quests/fc66ef6c-35db-4ee7-b11d-c3b2d3fa356a)

2. Add test case and initialization script.

3. Add Merkel tree hash value to NFTMarket contract. And require the permit buy signature contains Merkel tree hash

4. Get Multicall example.

5. Design this two functions (?):
permitPrePay() at NFTMarket contract, calls Erc20 Permit method, approve NFTMarket to transfer Erc20 Token.
claimNFT() at NFTMarket

6. No need to make any frontend, just use typescrit backend cli tool

## Execution

### 1 ✅ Copy from [this](https://github.com/zhaidewei/upchain_2025_s3/tree/main/dapp_quiz/fc66ef6c/on_chain)

Then there are below contracts:

* Erc20Eip2612Compatiable: Erc20 contract with permit
* AirdopMerkleNFTMarket: NFT Market contract
* BaseErc721: NFT contract.

`forge test` must success ✅

### 2 An Anvil facing initialize script

Make script `initialize_anvil.sh` to do below

* Set 3 users address and private key to env vars: admin, user1, user2
* Deploy contracts: erc20 using admin user.
* Admin user Initialize mint 1000 Token, then admin user give user1 100 Token, user 2 10 Token

* Admin user deploy nft using admin user.
admin user mint 2 nft, tokenid = 1 and 2.
admin user set owner to user1

* Admin user deploy nft market contract, and sets relationship with erc20 and nft

* Test:
1. Balance in erc20
2. Ownership of these two token.
3. [Hold on now] generate a permit buy Typescript to simulate user 2 signs and buys nft tokenid 2 from user 1
