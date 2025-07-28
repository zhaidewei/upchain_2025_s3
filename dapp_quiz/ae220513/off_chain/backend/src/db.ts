import * as duckdb from 'duckdb'
import { TransferEvent } from './indexer'
import { DB_CONFIG } from './config'
import path from 'path'

// 数据库表结构定义
export interface TransferRecord {
  id: number
  block_number: number
  block_hash: string
  transaction_hash: string
  log_index: number
  from_address: string
  to_address: string
  value: string
  value_decimal: number
  timestamp: string
  created_at: string
}

// DuckDB 数据库管理类
export class TransferDatabase {
  private db: duckdb.Database
  private connection: duckdb.Connection

  constructor() {
    const dbPath = path.resolve(DB_CONFIG.DATABASE_PATH)
    this.db = new duckdb.Database(dbPath)
    this.connection = new duckdb.Connection(this.db)
  }

  // 初始化数据库表
  async initialize(): Promise<void> {
    try {
      console.log('Initializing DuckDB database...')

      // 创建 transfer_events 表
      const createTableSQL = `
        CREATE TABLE IF NOT EXISTS transfer_events (
          id INTEGER PRIMARY KEY,
          block_number BIGINT NOT NULL,
          block_hash VARCHAR(66) NOT NULL,
          transaction_hash VARCHAR(66) NOT NULL,
          log_index INTEGER NOT NULL,
          from_address VARCHAR(42) NOT NULL,
          to_address VARCHAR(42) NOT NULL,
          value VARCHAR(78) NOT NULL,
          value_decimal DOUBLE NOT NULL,
          timestamp VARCHAR(30),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(block_number, transaction_hash, log_index)
        )
      `

      await this.executeSQL(createTableSQL)

      // 创建索引以提高查询性能
      const createIndexesSQL = `
        CREATE INDEX IF NOT EXISTS idx_from_address ON transfer_events(from_address);
        CREATE INDEX IF NOT EXISTS idx_to_address ON transfer_events(to_address);
        CREATE INDEX IF NOT EXISTS idx_block_number ON transfer_events(block_number);
        CREATE INDEX IF NOT EXISTS idx_transaction_hash ON transfer_events(transaction_hash);
      `

      await this.executeSQL(createIndexesSQL)

      console.log('Database initialized successfully')
    } catch (error) {
      console.error('Error initializing database:', error)
      throw error
    }
  }

  // 执行 SQL 语句
  private executeSQL(sql: string): Promise<void> {
    return new Promise((resolve, reject) => {
      this.connection.exec(sql, (err) => {
        if (err) {
          reject(err)
        } else {
          resolve()
        }
      })
    })
  }

  // 查询 SQL 语句
  private querySQL<T>(sql: string): Promise<T[]> {
    return new Promise((resolve, reject) => {
      this.connection.all(sql, (err, rows) => {
        if (err) {
          reject(err)
        } else {
          resolve(rows as T[])
        }
      })
    })
  }

  // 将 TransferEvent 转换为 TransferRecord
  private convertToTransferRecord(event: TransferEvent, id: number): TransferRecord {
    // 将 BigInt 转换为字符串和十进制数
    const valueStr = event.value.toString()
    const valueDecimal = Number(event.value) / Math.pow(10, 18) // 假设 18 位小数

    return {
      id,
      block_number: Number(event.blockNumber),
      block_hash: event.blockHash,
      transaction_hash: event.transactionHash,
      log_index: event.logIndex,
      from_address: event.from,
      to_address: event.to,
      value: valueStr,
      value_decimal: valueDecimal,
      timestamp: event.timestamp ? new Date(Number(event.timestamp) * 1000).toISOString() : new Date().toISOString(),
      created_at: new Date().toISOString()
    }
  }

  // 批量插入 Transfer 事件
  async insertTransferEvents(events: TransferEvent[]): Promise<number> {
    if (events.length === 0) {
      return 0
    }

    try {
      console.log(`Inserting ${events.length} transfer events into database...`)

      // 获取下一个 ID
      const nextIdResult = await this.querySQL<{ max_id: number }>('SELECT COALESCE(MAX(id), 0) as max_id FROM transfer_events')
      const nextId = (nextIdResult[0]?.max_id || 0) + 1

      // 准备插入数据
      const records: TransferRecord[] = events.map((event, index) =>
        this.convertToTransferRecord(event, nextId + index)
      )

      // 构建插入语句
      const insertSQL = `
        INSERT INTO transfer_events (
          id, block_number, block_hash, transaction_hash, log_index,
          from_address, to_address, value, value_decimal, timestamp, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT (block_number, transaction_hash, log_index) DO NOTHING
      `

            // 批量插入
      for (const record of records) {
        // 检查是否已存在
        const checkSQL = `SELECT id FROM transfer_events WHERE block_number = ${record.block_number} AND transaction_hash = '${record.transaction_hash}' AND log_index = ${record.log_index}`
        const existing = await this.querySQL<{ id: number }>(checkSQL)

        if (existing.length === 0) {
          const insertSQL = `
            INSERT INTO transfer_events (
              id, block_number, block_hash, transaction_hash, log_index,
              from_address, to_address, value, value_decimal, timestamp, created_at
            ) VALUES (
              ${record.id},
              ${record.block_number},
              '${record.block_hash}',
              '${record.transaction_hash}',
              ${record.log_index},
              '${record.from_address}',
              '${record.to_address}',
              '${record.value}',
              ${record.value_decimal},
              '${record.timestamp}',
              '${record.created_at}'
            )
          `
          await this.executeSQL(insertSQL)
        }
      }

      console.log(`Successfully inserted ${records.length} transfer events`)
      return records.length
    } catch (error) {
      console.error('Error inserting transfer events:', error)
      throw error
    }
  }

    // 根据地址查询转账记录
  async getTransfersByAddress(address: string): Promise<TransferRecord[]> {
    try {
      const sql = `
        SELECT * FROM transfer_events
        WHERE from_address = '${address}' OR to_address = '${address}'
        ORDER BY block_number DESC, log_index DESC
      `

      const records = await this.querySQL<TransferRecord>(sql)
      console.log(`Found ${records.length} transfer records for address ${address}`)
      return records
    } catch (error) {
      console.error('Error querying transfers by address:', error)
      throw error
    }
  }

  // 获取所有转账记录
  async getAllTransfers(limit: number = 100): Promise<TransferRecord[]> {
    try {
      const sql = `
        SELECT * FROM transfer_events
        ORDER BY block_number DESC, log_index DESC
        LIMIT ${limit}
      `

      const records = await this.querySQL<TransferRecord>(sql)
      console.log(`Retrieved ${records.length} transfer records`)
      return records
    } catch (error) {
      console.error('Error querying all transfers:', error)
      throw error
    }
  }

  // 获取数据库统计信息
  async getStats(): Promise<{ total_transfers: number; unique_addresses: number }> {
    try {
      const statsSQL = `
        SELECT
          COUNT(*) as total_transfers,
          COUNT(DISTINCT from_address) + COUNT(DISTINCT to_address) - COUNT(DISTINCT CASE WHEN from_address = to_address THEN from_address END) as unique_addresses
        FROM transfer_events
      `

      const result = await this.querySQL<{ total_transfers: number; unique_addresses: number }>(statsSQL)
      return result[0] || { total_transfers: 0, unique_addresses: 0 }
    } catch (error) {
      console.error('Error getting database stats:', error)
      return { total_transfers: 0, unique_addresses: 0 }
    }
  }

  // 关闭数据库连接
  close(): void {
    this.connection.close()
    this.db.close()
    console.log('Database connection closed')
  }
}
