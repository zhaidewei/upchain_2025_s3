import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { apiClient } from '../config/api'
import type { TransferRecord } from '../config/api'

export function TransferHistory() {
  const { address, isConnected } = useAccount()
  const [transfers, setTransfers] = useState<TransferRecord[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string>('')

  const fetchTransfers = async () => {
    if (!address) return

    setLoading(true)
    setError('')

    try {
      const response = await apiClient.getTransfersByAddress(address)
      if (response.success && response.data) {
        setTransfers(response.data)
      } else {
        setError(response.error || 'Failed to fetch transfers')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (isConnected && address) {
      fetchTransfers()
    }
  }, [isConnected, address])

  if (!isConnected) {
    return (
      <div className="bg-gradient-to-r from-yellow-50 to-orange-50 border border-yellow-200 rounded-2xl p-8 text-center">
        <div className="w-16 h-16 bg-gradient-to-r from-yellow-400 to-orange-500 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        <h3 className="text-lg font-semibold text-yellow-800 mb-2">
          Wallet Not Connected
        </h3>
        <p className="text-yellow-700">
          Please connect your wallet to view transfer history
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-gray-900">
            Transfer History
          </h2>
        </div>
        <button
          onClick={fetchTransfers}
          disabled={loading}
          className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 disabled:from-gray-400 disabled:to-gray-500 text-white font-medium py-2 px-4 rounded-xl transition-all duration-200 shadow-lg hover:shadow-xl transform hover:scale-105 disabled:transform-none"
        >
          {loading ? (
            <div className="flex items-center space-x-2">
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              <span>Loading...</span>
            </div>
          ) : (
            <div className="flex items-center space-x-2">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              <span>Refresh</span>
            </div>
          )}
        </button>
      </div>

      {error && (
        <div className="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-2xl p-4">
          <div className="flex items-center space-x-3">
            <div className="w-6 h-6 bg-red-500 rounded-full flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <p className="text-red-800 font-medium">{error}</p>
          </div>
        </div>
      )}

      {loading && (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-blue-500 border-t-transparent"></div>
          <p className="mt-4 text-gray-600 font-medium">Loading transfers...</p>
        </div>
      )}

      {!loading && transfers.length === 0 && !error && (
        <div className="bg-gradient-to-r from-gray-50 to-blue-50 border border-gray-200 rounded-2xl p-12 text-center">
          <div className="w-16 h-16 bg-gradient-to-r from-gray-400 to-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-700 mb-2">No Transfers Found</h3>
          <p className="text-gray-600">No transfer records found for this address</p>
        </div>
      )}

      {!loading && transfers.length > 0 && (
        <div className="space-y-4">
          {transfers.map((transfer) => (
            <TransferCard key={transfer.id} transfer={transfer} userAddress={address!} />
          ))}
        </div>
      )}
    </div>
  )
}

interface TransferCardProps {
  transfer: TransferRecord
  userAddress: string
}

function TransferCard({ transfer, userAddress }: TransferCardProps) {
  const isIncoming = transfer.to_address.toLowerCase() === userAddress.toLowerCase()
  const isOutgoing = transfer.from_address.toLowerCase() === userAddress.toLowerCase()

  return (
    <div className={`border rounded-2xl p-6 shadow-lg hover:shadow-xl transition-all duration-200 transform hover:scale-[1.02] ${
      isIncoming ? 'border-green-200 bg-gradient-to-r from-green-50 to-emerald-50' :
      isOutgoing ? 'border-red-200 bg-gradient-to-r from-red-50 to-pink-50' :
      'border-gray-200 bg-gradient-to-r from-gray-50 to-blue-50'
    }`}>
      <div className="flex justify-between items-start">
        <div className="flex-1">
          <div className="flex items-center space-x-3 mb-4">
            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
              isIncoming ? 'bg-green-100 text-green-800' :
              isOutgoing ? 'bg-red-100 text-red-800' :
              'bg-gray-100 text-gray-800'
            }`}>
              {isIncoming ? '📥 Received' : isOutgoing ? '📤 Sent' : '🔄 Transfer'}
            </span>
            <span className="text-sm text-gray-500 bg-white/60 px-2 py-1 rounded-lg">
              Block #{transfer.block_number}
            </span>
          </div>

          <div className="space-y-3">
            <div className="bg-white/60 rounded-xl p-3">
              <p className="text-sm font-medium text-gray-700 mb-1">From</p>
              <p className="text-xs text-gray-600 font-mono break-all">{transfer.from_address}</p>
            </div>
            <div className="bg-white/60 rounded-xl p-3">
              <p className="text-sm font-medium text-gray-700 mb-1">To</p>
              <p className="text-xs text-gray-600 font-mono break-all">{transfer.to_address}</p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-white/60 rounded-xl p-3">
                <p className="text-sm font-medium text-gray-700 mb-1">Amount</p>
                <p className="text-sm font-semibold text-gray-900">{transfer.value_decimal} tokens</p>
              </div>
              <div className="bg-white/60 rounded-xl p-3">
                <p className="text-sm font-medium text-gray-700 mb-1">Raw Value</p>
                <p className="text-xs text-gray-600 font-mono">{transfer.value}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="text-right ml-4">
          <p className={`text-2xl font-bold ${
            isIncoming ? 'text-green-600' : isOutgoing ? 'text-red-600' : 'text-gray-600'
          }`}>
            {isIncoming ? '+' : isOutgoing ? '-' : ''}{transfer.value_decimal}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            {new Date(transfer.created_at).toLocaleString()}
          </p>
        </div>
      </div>
    </div>
  )
}
