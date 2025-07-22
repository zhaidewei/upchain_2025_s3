# [Quiz](https://decert.me/challenge/a1a9aff6-1788-4254-bc47-405cc529bbd1)

为 NFTMarket 项目添加前端，并接入 AppKit 进行前端登录，并实际操作使用 WalletConnect 进行登录（需要先安装手机端钱包）。

并在 NFTMarket 前端添加上架操作，切换另一个账号后可使用 Token 进行购买 NFT。

提交 github 仓库地址，请在仓库中包含 NFT 上架后的截图。

## 分析

可以把这道题分解成两部分：
1. NFTMarket （3个合约部署入链）这个可以用forge命令手动操作。
2. 用react 和next js 写一个app （包括前后端）使用WalletConnect 和AppKit。

## 操作
### 1 本地anvil部署操作


```sh
export ROOT_PATH=/Users/zhaidewei/upchain_2025_s3/foundry_quiz/08973815/src
forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/ExtendedERC20WithData.sol:ExtendedERC20WithData --broadcast
Compiler run successful!
#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
#Transaction hash: 0x12e63a980eb71bc24076485e4cd85c376f9e1cb1fe7288bd8e685ed07a5a3218
export ExtendedERC20WithData="0x5FbDB2315678afecb367f032d93F642f64180aa3"

forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/ExtendedERC721.sol:ExtendedERC721 --broadcast
#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
#Transaction hash: 0x9de1d89b51111dcb93eb7136d921a192cf0b47fc03f4a7843490ddc6cd104a92
#export ExtendedERC721="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
export ExtendedERC721="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"


forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/NftMarket.sol:NFTMarket --broadcast \
--constructor-args $ExtendedERC20WithData $ExtendedERC721

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x0165878A594ca255338adfa4d48449f69242Eb8F
#Transaction hash: 0x044c3c6035bdaf668c6354dca9d109d26e6881f98cfd028ed4bf2336501717cf
export NFTMarket="0x0165878A594ca255338adfa4d48449f69242Eb8F"
```


### 2 前端程序

要使用walletconnect，需要先在walletconnect上注册一个项目，并且获取项目id


```sh
export admin="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
cast send $ExtendedERC721 \
  "mint(address,uint256)" \
  $admin \
  1 \
  --rpc-url local \
  --account anvil-tester \
  --password ''
```



```sh
#查询上架信息
cast call $NFTMarket "getListing(uint256)" 2 --rpc-url local
```
```sh
# manual listing
cast send $ExtendedERC721 "approve(address,uint256)" $NFTMarket 1 --rpc-url local --account anvil-tester --password ''

cast send $NFTMarket "list(uint256,uint256)" 1 1e16 --rpc-url local --account anvil-tester --password ''
```
