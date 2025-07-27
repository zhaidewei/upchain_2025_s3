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

### 1. ✅ Goal: 实现一个EIP2612的Token合约

也就是在erc20基础上添加erc2612里所要求的三个新方法。

### 2. ✅ Goal: 实现一个支持permitDeposit方法的tokenbank

我选择不在tokenbank里去验证签名，直接丢给ERC20 合约去验证。通过permit方法去修改用户的allowarence为tokenBank

### 3. ✅ Goal：给tokenBank实现一个前端

支持通过签名存款的功能。用户可以点击签名存款，然后前端发送这个eip712的结构化签名给用户钱包。
钱包签名后，签名返回前端。

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

### 4 ✅ 部署一个简单版本的ERC721合约，然后mint

```sh
# 先部署之前的NFT合约
export ON_CHAIN_PATH=/Users/zhaidewei/upchain_2025_s3/dapp_quiz/fc66ef6c/on_chain
export anvil="http://localhost:8545"
forge create --rpc-url $anvil --account anvil-tester --password '' src/BaseErc721.sol:BaseERC721 --broadcast --constructor-args DNft721 DNFT

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
#Transaction hash: 0x414db8f2711c1f807424a418e688c62dfcbbaf374835e5467147ab81758a8ca9

forge inspect src/BaseErc721.sol:BaseERC721 abi --json > BaseERC721.json

#MINT
export NFT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
export Dewei=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
export USER3=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
cast send $NFT "mint(address)" $Dewei --account anvil-tester --password '' # 0
cast send $NFT "mint(address)" $USER3 --account anvil-tester --password '' # 1
cast send $NFT "mint(address)(uint256)" $USER3 --account anvil-tester --password ''

```


### 5 引入管理员EIP712签名的白名单验证 ✅

#### 5.1 NFTMarket合约

给nftmarket合约添加一个管理员地址，管理员可以签署一个EIP712签名，声明一个buyer地址是不是可以购买NFT。这里需要引入一个EIP712签名。

```sh
#准备脚本
export ERC20=0x5FbDB2315678afecb367f032d93F642f64180aa3
export NFT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
export DOMAIN_NAME=DNFT
export VERSION="1.0"
forge create --rpc-url $anvil --account anvil-tester --password '' src/NFTMarket.sol:NFTMarket --broadcast --constructor-args $ERC20 $NFT $DOMAIN_NAME $VERSION

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x610178dA211FEF7D417bC0e6FeD39F05609AD788
#Transaction hash: 0x946fdea217072122847183f3ac59e30aec7474ee9d91205c5dd4ac36d2150edd
export NFTMARKETOWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export NFTMARKET=0x610178dA211FEF7D417bC0e6FeD39F05609AD788



# approve nft to market
export BUYER3_PRIVATEKEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
export NFT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
export NFTMARKET=0x610178dA211FEF7D417bC0e6FeD39F05609AD788
export anvil="http://localhost:8545"

cast send \
--rpc-url $anvil \
--private-key $BUYER3_PRIVATEKEY \
$NFT \
"approve(address,uint256)" \
$NFTMARKET "2"

# listing
export BUYER3_PRIVATEKEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
export NFTMARKET=0x610178dA211FEF7D417bC0e6FeD39F05609AD788
export anvil="http://localhost:8545"
cast send \
--rpc-url $anvil \
--private-key $BUYER3_PRIVATEKEY \
$NFTMARKET \
"list(uint256,uint256)" \
"2" "1000000000" # 1e-9 token

```

#### 5.2 typescript 工具做签名 ✅

前端部分，为了简单，用typescript的CLI工具做，里面支持admin 给buyer签署白名单签名。

1. NFTMarket 合约需要有个admin
2. admin离线签署EIP712 sig，声明某buyer地址可以购买NFT
3. 这个Buyer拿到sig后，亲自呼叫permitBuy方法

### 6 permitBuy实现 ✅

配合第5步，在NFTMarket合约里实现可以验证EIP712的permitBuy

不做前端，用cast命令模拟操作了。
买家，需要先在erc20里approve 给NFTMarket合约
然后获取白名单签名
然后调用permitBuy函数
permitBuy函数首先验证签名，使用deadline 而不是nonce，因为并发性
其次尝试执行buyNFT操作，如果失败就revert，另外，隐藏buyNFT操作，不允许买家绕开permitBuy操作

具体实现见`step6.sh`
