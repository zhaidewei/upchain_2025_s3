import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { apiClient } from '../config/api'
import type { TransferRecord } from '../config/api'

export function TransferStats() {
  const { address, isConnected } = useAccount()
  const [transfers, setTransfers] = useState<TransferRecord[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const fetchTransfers = async () => {
      if (!address) return

      setLoading(true)
      try {
        const response = await apiClient.getTransfersByAddress(address)
        if (response.success && response.data) {
          setTransfers(response.data)
        }
      } catch (error) {
        console.error('Failed to fetch transfers for stats:', error)
      } finally {
        setLoading(false)
      }
    }

    if (isConnected && address) {
      fetchTransfers()
    }
  }, [isConnected, address])

  if (!isConnected) {
    return null
  }

  const stats = {
    totalTransfers: transfers.length,
    totalReceived: transfers
      .filter(t => t.to_address.toLowerCase() === address?.toLowerCase())
      .reduce((sum, t) => sum + t.value_decimal, 0),
    totalSent: transfers
      .filter(t => t.from_address.toLowerCase() === address?.toLowerCase())
      .reduce((sum, t) => sum + t.value_decimal, 0),
    recentActivity: transfers
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
      .slice(0, 3)
  }

  return (
    <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-xl border border-gray-200 p-6">
      <div className="flex items-center space-x-3 mb-6">
        <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <h3 className="text-xl font-semibold text-gray-900">
          Transfer Statistics
        </h3>
      </div>

      {loading ? (
        <div className="text-center py-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
          <p className="mt-3 text-sm text-gray-600 font-medium">Loading stats...</p>
        </div>
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gradient-to-r from-blue-50 to-blue-100 border border-blue-200 rounded-2xl p-6 hover:shadow-lg transition-all duration-200">
              <div className="flex items-center justify-between mb-3">
                <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center">
                  <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                  </svg>
                </div>
                <span className="text-xs font-medium text-blue-600 bg-blue-100 px-2 py-1 rounded-full">
                  Total
                </span>
              </div>
              <h4 className="text-sm font-medium text-blue-800 mb-1">Total Transfers</h4>
              <p className="text-3xl font-bold text-blue-900">{stats.totalTransfers}</p>
            </div>

            <div className="bg-gradient-to-r from-green-50 to-green-100 border border-green-200 rounded-2xl p-6 hover:shadow-lg transition-all duration-200">
              <div className="flex items-center justify-between mb-3">
                <div className="w-8 h-8 bg-green-500 rounded-lg flex items-center justify-center">
                  <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 11l5-5m0 0l5 5m-5-5v12" />
                  </svg>
                </div>
                <span className="text-xs font-medium text-green-600 bg-green-100 px-2 py-1 rounded-full">
                  Received
                </span>
              </div>
              <h4 className="text-sm font-medium text-green-800 mb-1">Total Received</h4>
              <p className="text-3xl font-bold text-green-900">+{stats.totalReceived.toFixed(2)}</p>
            </div>

            <div className="bg-gradient-to-r from-red-50 to-red-100 border border-red-200 rounded-2xl p-6 hover:shadow-lg transition-all duration-200">
              <div className="flex items-center justify-between mb-3">
                <div className="w-8 h-8 bg-red-500 rounded-lg flex items-center justify-center">
                  <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 13l-5 5m0 0l-5-5m5 5V6" />
                  </svg>
                </div>
                <span className="text-xs font-medium text-red-600 bg-red-100 px-2 py-1 rounded-full">
                  Sent
                </span>
              </div>
              <h4 className="text-sm font-medium text-red-800 mb-1">Total Sent</h4>
              <p className="text-3xl font-bold text-red-900">-{stats.totalSent.toFixed(2)}</p>
            </div>
          </div>

          {stats.recentActivity.length > 0 && (
            <div className="bg-gradient-to-r from-gray-50 to-blue-50 rounded-2xl p-6">
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-6 h-6 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h4 className="text-sm font-semibold text-gray-700">Recent Activity</h4>
              </div>
              <div className="space-y-3">
                {stats.recentActivity.map((transfer) => {
                  const isIncoming = transfer.to_address.toLowerCase() === address?.toLowerCase()
                  return (
                    <div key={transfer.id} className="flex justify-between items-center bg-white/60 rounded-xl p-3">
                      <div className="flex items-center space-x-3">
                        <div className={`w-3 h-3 rounded-full ${
                          isIncoming ? 'bg-green-500' : 'bg-red-500'
                        }`}></div>
                        <span className={`text-sm font-medium ${
                          isIncoming ? 'text-green-600' : 'text-red-600'
                        }`}>
                          {isIncoming ? '📥 Received' : '📤 Sent'} {transfer.value_decimal} tokens
                        </span>
                      </div>
                      <span className="text-xs text-gray-500 bg-white/80 px-2 py-1 rounded-lg">
                        {new Date(transfer.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
