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

1. ✅ 实现一个EIP2612的Token合约。也就是在erc20基础上添加erc2612里所要求的三个新方法

2. ✅ 用从之前的[tokenBank合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/dapp_quiz/56e455b3/contracts/src/TokenBank.sol)作为基础，添加permitDeposit功能, 我选择不在tokenbank里去验证签名，直接丢给ERC20 合约去验证。通过permit方法去修改用户的allowarence为tokenBank

3.前端，支持通过签名存款的功能。用户可以点击签名存款，然后前端发送这个eip712的结构化签名给用户钱包。
钱包签名后，签名返回前端。

4.发行一个[NFT合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/foundry_quiz/08973815/src/ExtendedERC721.sol)

拿来之前的[NTFMarket 合约](https://github.com/zhaidewei/upchain_2025_s3/blob/main/foundry_quiz/08973815/src/NftMarket.sol)发行一个NFTMarket合约

之前实现了一笔交易从ERC20发起，转账后，向NFTMarket合约发起购买交易。

5 给nftmarket合约添加一个管理员地址，管理员可以修改白名单信息，也就是一个address到bool到映射，true是白，false是黑
admin可以修改值，但是不用删除记录
在合约里添加白名单地址，也就是合法买家地址。

在NFTMarket里添加permitBuy()方法，如果前端发来的签名的用户（注意，不需要是本人发送）在白名单里，那么就：
1 使用用户的签名信息去erc20里调用permit，修改从买家给卖家在erc20里转账的allowance为nft的价格。
2 在erc721合约里把nft卖给买家。
3 在erc2612的token合约里调用transferfrom 函数给卖家打款。

## 执行1-3

1. ✅ Goal: 实现一个EIP2612的Token合约。也就是在erc20基础上添加erc2612里所要求的三个新方法
2. ✅ Goal: 实现一个支持permitDeposit方法的tokenbank
3. ✅ Goal：给tokenBank实现一个前端。


```prompt
在off_chain目录下，实现一个前端deapp程序。
使用react，wagmi.
要求具备以下功能：
1. 和部署好的Erc20Eip2612Compatiable 以及 TokenBank 交互。ABI见`off_chain/abi/`folder
2. 实现metaMask钱包登陆
3. 实现查看用户在Erc20Eip2612Compatiable 以及 TokenBank 中账户余额的界面
4. 实现利用TokenBank的permitDeposit 方法去签名存款。这种structure sign 需要的context需要前端从合约里提取。如果缺少方法，告诉我，我可以修改合约。
5. 不要做不相关的功能，keep it simple，this is just a demo
6. 目标合约我已经部署在Anvil网络里了，看quiz.md下面的记录
```

```sh
cd ../off_chain && npm create vite@latest tokenbank-frontend -- --template react-ts
npm install
npm install wagmi viem @wagmi/core @wagmi/connectors
```sh
# 3.1 Prepare
export ON_CHAIN_PATH=/Users/zhaidewei/upchain_2025_s3/dapp_quiz/fc66ef6c/on_chain
export anvil="http://localhost:8545"
export VERSION="1.0"

# 3.1 Deploy ERC20_EIP2612
cd $ON_CHAIN_PATH
forge create --rpc-url $anvil --account anvil-tester --password '' src/Erc20Eip2612Compatiable.sol:Erc20Eip2612Compatiable --broadcast --constructor-args $VERSION
#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
#Transaction hash: 0x0e5689174cdb4b42d65fa00c7358b9600c80114659499ed106670b561186bae6
export ERC20=0x5FbDB2315678afecb367f032d93F642f64180aa3

forge inspect src/Erc20Eip2612Compatiable.sol:Erc20Eip2612Compatiable abi --json > ../off_chain/abi_Erc20Eip2612Compatiable.json

# 3.2 Deploy TokenBank
forge create --rpc-url $anvil --account anvil-tester --password '' src/TokenBank.sol:TokenBank --broadcast --constructor-args $ERC20
# Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
# Transaction hash: 0x99dbf457806075cc33cf516376b06275feb4eb590c9bbf442f5b63045868a764

forge inspect src/TokenBank.sol:TokenBank abi --json > ../off_chain/abi_TokenBank.json

export ERC20=0x5FbDB2315678afecb367f032d93F642f64180aa3
export tokenBank=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export adminAddress=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
cast call --rpc-url http://localhost:8545 $ERC20 "balanceOf(address)(uint256)" $adminAddress
# 1000000000000000000000000000 [1e27]

cast call --rpc-url http://localhost:8545 $tokenBank "getUserBalance(address)(uint256)" $adminAddress
# 0
```

## 执行4

```sh
# 先部署之前的NFT合约
export ON_CHAIN_PATH=/Users/zhaidewei/upchain_2025_s3/dapp_quiz/fc66ef6c/on_chain
export anvil="http://localhost:8545"
forge create --rpc-url $anvil --account anvil-tester --password '' src/ExtendedErc721.sol:ExtendedERC721 --broadcast

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
#Transaction hash: 0x5c626fb56261a17e9d965b0e5020058a5056a3ca97ae9f5c51ba91a518e71c4a
```
