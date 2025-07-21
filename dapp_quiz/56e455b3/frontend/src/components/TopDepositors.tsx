import { useContractRead } from 'wagmi'
import { formatEther } from 'viem'
import { Trophy, Medal, Award } from 'lucide-react'
import { CONTRACT_ADDRESSES, TOKENBANK_ABI } from '../utils/contracts'

export default function TopDepositors() {
  const { data: topDepositors, isLoading, error } = useContractRead({
    address: CONTRACT_ADDRESSES.TOKENBANK,
    abi: TOKENBANK_ABI,
    functionName: 'getTopDepositors',
    watch: true,
  })

  const getRankIcon = (index: number) => {
    switch (index) {
      case 0:
        return <Trophy className="w-5 h-5 text-yellow-500" />
      case 1:
        return <Medal className="w-5 h-5 text-gray-400" />
      case 2:
        return <Award className="w-5 h-5 text-amber-600" />
      default:
        return null
    }
  }

  const getRankColor = (index: number) => {
    switch (index) {
      case 0:
        return 'bg-yellow-50 border-yellow-200'
      case 1:
        return 'bg-gray-50 border-gray-200'
      case 2:
        return 'bg-amber-50 border-amber-200'
      default:
        return 'bg-white border-gray-200'
    }
  }

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <Trophy className="w-5 h-5 mr-2 text-yellow-500" />
          Top Depositors Leaderboard
        </h3>
      </div>

      <div className="space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <div className="loading-spinner"></div>
            <span className="ml-2 text-gray-600">Loading leaderboard...</span>
          </div>
        ) : error ? (
          <div className="text-red-600 text-center py-4">
            <p>Error loading leaderboard</p>
            <p className="text-sm text-red-500 mt-1">{error.message}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {topDepositors && topDepositors.length > 0 ? (
              topDepositors.map((depositor, index) => {
                // Skip empty slots (address(0))
                if (depositor.depositor === '0x0000000000000000000000000000000000000000') {
                  return null
                }

                return (
                  <div
                    key={`${depositor.depositor}-${index}`}
                    className={`p-4 rounded-lg border-2 ${getRankColor(index)}`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        {getRankIcon(index)}
                        <div>
                          <div className="font-semibold text-gray-900">
                            #{index + 1}
                          </div>
                          <div className="text-xs font-mono text-gray-600 break-all">
                            {depositor.depositor.slice(0, 6)}...{depositor.depositor.slice(-4)}
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-lg font-bold text-gray-900">
                          {parseFloat(formatEther(depositor.amount)).toFixed(4)}
                        </div>
                        <div className="text-sm text-gray-600">ETH</div>
                      </div>
                    </div>
                  </div>
                )
              })
            ) : (
              <div className="text-center py-8">
                <Trophy className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">No depositors yet</p>
                <p className="text-sm text-gray-400 mt-1">
                  Be the first to deposit and claim the top spot!
                </p>
              </div>
            )}
          </div>
        )}

        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <h4 className="text-sm font-medium text-blue-900 mb-2">🏆 Leaderboard Rules:</h4>
          <ul className="text-sm text-blue-800 space-y-1">
            <li>• Rankings update in real-time</li>
            <li>• Based on total deposit amount</li>
            <li>• Top 3 positions displayed</li>
            <li>• Withdrawals affect your ranking</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
