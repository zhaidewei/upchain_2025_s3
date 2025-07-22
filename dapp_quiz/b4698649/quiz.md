#[Link](https://decert.me/challenge/b4698649-25b2-45ae-9bb5-23da0c49e491)

在[NFTMarket 合约中](https://github.com/zhaidewei/upchain_2025_s3/tree/main/foundry_quiz/08973815/)
在上架（list）和买卖函数（buyNFT 及 tokensReceived）中添加相应事件，
在后台监听上架和买卖事件，如果链上发生了上架或买卖行为，打印出相应的日志。


## 分析

### 第一部分：合约
1 版本1 使用本地anviel 测试链，使用forge script，部署NFTMarket合约。部署者是Anvil的第一个user，nft admin
admin: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

2 构造csat命令去完成合约部署后的list
admin完成list
3 用user1去获取代币
使用admin给user1账户转erc20 代币
user1，0x70997970C51812dc3A010C7d01b50e0d17dc79C8， 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
在ERC20token上获取代币
4 user1 去使用transferWithCallback方法给admin在erc20合约里的地址转账买nft，

预期触发TransferWithCallbackAndData事件和event NFTSold事件

### 第二部分：监听
需要一个后端typescript 脚本，使用viem库，websocket连接本地的Anviel环境，监听相关事件。

在之前的代码里，我已经实现了`NFTListed`

`event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);`
`event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);`

### 代码实现

1. deploy ExtendedERC20WithData
```sh
ROOT_PATH=/Users/zhaidewei/upchain_2025_s3/foundry_quiz/08973815/src
forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/ExtendedERC20WithData.sol:ExtendedERC20WithData --broadcast

# Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
# Transaction hash: 0xfb37a015dc7948239445616c6bc331170a1fbb1543b560e81bcc7ff9a7ee0121
```

2. Deploy ERC721

```sh
forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/ExtendedERC721.sol:ExtendedERC721 --broadcast

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
#Transaction hash: 0x2c7946863d95509448035fc4c07d9de039667c59888578d015ff54f41197cb3c
```

3. Deploy NFTMarket

```sh
forge create --rpc-url local --account anvil-tester --password '' $ROOT_PATH/NftMarket.sol:NFTMarket --broadcast \
--constructor-args "0x5FbDB2315678afecb367f032d93F642f64180aa3" "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
#Transaction hash: 0x343e51a94fc52dc328eb102daca8a621ad794234ec4c0774e082edf873a21152
```

4. 编写和启动监听

```typescript
import { createPublicClient, webSocket, parseAbi, formatEther, getAddress } from 'viem'
import { anvil } from 'viem/chains'

// NFTMarket 合约地址 (从部署信息获取)
const NFT_MARKET_ADDRESS = getAddress('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0')

// 定义合约ABI - 只包含事件定义
const nftMarketAbi = parseAbi([
  'event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price)',
  'event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price)'
])

// 创建WebSocket客户端连接到本地Anvil节点
const client = createPublicClient({
  chain: anvil,
  transport: webSocket('ws://127.0.0.1:8545')
})

console.log('🚀 开始监听NFTMarket合约事件...')
console.log(`📍 合约地址: ${NFT_MARKET_ADDRESS}`)
console.log(`🌐 连接节点: ws://127.0.0.1:8545`)
console.log('='.repeat(60))

// 监听所有相关事件
const unwatch = client.watchEvent({
  address: NFT_MARKET_ADDRESS,
  events: nftMarketAbi,
  onLogs: (logs) => {
    logs.forEach((log: any) => {
      if (log.eventName === 'NFTListed') {
        const { tokenId, seller, price } = log.args
        console.log('\n🏷️  NFT上架事件 (NFTListed)')
        console.log(`   Token ID: ${tokenId}`)
        console.log(`   卖家地址: ${seller}`)
        console.log(`   价格: ${formatEther(price)} Token`)
        console.log(`   区块号: ${log.blockNumber}`)
        console.log(`   交易哈希: ${log.transactionHash}`)
        console.log('-'.repeat(40))
      } else if (log.eventName === 'NFTSold') {
        const { tokenId, seller, buyer, price } = log.args
        console.log('\n💰 NFT售出事件 (NFTSold)')
        console.log(`   Token ID: ${tokenId}`)
        console.log(`   卖家地址: ${seller}`)
        console.log(`   买家地址: ${buyer}`)
        console.log(`   成交价格: ${formatEther(price)} Token`)
        console.log(`   区块号: ${log.blockNumber}`)
        console.log(`   交易哈希: ${log.transactionHash}`)
        console.log('-'.repeat(40))
      }
    })
  }
})

// 处理程序退出
process.on('SIGINT', () => {
  console.log('\n\n⏹️  停止监听事件...')
  unwatch()
  process.exit(0)
})

// 保持程序运行
console.log('✅ 事件监听已启动，按 Ctrl+C 退出')

```

5. admin给user1 设置初始token
使用csat呼叫合约ExtendedERC20WithData (addr:0x5FbDB2315678afecb367f032d93F642f64180aa3) 的function transfer(address _to, uint256 _value) public returns (bool success)方法，设置 1 eth
admin --account anvil-tester
user1 address my MetaMask user 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2

```sh
export ExtendedERC20WithData="0x5FbDB2315678afecb367f032d93F642f64180aa3"
export metaMask="0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2"
cast send $ExtendedERC20WithData \
  "transfer(address,uint256)" \
  $metaMask \
  1e18 \
  --rpc-url local \
  --account anvil-tester \
  --password ''
```

6 mint
admin 用户去mint 第一个nft token
```sh
export ERC721="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
export admin="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
cast send $ERC721 \
  "mint(address,uint256)" \
  $admin \
  1 \
  --rpc-url local \
  --account anvil-tester \
  --password ''
```

7 approve for NFT market

```sh
export NFT_MARKET="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
cast send $ERC721 \
  "approve(address,uint256)" \
  $NFT_MARKET \
  1 \
  --rpc-url local \
  --account anvil-tester \
  --password ''
```

7 在nft market 上 listing

```sh
export NFT_MARKET="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
cast send $NFT_MARKET \
  "list(uint256,uint256)" \
  1 \
  1e17 \
  --rpc-url local \
  --account anvil-tester \
  --password ''
```
```sh
🏷️  NFT上架事件 (NFTListed)
   Token ID: 1
   卖家地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   价格: 0.1 Token
   区块号: 8
   交易哈希: 0x98976d43ac0746b574e882bf6ceadc13599baeef0b6296813bc3deb3c53feda1
```

7 给metaMask用户一点Anvil的以太币
```sh
cast send $metaMask --value 1ether --rpc-url local --account anvil-tester --password ''
```

8 metaMask user 使用csat去呼叫合约ExtendedERC20WithData

```sh
DATA=$(cast abi-encode "f(uint256)" 1)
cast send $ExtendedERC20WithData \
  "transferWithCallback(address,uint256,bytes)" \
  $NFT_MARKET \
  1e17 \
  $DATA\
  --rpc-url local \
  --account myMetaMaskAcc \
  --password ''
  ```

```sh

💰 NFT售出事件 (NFTSold)
   Token ID: 1
   卖家地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   买家地址: 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
   成交价格: 0.1 Token
   区块号: 10
   交易哈希: 0x037a5429de9d197fb66932948693be5cca05c91f1a3f937c77aac9b5fa21eeb0
----------------------------------------
```
