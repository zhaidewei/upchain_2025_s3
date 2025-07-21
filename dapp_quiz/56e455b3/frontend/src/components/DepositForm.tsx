import { useState } from 'react'
import { useAccount, useContractWrite, useWaitForTransaction } from 'wagmi'
import { parseEther, formatEther } from 'viem'
import { ArrowDownCircle, Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { CONTRACT_ADDRESSES, TOKENBANK_ABI } from '../utils/contracts'

export default function DepositForm() {
  const { address, isConnected } = useAccount()
  const [amount, setAmount] = useState('')

  const { data, write, isLoading: isWriteLoading } = useContractWrite({
    address: CONTRACT_ADDRESSES.TOKENBANK,
    abi: TOKENBANK_ABI,
    functionName: 'deposit',
  })

  const { isLoading: isTxLoading, isSuccess } = useWaitForTransaction({
    hash: data?.hash,
    onSuccess() {
      toast.success(`Successfully deposited ${amount} ETH!`)
      setAmount('')
    },
    onError(error) {
      toast.error(`Deposit failed: ${error.message}`)
    },
  })

  const handleDeposit = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount')
      return
    }

    try {
      const value = parseEther(amount)
      write?.({
        value,
      })
    } catch (error) {
      toast.error('Invalid amount format')
    }
  }

  const isLoading = isWriteLoading || isTxLoading

  if (!isConnected) {
    return null
  }

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <ArrowDownCircle className="w-5 h-5 mr-2 text-green-600" />
          Deposit ETH
        </h3>
      </div>

      <div className="space-y-6">
        <div>
          <label htmlFor="deposit-amount" className="block text-sm font-medium text-gray-700 mb-2">
            Amount (ETH)
          </label>
          <input
            id="deposit-amount"
            type="number"
            step="0.001"
            min="0"
            placeholder="0.0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input"
            disabled={isLoading}
          />
          <div className="mt-2 flex justify-between text-sm text-gray-500">
            <span>Minimum: 0.001 ETH</span>
            <button
              type="button"
              onClick={() => setAmount('0.1')}
              className="text-primary-600 hover:text-primary-700"
              disabled={isLoading}
            >
              Use 0.1 ETH
            </button>
          </div>
        </div>

        <div className="bg-blue-50 p-4 rounded-lg">
          <h4 className="text-sm font-medium text-blue-900 mb-2">Deposit Benefits:</h4>
          <ul className="text-sm text-blue-800 space-y-1">
            <li>• Secure storage in smart contract</li>
            <li>• Withdraw anytime with no penalties</li>
            <li>• Appear on the leaderboard</li>
            <li>• Gas-efficient transactions</li>
          </ul>
        </div>

        <button
          onClick={handleDeposit}
          disabled={!amount || parseFloat(amount) <= 0 || isLoading}
          className="btn-primary w-full flex items-center justify-center"
        >
          {isLoading ? (
            <>
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              {isTxLoading ? 'Confirming...' : 'Depositing...'}
            </>
          ) : (
            <>
              <ArrowDownCircle className="w-4 h-4 mr-2" />
              Deposit {amount || '0'} ETH
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
