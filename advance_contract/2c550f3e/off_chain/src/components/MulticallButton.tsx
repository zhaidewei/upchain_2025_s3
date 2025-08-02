import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { encodeFunctionData } from 'viem'
import { CONTRACTS } from '../config/contracts'

interface MulticallButtonProps {
  amount: string
}

export function MulticallButton({ amount }: MulticallButtonProps) {
  const { address } = useAccount()
  const [isPreparing, setIsPreparing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const { writeContract, data: hash, isPending } = useWriteContract()

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const handleMulticall = async () => {
    if (!address) {
      setError('Please connect your wallet first')
      return
    }

    setIsPreparing(true)
    setError(null)

    try {
      // Convert amount to wei (assuming 18 decimals)
      const amountInWei = BigInt(parseFloat(amount) * 10 ** 18)

      // Construct call data for ERC20 approve
      const approveCallData = encodeFunctionData({
        abi: [
          {
            "type": "function",
            "name": "approve",
            "inputs": [
              {
                "name": "spender",
                "type": "address"
              },
              {
                "name": "amount",
                "type": "uint256"
              }
            ],
            "outputs": [
              {
                "name": "",
                "type": "bool"
              }
            ],
            "stateMutability": "nonpayable"
          }
        ],
        functionName: 'approve',
        args: [CONTRACTS.TOKENBANK as `0x${string}`, amountInWei]
      })

      // Construct call data for TokenBank deposit
      const depositCallData = encodeFunctionData({
        abi: [
          {
            "type": "function",
            "name": "deposit",
            "inputs": [
              {
                "name": "amount",
                "type": "uint256"
              }
            ],
            "outputs": [],
            "stateMutability": "nonpayable"
          }
        ],
        functionName: 'deposit',
        args: [amountInWei]
      })

      // Multicall ABI
      const multicallAbi = [
        {
          "type": "function",
          "name": "multicall",
          "inputs": [
            {
              "name": "targets",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "data",
              "type": "bytes[]",
              "internalType": "bytes[]"
            }
          ],
          "outputs": [
            {
              "name": "results",
              "type": "bytes[]",
              "internalType": "bytes[]"
            }
          ],
          "stateMutability": "nonpayable"
        }
      ] as const

      // Execute the multicall transaction
      writeContract({
        address: address as `0x${string}`,
        abi: multicallAbi,
        functionName: 'multicall',
        args: [
          [CONTRACTS.ERC20 as `0x${string}`, CONTRACTS.TOKENBANK as `0x${string}`],
          [approveCallData, depositCallData]
        ]
      })

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setIsPreparing(false)
    }
  }

  return (
    <div style={{ marginTop: '20px' }}>
      <h3>EIP-7702 Multicall</h3>
      <p>Deposit {amount} tokens using EIP-7702 delegation</p>

      <button
        onClick={handleMulticall}
        disabled={isPreparing || isPending || isConfirming}
        style={{ marginTop: '10px' }}
      >
        {isPreparing && 'Preparing...'}
        {isPending && 'Confirming...'}
        {isConfirming && 'Processing...'}
        {!isPreparing && !isPending && !isConfirming && 'Execute Multicall'}
      </button>

      {error && (
        <p style={{ color: 'red', marginTop: '10px' }}>
          Error: {error}
        </p>
      )}

      {hash && (
        <p style={{ marginTop: '10px' }}>
          Transaction Hash: {hash}
        </p>
      )}

      {isSuccess && (
        <p style={{ color: 'green', marginTop: '10px' }}>
          ✅ Transaction successful! Check your balances.
        </p>
      )}
    </div>
  )
}
