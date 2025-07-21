import { useAccount, useContractRead } from 'wagmi'
import { PiggyBank } from 'lucide-react'
import { formatEther } from 'viem'
import { CONTRACT_ADDRESSES, TOKENBANK_ABI } from '../utils/contracts'

export default function UserDeposits() {
  const { address, isConnected } = useAccount()

  const { data: userBalance, isLoading, error } = useContractRead({
    address: CONTRACT_ADDRESSES.TOKENBANK,
    abi: TOKENBANK_ABI,
    functionName: 'balances',
    args: address ? [address] : undefined,
    watch: true,
    enabled: !!address && isConnected,
  })

  if (!isConnected) {
    return null
  }

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <PiggyBank className="w-5 h-5 mr-2 text-green-600" />
          Your Deposits
        </h3>
      </div>

      <div className="space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <div className="loading-spinner"></div>
            <span className="ml-2 text-gray-600">Loading deposits...</span>
          </div>
        ) : error ? (
          <div className="text-red-600 text-center py-4">
            <p>Error loading deposits</p>
            <p className="text-sm text-red-500 mt-1">{error.message}</p>
          </div>
        ) : (
          <div className="text-center">
            <div className="text-3xl font-bold text-green-600 mb-2">
              {userBalance ? parseFloat(formatEther(userBalance)).toFixed(6) : '0.000000'}
            </div>
            <div className="text-sm text-gray-600 uppercase tracking-wide">
              ETH Deposited
            </div>

            {userBalance && userBalance > 0n ? (
              <div className="mt-4 p-3 bg-green-50 rounded-lg">
                <div className="text-sm text-green-800">
                  💰 You have active deposits earning rewards!
                </div>
              </div>
            ) : (
              <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                <div className="text-sm text-gray-600">
                  No deposits yet. Start earning by depositing ETH!
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
