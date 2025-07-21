import { useAccount, useBalance } from 'wagmi'
import { Wallet } from 'lucide-react'
import { formatEther } from 'viem'

export default function TokenBalance() {
  const { address, isConnected } = useAccount()
  const { data: balance, isLoading, error } = useBalance({
    address: address,
    watch: true,
  })

  if (!isConnected) {
    return null
  }

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <Wallet className="w-5 h-5 mr-2 text-primary-600" />
          ETH Balance
        </h3>
      </div>

      <div className="space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <div className="loading-spinner"></div>
            <span className="ml-2 text-gray-600">Loading balance...</span>
          </div>
        ) : error ? (
          <div className="text-red-600 text-center py-4">
            <p>Error loading balance</p>
            <p className="text-sm text-red-500 mt-1">{error.message}</p>
          </div>
        ) : (
          <div className="text-center">
            <div className="text-3xl font-bold text-gray-900 mb-2">
              {balance ? parseFloat(formatEther(balance.value)).toFixed(6) : '0.000000'}
            </div>
            <div className="text-sm text-gray-600 uppercase tracking-wide">
              {balance?.symbol || 'ETH'}
            </div>
            <div className="mt-4 p-3 bg-gray-50 rounded-lg">
              <div className="text-xs text-gray-500">Wallet Address</div>
              <div className="text-sm font-mono mt-1 break-all">
                {address}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
