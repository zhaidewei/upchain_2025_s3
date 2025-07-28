import { publicClient, CONTRACT_CONFIG } from './config'
import { type Log } from 'viem'
import fs from 'fs'
import path from 'path'
import { TransferDatabase } from './db'

// Transfer 事件数据结构
export interface TransferEvent {
  blockNumber: bigint
  blockHash: string
  transactionHash: string
  logIndex: number
  from: string
  to: string
  value: bigint
  timestamp?: number
}

// 事件索引器类
export class EventIndexer {
  private currentBlock: bigint
  private isRunning: boolean = false
  private database: TransferDatabase

  constructor(startBlock: bigint = 0n) {
    this.currentBlock = startBlock
    this.database = new TransferDatabase()
  }

  // 获取当前区块高度
  async getCurrentBlockNumber(): Promise<bigint> {
    try {
      const blockNumber = await publicClient.getBlockNumber()
      console.log(`Current block number: ${blockNumber}`)
      return blockNumber
    } catch (error) {
      console.error('Error getting current block number:', error)
      throw error
    }
  }

  // 获取指定区块范围的 Transfer 事件
  async getTransferEvents(fromBlock: bigint, toBlock: bigint): Promise<TransferEvent[]> {
    try {
      console.log(`Fetching Transfer events from block ${fromBlock} to ${toBlock}`)

      const logs = await publicClient.getLogs({
        address: CONTRACT_CONFIG.TOKEN_ADDRESS as `0x${string}`,
        event: {
          type: 'event',
          name: 'Transfer',
          inputs: [
            { type: 'address', name: 'from', indexed: true },
            { type: 'address', name: 'to', indexed: true },
            { type: 'uint256', name: 'value', indexed: false }
          ]
        },
        fromBlock,
        toBlock,
      })

      const transferEvents: TransferEvent[] = logs.map((log: any) => ({
        blockNumber: log.blockNumber!,
        blockHash: log.blockHash!,
        transactionHash: log.transactionHash!,
        logIndex: log.logIndex!,
        from: log.args?.from as string,
        to: log.args?.to as string,
        value: log.args?.value as bigint,
      }))

      console.log(`Found ${transferEvents.length} Transfer events`)
      return transferEvents
    } catch (error) {
      console.error('Error fetching Transfer events:', error)
      return []
    }
  }

    // 将事件数据保存到 JSON 文件
  async saveEventsToJson(events: TransferEvent[], filename?: string): Promise<void> {
    const defaultFilename = `transfer_events_${Date.now()}.json`
    const filepath = filename || path.join(process.cwd(), defaultFilename)

    try {
      // 处理 BigInt 序列化问题
      const serializableEvents = events.map(event => ({
        ...event,
        blockNumber: event.blockNumber.toString(),
        value: event.value.toString()
      }))

      const data = {
        timestamp: new Date().toISOString(),
        totalEvents: events.length,
        events: serializableEvents
      }

      fs.writeFileSync(filepath, JSON.stringify(data, null, 2))
      console.log(`Events saved to ${filepath}`)
    } catch (error) {
      console.error('Error saving events to JSON:', error)
    }
  }

    // 开始轮询事件
  async startPolling(): Promise<void> {
    if (this.isRunning) {
      console.log('Indexer is already running')
      return
    }

    // 初始化数据库
    await this.database.initialize()

    this.isRunning = true
    console.log('Starting event polling...')

    while (this.isRunning) {
      try {
        const currentBlock = await this.getCurrentBlockNumber()

        if (this.currentBlock < currentBlock) {
          const toBlock = this.currentBlock + BigInt(CONTRACT_CONFIG.BATCH_SIZE - 1)
          const actualToBlock = toBlock > currentBlock ? currentBlock : toBlock

          const events = await this.getTransferEvents(this.currentBlock, actualToBlock)

          if (events.length > 0) {
            // 保存到 JSON 文件
            await this.saveEventsToJson(events)
            // 保存到数据库
            await this.database.insertTransferEvents(events)
          }

          this.currentBlock = actualToBlock + 1n
        }

        // 等待下一次轮询
        await new Promise(resolve => setTimeout(resolve, CONTRACT_CONFIG.POLL_INTERVAL))
      } catch (error) {
        console.error('Error in polling loop:', error)
        await new Promise(resolve => setTimeout(resolve, CONTRACT_CONFIG.POLL_INTERVAL))
      }
    }
  }

  // 停止轮询
  stopPolling(): void {
    this.isRunning = false
    console.log('Stopping event polling...')
    this.database.close()
  }

    // 一次性获取历史事件（用于初始化）
  async getHistoricalEvents(fromBlock: bigint, toBlock: bigint): Promise<TransferEvent[]> {
    console.log(`Fetching historical Transfer events from block ${fromBlock} to ${toBlock}`)

    const allEvents: TransferEvent[] = []
    let currentFromBlock = fromBlock

    while (currentFromBlock <= toBlock) {
      const currentToBlock = currentFromBlock + BigInt(CONTRACT_CONFIG.BATCH_SIZE - 1)
      const actualToBlock = currentToBlock > toBlock ? toBlock : currentToBlock

      const events = await this.getTransferEvents(currentFromBlock, actualToBlock)
      allEvents.push(...events)

      currentFromBlock = actualToBlock + 1n
    }

    return allEvents
  }

  // 获取数据库实例（用于外部查询）
  getDatabase(): TransferDatabase {
    return this.database
  }
}
