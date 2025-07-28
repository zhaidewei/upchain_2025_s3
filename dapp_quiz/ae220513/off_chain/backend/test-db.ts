import { EventIndexer } from './src/indexer'
import { TransferDatabase } from './src/db'
import { CONTRACT_CONFIG } from './src/config'

function safeStringify(obj: any) {
  return JSON.stringify(obj, (key, value) =>
    typeof value === 'bigint' ? value.toString() : value,
    2
  )
}

async function testDatabase() {
  console.log('Testing DuckDB Integration...')
  console.log('Contract address:', CONTRACT_CONFIG.TOKEN_ADDRESS)

  const indexer = new EventIndexer()
  const database = indexer.getDatabase()

  try {
    // 初始化数据库
    await database.initialize()
    console.log('✅ Database initialized successfully')

    // 获取当前区块高度
    const currentBlock = await indexer.getCurrentBlockNumber()
    console.log(`Current block number: ${currentBlock}`)

    // 获取历史事件
    const fromBlock = currentBlock > 10n ? currentBlock - 10n : 0n
    console.log(`🔍 Fetching events from block ${fromBlock} to ${currentBlock}`)

    const events = await indexer.getHistoricalEvents(fromBlock, currentBlock)
    console.log(`✅ Found ${events.length} Transfer events`)

    if (events.length > 0) {
      // 保存到数据库
      const insertedCount = await database.insertTransferEvents(events)
      console.log(`✅ Inserted ${insertedCount} events into database`)

      // 获取数据库统计信息
      const stats = await database.getStats()
      console.log('📊 Database stats:', safeStringify(stats))

      // 查询特定地址的转账记录
      const testAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266' // USER1
      const userTransfers = await database.getTransfersByAddress(testAddress)
      console.log(`📋 Found ${userTransfers.length} transfers for ${testAddress}`)

      if (userTransfers.length > 0) {
        console.log('📄 Sample transfer record:')
        console.log(safeStringify(userTransfers[0]))
      }

      // 获取所有转账记录
      const allTransfers = await database.getAllTransfers(10)
      console.log(`📋 Retrieved ${allTransfers.length} recent transfers`)
    } else {
      console.log('ℹ️  No Transfer events found in recent blocks')
    }

  } catch (error) {
    console.error('❌ Error during database testing:', error)
  } finally {
    // 关闭数据库连接
    database.close()
  }
}

testDatabase().catch(console.error)
