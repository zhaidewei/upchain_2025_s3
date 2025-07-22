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
