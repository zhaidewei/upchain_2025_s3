import { startServer } from './api'

async function main() {
  console.log('Starting ERC20 Transfer API Server...')

  try {
    // 启动 API 服务器
    await startServer()
  } catch (error) {
    console.error('Error starting server:', error)
    process.exit(1)
  }
}

// 处理程序退出
process.on('SIGINT', () => {
  console.log('\nReceived SIGINT, shutting down gracefully...')
  process.exit(0)
})

process.on('SIGTERM', () => {
  console.log('\nReceived SIGTERM, shutting down gracefully...')
  process.exit(0)
})

main().catch(console.error)
