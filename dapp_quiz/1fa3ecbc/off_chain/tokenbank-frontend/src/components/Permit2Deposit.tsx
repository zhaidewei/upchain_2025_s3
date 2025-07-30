import { useState } from 'react'
import { useAccount, useWriteContract, useReadContract } from 'wagmi'
import { CONTRACTS, TOKEN_BANK_ABI } from '../config/contracts'
import { parseEther, formatEther } from 'viem'
import './Permit2Deposit.css'
import React from 'react'

// EIP712 Domain for Permit2
const DOMAIN = {
  name: 'Permit2',
  chainId: 31337,
  verifyingContract: CONTRACTS.PERMIT2 as `0x${string}`
}

// EIP712 Types for PermitTransferFrom
const PERMIT_TRANSFER_FROM_TYPES = {
  PermitTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' }
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' }
  ]
} as const

function Permit2Deposit() {
  const { address } = useAccount()
  const [amount, setAmount] = useState('')
  const [nonce, setNonce] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [status, setStatus] = useState('')

  // Write contract for deposit
  const { writeContract, isPending, data: hash, error, isSuccess, isError } = useWriteContract()

  // Function to get blockchain time for comparison
  const getBlockchainTime = async (): Promise<number> => {
    try {
      console.log('🔍 Fetching blockchain time...')
      // 'eth_getBlockByNumber' 的第二个参数表示是否返回完整交易对象数组。
      // 传 true 会返回完整交易对象数组，传 false 只返回区块基本信息（更快）。
      // 这里只需要区块头信息（如 timestamp），不需要交易详情，所以用 false。
      const block = await window.ethereum.request({
        method: 'eth_getBlockByNumber',
        params: ['latest', false]
      })
      const blockchainTime = parseInt(block.timestamp, 16)
      console.log('✅ Successfully fetched blockchain time:', blockchainTime)
      console.log('📋 Block info:', {
        number: block.number,
        timestamp: block.timestamp,
        timestampDecimal: blockchainTime
      })
      return blockchainTime
    } catch (error) {
      console.error('❌ Error getting blockchain time, falling back to local time:', error)
      const fallbackTime = Math.floor(Date.now() / 1000)
      console.warn('⚠️ Using local time as fallback:', fallbackTime)
      return fallbackTime
    }
  }

  // Read user's token balance
  const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
    address: CONTRACTS.TOKEN as `0x${string}`,
    abi: [
      {
        name: 'balanceOf',
        type: 'function',
        inputs: [{ name: 'account', type: 'address' }],
        outputs: [{ name: '', type: 'uint256' }],
        stateMutability: 'view'
      }
    ],
    functionName: 'balanceOf',
    args: [address!],
    query: { enabled: !!address }
  })

  // Read user's bank balance
  const { data: bankBalance, refetch: refetchBankBalance } = useReadContract({
    address: CONTRACTS.BANK as `0x${string}`,
    abi: [
      {
        name: 'balances',
        type: 'function',
        inputs: [{ name: 'user', type: 'address' }],
        outputs: [{ name: '', type: 'uint256' }],
        stateMutability: 'view'
      }
    ],
    functionName: 'balances',
    args: [address!],
    query: { enabled: !!address }
  })

  const checkNonce = async () => {
    if (!address || !nonce) return

    try {
      const nonceValue = BigInt(nonce)
      const wordPos = Number(nonceValue / 256n)
      const bitPos = Number(nonceValue % 256n)

              const bitmap = await window.ethereum.request({
          method: 'eth_call',
          params: [{
            to: CONTRACTS.PERMIT2,
            data: `0x4fe02b44${address.slice(2).padStart(64, '0')}${wordPos.toString(16).padStart(64, '0')}`
          }]
        })

      const bitmapValue = BigInt(bitmap)
      const bit = (bitmapValue >> BigInt(bitPos)) & 1n
      const isUsed = bit === 1n

      if (isUsed) {
        setStatus(`❌ Nonce ${nonce} is already used`)
      } else {
        setStatus(`✅ Nonce ${nonce} is available`)
      }
    } catch (error) {
      console.error('Error checking nonce:', error)
      setStatus('❌ Error checking nonce')
    }
  }

  const findUnusedNonce = async () => {
    if (!address) return

    try {
      let currentNonce = 0
      const maxAttempts = 100

      for (let i = 0; i < maxAttempts; i++) {
        const wordPos = Math.floor(currentNonce / 256)
        const bitPos = currentNonce % 256

        const bitmap = await window.ethereum.request({
          method: 'eth_call',
          params: [{
            to: CONTRACTS.PERMIT2,
            data: `0x4fe02b44${address.slice(2).padStart(64, '0')}${wordPos.toString(16).padStart(64, '0')}`
          }]
        })

        const bitmapValue = BigInt(bitmap)
        const bit = (bitmapValue >> BigInt(bitPos)) & 1n

        if (bit === 0n) {
          setNonce(currentNonce.toString())
          setStatus(`✅ Found unused nonce: ${currentNonce}`)
          break
        }

        currentNonce++
      }
    } catch (error) {
      console.error('Error finding unused nonce:', error)
      setStatus('❌ Error finding unused nonce')
    }
  }

  // Test function to verify blockchain time is working
  const testBlockchainTime = async () => {
    setStatus('🧪 Testing blockchain time retrieval...')
    try {
      const blockchainTime = await getBlockchainTime()
      const localTime = Math.floor(Date.now() / 1000)
      const timeDiff = Math.abs(blockchainTime - localTime)

      console.log('🧪 BLOCKCHAIN TIME TEST')
      console.log('Blockchain time:', blockchainTime)
      console.log('Local time:', localTime)
      console.log('Difference:', timeDiff, 'seconds')

      setStatus(`✅ Blockchain time test completed! Difference: ${timeDiff}s. Check console for details.`)
    } catch (error) {
      console.error('❌ Blockchain time test failed:', error)
      setStatus('❌ Blockchain time test failed')
    }
  }

  const handleDeposit = async () => {
    if (!address || !amount || !nonce) {
      setStatus('❌ Please fill in all fields')
      return
    }

    setIsProcessing(true)
    setStatus('🔄 Processing deposit...')

    try {
      const amountValue = parseEther(amount)
      const nonceValue = BigInt(nonce)

      // Get blockchain time for more accurate deadline calculation
      console.log('🕒 Starting deadline calculation with blockchain time...')
      const blockchainTime = await getBlockchainTime()
      const localTime = Math.floor(Date.now() / 1000)
      const timeDiff = Math.abs(blockchainTime - localTime)

      // Explicitly verify we're using blockchain time
      console.log('🎯 Using blockchain time for deadline calculation!')
      console.log('📊 Blockchain time:', blockchainTime, '(this is the base for deadline)')
      console.log('📊 Local machine time:', localTime, '(for comparison only)')

      // Use blockchain time as reference and add buffer
      const deadline = BigInt(blockchainTime + 24 * 3600) // 24 hours buffer

      console.log('✅ Deadline calculated using BLOCKCHAIN TIME (not local time)')

      // Add comprehensive time debugging
      console.log('=== TIME SYNCHRONIZATION DEBUG ===')
      console.log('🔹 Base time source: BLOCKCHAIN TIME')
      console.log('🔹 Blockchain time (seconds):', blockchainTime)
      console.log('🔹 Local time (seconds):', localTime)
      console.log('🔹 Time difference:', timeDiff, 'seconds')
      console.log('🔹 Deadline (seconds):', deadline.toString())
      console.log('🔹 Time until deadline:', Number(deadline) - blockchainTime, 'seconds (24 hours)')
      console.log('🔹 Blockchain time string:', new Date(blockchainTime * 1000).toString())
      console.log('🔹 Local time string:', new Date(localTime * 1000).toString())
      console.log('🔹 Deadline time string:', new Date(Number(deadline) * 1000).toString())

      if (timeDiff > 60) { // More than 1 minute difference
        console.warn('⚠️ Significant time difference detected:', timeDiff, 'seconds')
        console.warn('💡 But don\'t worry - we\'re using blockchain time for deadline!')
      } else {
        console.log('✅ Blockchain and local time are in sync (difference < 1 minute)')
      }
      console.log('=====================================')

      // Prepare the message for signing (convert BigInt to string for JSON serialization)
      const message = {
        permitted: {
          token: CONTRACTS.TOKEN as `0x${string}`,
          amount: amountValue.toString() // Convert BigInt to string
        },
        spender: CONTRACTS.BANK as `0x${string}`, // Use TokenBank as spender, matching successful test
        nonce: nonceValue.toString(), // Convert BigInt to string
        deadline: deadline.toString() // Convert BigInt to string
      }

      // Create the complete EIP712 data structure
      const eip712Data = {
        types: PERMIT_TRANSFER_FROM_TYPES,
        primaryType: 'PermitTransferFrom',
        domain: DOMAIN,
        message: message
      }

      // DEBUG: Log the complete EIP712 structure
      console.log('=== EIP712 DEBUG INFO ===')
      console.log('Domain:', DOMAIN)
      console.log('Types:', PERMIT_TRANSFER_FROM_TYPES)
      console.log('Message:', message)
      console.log('Complete EIP712 Data:', eip712Data)
      console.log('JSON Stringified:', JSON.stringify(eip712Data, null, 2))
      console.log('Contract Addresses:')
      console.log('  TOKEN:', CONTRACTS.TOKEN)
      console.log('  BANK:', CONTRACTS.BANK)
      console.log('  PERMIT2:', CONTRACTS.PERMIT2)
      console.log('User Address:', address)
      console.log('Amount (wei):', amountValue.toString())
      console.log('Nonce:', nonceValue.toString())
      console.log('Deadline:', deadline.toString())
      console.log('========================')

      // Compare with successful test structure
      console.log('=== COMPARISON WITH SUCCESSFUL TEST ===')
      console.log('Expected structure from successful test:')
      console.log('Domain: { name: "Permit2", chainId: 31337, verifyingContract: "0x5FbDB2315678afecb367f032d93F642f64180aa3" }')
      console.log('Types: PermitTransferFrom with TokenPermissions')
      console.log('Message: { permitted: { token, amount }, spender, nonce, deadline }')
      console.log('Current structure matches expected: ✅')
      console.log('========================================')

      // Request signature from MetaMask
      const signature = await window.ethereum.request({
        method: 'eth_signTypedData_v4',
        params: [
          address,
          JSON.stringify(eip712Data)
        ]
      })

      console.log('Signature received:', signature)

      setStatus('📝 Signature generated, calling contract...')

      // Call TokenBank depositWithPermit2
      console.log('=== CONTRACT CALL DEBUG ===')
      console.log('Calling TokenBank.depositWithPermit2 with:')
      console.log('  owner:', address)
      console.log('  amount:', amountValue.toString())
      console.log('  deadline:', deadline.toString())
      console.log('  nonce:', nonceValue.toString())
      console.log('  signature:', signature)
      console.log('========================')

      writeContract({
        address: CONTRACTS.BANK as `0x${string}`,
        abi: TOKEN_BANK_ABI,
        functionName: 'depositWithPermit2',
        args: [
          address,
          amountValue,
          deadline,
          nonceValue,
          signature
        ]
      })

      setStatus('✅ Deposit transaction submitted!')
    } catch (error) {
      console.error('Error during deposit:', error)
      setStatus('❌ Error during deposit. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }

  // Handle transaction status changes
  React.useEffect(() => {
    if (isSuccess && hash) {
      console.log('✅ Transaction successful! Hash:', hash)
      setStatus(`✅ Transaction successful! Hash: ${hash}`)
      // Refresh balances after successful transaction
      setTimeout(() => {
        refetchTokenBalance()
        refetchBankBalance()
      }, 2000) // Wait 2 seconds for blockchain to update
    }
  }, [isSuccess, hash, refetchTokenBalance, refetchBankBalance])

  React.useEffect(() => {
    if (isError && error) {
      console.error('❌ Transaction failed:', error)
      setStatus(`❌ Transaction failed: ${error.message}`)
    }
  }, [isError, error])

  if (!address) {
    return <div>Please connect your wallet</div>
  }

  return (
    <div className="permit2-deposit">
      <h2>Permit2 Deposit</h2>
      <p>Deposit tokens using Permit2 signature authorization</p>

      <div className="deposit-form">
        <div className="form-group">
          <label htmlFor="amount">Amount (TT):</label>
          <input
            id="amount"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="Enter amount (e.g., 10)"
            min="0"
            step="0.1"
          />
          {tokenBalance !== undefined && (
            <small>
              Available: {formatEther(tokenBalance)} TT
            </small>
          )}
        </div>

        <div className="form-group">
          <label htmlFor="nonce">Nonce:</label>
          <div className="nonce-input-group">
            <input
              id="nonce"
              type="number"
              value={nonce}
              onChange={(e) => setNonce(e.target.value)}
              placeholder="Enter nonce value"
              min="0"
            />
            <button
              onClick={checkNonce}
              className="check-nonce-btn"
              disabled={!nonce}
            >
              Check
            </button>
            <button
              onClick={findUnusedNonce}
              className="find-nonce-btn"
            >
              Find
            </button>
          </div>
        </div>

        {bankBalance !== undefined && (
          <div className="balance-info">
            <small>
              Current Bank Balance: {formatEther(bankBalance)} TT
            </small>
          </div>
        )}

        <div className="button-group">
          <button
            onClick={testBlockchainTime}
            className="test-button"
            style={{ marginRight: '10px', backgroundColor: '#6c757d' }}
          >
            🧪 Test Blockchain Time
          </button>

          <button
            onClick={handleDeposit}
            disabled={!amount || !nonce || isProcessing || isPending}
            className="deposit-button"
          >
            {isProcessing || isPending ? 'Processing...' : 'Deposit with Permit2'}
          </button>
        </div>
      </div>

      {status && (
        <div className="status-message">
          {status}
        </div>
      )}

      <div className="info-box">
        <h3>How Permit2 Deposit Works</h3>
        <ol>
          <li>Enter the amount you want to deposit</li>
          <li>Enter a nonce value (or use "Find" to get an unused one)</li>
          <li>Click "Deposit with Permit2"</li>
          <li>Sign the EIP712 message in MetaMask</li>
          <li>The contract will verify your signature and transfer tokens</li>
        </ol>
        <p><strong>Note:</strong> Each nonce can only be used once. Make sure to use an unused nonce value.</p>
      </div>
    </div>
  )
}

export default Permit2Deposit
