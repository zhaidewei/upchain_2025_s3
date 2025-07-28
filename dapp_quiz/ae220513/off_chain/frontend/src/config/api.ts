// API 配置
export const API_CONFIG = {
  BASE_URL: 'http://localhost:3000',
  ENDPOINTS: {
    HEALTH: '/health',
    STATS: '/api/stats',
    TRANSFERS: '/api/transfers',
    TRANSFERS_RECENT: '/api/transfers/recent',
    TRANSFERS_BY_ADDRESS: '/api/transfers/address',
  },
}

// API 响应类型
export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

// 转账记录类型
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

// 统计信息类型
export interface StatsResponse {
  total_transfers: number
  unique_addresses: number
}

// API 工具函数
export const apiClient = {
  async get<T>(endpoint: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    const url = new URL(`${API_CONFIG.BASE_URL}${endpoint}`)
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        url.searchParams.append(key, value)
      })
    }

    const response = await fetch(url.toString())
    return response.json()
  },

  async getTransfersByAddress(address: string): Promise<ApiResponse<TransferRecord[]>> {
    return this.get<TransferRecord[]>(API_CONFIG.ENDPOINTS.TRANSFERS_BY_ADDRESS, { address })
  },

  async getStats(): Promise<ApiResponse<StatsResponse>> {
    return this.get<StatsResponse>(API_CONFIG.ENDPOINTS.STATS)
  },

  async getRecentTransfers(limit: number = 10): Promise<ApiResponse<TransferRecord[]>> {
    return this.get<TransferRecord[]>(API_CONFIG.ENDPOINTS.TRANSFERS_RECENT, { limit: limit.toString() })
  },
}
