import { EventIndexer } from './src/indexer'
import { CONTRACT_CONFIG } from './src/config'

async function testIndexer() {
  console.log('Testing ERC20 Transfer Event Indexer...')
  console.log('Contract address:', CONTRACT_CONFIG.TOKEN_ADDRESS)

  const indexer = new EventIndexer()

  try {
    // 测试获取当前区块高度
    const currentBlock = await indexer.getCurrentBlockNumber()
    console.log(`✅ Current block number: ${currentBlock}`)

    // 测试获取历史事件（最近5个区块）
    const fromBlock = currentBlock - 5n
    console.log(`🔍 Fetching events from block ${fromBlock} to ${currentBlock}`)

    const events = await indexer.getHistoricalEvents(fromBlock, currentBlock)
    console.log(`✅ Found ${events.length} Transfer events`)

    if (events.length > 0) {
      console.log('📄 Sample event:')
      // 处理 BigInt 序列化问题
      const sampleEvent = {
        ...events[0],
        value: events[0].value.toString(),
        blockNumber: events[0].blockNumber.toString()
      }
      console.log(JSON.stringify(sampleEvent, null, 2))

      // 保存到文件
      await indexer.saveEventsToJson(events, 'test_events.json')
      console.log('✅ Events saved to test_events.json')
    } else {
      console.log('ℹ️  No Transfer events found in recent blocks')
      console.log('💡 Make sure you have deployed the ERC20 contract and made some transfers')
    }

  } catch (error) {
    console.error('❌ Error during testing:', error)
  }
}

testIndexer().catch(console.error)
