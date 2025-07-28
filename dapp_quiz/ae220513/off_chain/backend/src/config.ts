import { createPublicClient, http } from 'viem'
import { anvil } from 'viem/chains'
import dotenv from 'dotenv'

// 加载环境变量
dotenv.config()

// 区块链连接配置
export const publicClient = createPublicClient({
  chain: anvil,
  transport: http('http://127.0.0.1:8545'),
})

// 合约配置
export const CONTRACT_CONFIG = {
  // 这里需要填入部署的ERC20合约地址
  // 可以从 deploy_and_test.sh 脚本的输出中获取
  TOKEN_ADDRESS: process.env.TOKEN_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3',

  // ERC20 Transfer 事件签名
  // 是的，这是ERC20标准定义的Transfer事件
  TRANSFER_EVENT_SIGNATURE: 'Transfer(address indexed from,address indexed to,uint256 value)',

  // 轮询配置
  START_BLOCK: parseInt(process.env.START_BLOCK || '0'),
  BATCH_SIZE: 3, // 每次轮询3个区块

  // 轮询间隔 (毫秒)
  POLL_INTERVAL: 5000,
}

// 数据库配置
export const DB_CONFIG = {
  DATABASE_PATH: './transfer_events.db',
}

// API配置
export const API_CONFIG = {
  PORT: parseInt(process.env.PORT || '3000'),
}
