import express from 'express'
import cors from 'cors'
import { TransferDatabase } from './db'
import { API_CONFIG } from './config'

// API 响应接口
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

// 转账记录接口
interface TransferRecord {
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

// 统计信息接口
interface StatsResponse {
  total_transfers: number
  unique_addresses: number
}

// 创建 Express 应用
const app = express()

// 中间件
app.use(cors())
app.use(express.json())

// 创建数据库实例
const database = new TransferDatabase()

// 初始化数据库
async function initializeDatabase() {
  try {
    await database.initialize()
    console.log('✅ Database initialized for API server')
  } catch (error) {
    console.error('❌ Failed to initialize database:', error)
    process.exit(1)
  }
}

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'ERC20 Transfer API is running',
    timestamp: new Date().toISOString()
  })
})

// 获取数据库统计信息
app.get('/api/stats', async (req, res) => {
  try {
    const stats = await database.getStats()

    // 处理 BigInt 序列化问题
    const response: StatsResponse = {
      total_transfers: Number(stats.total_transfers),
      unique_addresses: Number(stats.unique_addresses)
    }

    const apiResponse: ApiResponse<StatsResponse> = {
      success: true,
      data: response
    }

    res.json(apiResponse)
  } catch (error) {
    console.error('Error getting stats:', error)
    res.status(500).json({
      success: false,
      error: 'Failed to get database stats'
    })
  }
})

// 根据地址查询转账记录
app.get('/api/transfers/address', async (req, res) => {
  try {
    const { address } = req.query

    // 验证地址格式
    if (!address || typeof address !== 'string' || !address.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid Ethereum address format. Please provide a valid address as query parameter.'
      })
    }

    const transfers = await database.getTransfersByAddress(address)

    // 处理 BigInt 序列化问题
    const serializableTransfers = transfers.map(transfer => ({
      ...transfer,
      id: Number(transfer.id),
      block_number: Number(transfer.block_number),
      log_index: Number(transfer.log_index),
      value_decimal: Number(transfer.value_decimal)
    }))

    const apiResponse: ApiResponse<TransferRecord[]> = {
      success: true,
      data: serializableTransfers,
      message: `Found ${transfers.length} transfers for address ${address}`
    }

    res.json(apiResponse)
  } catch (error) {
    console.error('Error querying transfers by address:', error)
    res.status(500).json({
      success: false,
      error: 'Failed to query transfers'
    })
  }
})

// 获取所有转账记录（分页）
app.get('/api/transfers', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100
    const page = parseInt(req.query.page as string) || 1

    // 验证参数
    if (limit > 1000) {
      return res.status(400).json({
        success: false,
        error: 'Limit cannot exceed 1000'
      })
    }

    const transfers = await database.getAllTransfers(limit)

    // 处理 BigInt 序列化问题
    const serializableTransfers = transfers.map(transfer => ({
      ...transfer,
      id: Number(transfer.id),
      block_number: Number(transfer.block_number),
      log_index: Number(transfer.log_index),
      value_decimal: Number(transfer.value_decimal)
    }))

    const apiResponse: ApiResponse<TransferRecord[]> = {
      success: true,
      data: serializableTransfers,
      message: `Retrieved ${transfers.length} transfers`
    }

    res.json(apiResponse)
  } catch (error) {
    console.error('Error querying all transfers:', error)
    res.status(500).json({
      success: false,
      error: 'Failed to query transfers'
    })
  }
})

// 获取最近的转账记录
app.get('/api/transfers/recent', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10

    if (limit > 100) {
      return res.status(400).json({
        success: false,
        error: 'Limit cannot exceed 100 for recent transfers'
      })
    }

    const transfers = await database.getAllTransfers(limit)

    // 处理 BigInt 序列化问题
    const serializableTransfers = transfers.map(transfer => ({
      ...transfer,
      id: Number(transfer.id),
      block_number: Number(transfer.block_number),
      log_index: Number(transfer.log_index),
      value_decimal: Number(transfer.value_decimal)
    }))

    const apiResponse: ApiResponse<TransferRecord[]> = {
      success: true,
      data: serializableTransfers,
      message: `Retrieved ${transfers.length} recent transfers`
    }

    res.json(apiResponse)
  } catch (error) {
    console.error('Error querying recent transfers:', error)
    res.status(500).json({
      success: false,
      error: 'Failed to query recent transfers'
    })
  }
})

// 错误处理中间件
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('API Error:', err)
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  })
})

// 404 处理
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  })
})

// 启动服务器
async function startServer() {
  await initializeDatabase()

  const port = API_CONFIG.PORT
  app.listen(port, () => {
    console.log(`🚀 ERC20 Transfer API server running on http://localhost:${port}`)
    console.log('📋 Available endpoints:')
    console.log(`  GET  /health                    - Health check`)
    console.log(`  GET  /api/stats                 - Database statistics`)
    console.log(`  GET  /api/transfers/address?address=0x... - Get transfers by address`)
    console.log(`  GET  /api/transfers             - Get all transfers (with limit)`)
    console.log(`  GET  /api/transfers/recent      - Get recent transfers`)
  })
}

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down API server...')
  database.close()
  process.exit(0)
})

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down API server...')
  database.close()
  process.exit(0)
})

export { startServer }
