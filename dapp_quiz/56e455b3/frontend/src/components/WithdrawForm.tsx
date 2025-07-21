import { useState } from 'react'
import { useAccount, useContractWrite, useWaitForTransaction, useContractRead } from 'wagmi'
import { parseEther, formatEther } from 'viem'
import { ArrowUpCircle, Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { CONTRACT_ADDRESSES, TOKENBANK_ABI } from '../utils/contracts'

export default function WithdrawForm() {
  const { address, isConnected } = useAccount()
  const [amount, setAmount] = useState('')

  // Get user's deposit balance
  const { data: userBalance } = useContractRead({
    address: CONTRACT_ADDRESSES.TOKENBANK,
    abi: TOKENBANK_ABI,
    functionName: 'balances',
    args: address ? [address] : undefined,
    watch: true,
    enabled: !!address && isConnected,
  })

  const { data, write, isLoading: isWriteLoading } = useContractWrite({
    address: CONTRACT_ADDRESSES.TOKENBANK,
    abi: TOKENBANK_ABI,
    functionName: 'withdraw',
  })

  const { isLoading: isTxLoading, isSuccess } = useWaitForTransaction({
    hash: data?.hash,
    onSuccess() {
      toast.success(`Successfully withdrew ${amount} ETH!`)
      setAmount('')
    },
    onError(error) {
      toast.error(`Withdrawal failed: ${error.message}`)
    },
  })

  const handleWithdraw = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount')
      return
    }

    if (!userBalance || userBalance === 0n) {
      toast.error('No deposits to withdraw')
      return
    }

    try {
      const value = parseEther(amount)
      if (value > userBalance) {
        toast.error('Amount exceeds your deposit balance')
        return
      }

      write?.({
        args: [value],
      })
    } catch (error) {
      toast.error('Invalid amount format')
    }
  }

  const handleMaxWithdraw = () => {
    if (userBalance && userBalance > 0n) {
      setAmount(formatEther(userBalance))
    }
  }

  const isLoading = isWriteLoading || isTxLoading
  const maxBalance = userBalance ? parseFloat(formatEther(userBalance)) : 0

  if (!isConnected) {
    return null
  }

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <ArrowUpCircle className="w-5 h-5 mr-2 text-blue-600" />
          Withdraw ETH
        </h3>
      </div>

      <div className="space-y-6">
        <div>
          <label htmlFor="withdraw-amount" className="block text-sm font-medium text-gray-700 mb-2">
            Amount (ETH)
          </label>
          <input
            id="withdraw-amount"
            type="number"
            step="0.001"
            min="0"
            max={maxBalance}
            placeholder="0.0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input"
            disabled={isLoading || maxBalance === 0}
          />
          <div className="mt-2 flex justify-between text-sm text-gray-500">
            <span>Available: {maxBalance.toFixed(6)} ETH</span>
            {maxBalance > 0 && (
              <button
                type="button"
                onClick={handleMaxWithdraw}
                className="text-primary-600 hover:text-primary-700"
                disabled={isLoading}
              >
                Withdraw All
              </button>
            )}
          </div>
        </div>

        {maxBalance === 0 ? (
          <div className="bg-yellow-50 p-4 rounded-lg">
            <h4 className="text-sm font-medium text-yellow-900 mb-2">No Deposits Available</h4>
            <p className="text-sm text-yellow-800">
              You need to deposit ETH first before you can withdraw. Head to the deposit section to get started!
            </p>
          </div>
        ) : (
          <div className="bg-orange-50 p-4 rounded-lg">
            <h4 className="text-sm font-medium text-orange-900 mb-2">Withdrawal Info:</h4>
            <ul className="text-sm text-orange-800 space-y-1">
              <li>• Instant withdrawal to your wallet</li>
              <li>• No withdrawal fees or penalties</li>
              <li>• Gas fees apply for transaction</li>
              <li>• Minimum withdrawal: 0.001 ETH</li>
            </ul>
          </div>
        )}

        <button
          onClick={handleWithdraw}
          disabled={!amount || parseFloat(amount) <= 0 || isLoading || maxBalance === 0}
          className="btn-primary w-full flex items-center justify-center"
        >
          {isLoading ? (
            <>
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              {isTxLoading ? 'Confirming...' : 'Withdrawing...'}
            </>
          ) : (
            <>
              <ArrowUpCircle className="w-4 h-4 mr-2" />
              Withdraw {amount || '0'} ETH
            </>
          )}
        </button>

        {data?.hash && (
          <div className="text-center">
            <p className="text-sm text-gray-600">Transaction Hash:</p>
            <p className="text-xs font-mono mt-1 break-all text-primary-600">
              {data.hash}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
