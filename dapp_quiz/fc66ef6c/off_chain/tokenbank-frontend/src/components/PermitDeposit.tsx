import { useState } from 'react'
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useWalletClient, usePublicClient } from 'wagmi'
import { CONTRACTS, ABIS, PERMIT_DOMAIN, PERMIT_TYPES } from '../config/contracts'
import { parseEther, keccak256, encodePacked, toHex, hexToSignature } from 'viem'
import './PermitDeposit.css'

function PermitDeposit() {
  const { address } = useAccount()
  const { data: walletClient } = useWalletClient()
  const publicClient = usePublicClient()
  const [amount, setAmount] = useState('')
  const [error, setError] = useState('')
  const [isSigning, setIsSigning] = useState(false)

  // Get current nonce
  const { data: nonce, isLoading: nonceLoading } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'nonces',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Write contract for permit deposit
  const { data: hash, writeContract, isPending } = useWriteContract()

  // Wait for transaction
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

    const handlePermitDeposit = async () => {
    if (!address) {
      setError('Wallet not connected')
      return
    }
    if (!amount) {
      setError('Please enter an amount')
      return
    }
    if (nonce === undefined || nonce === null) {
      setError('Nonce not loaded')
      return
    }
    if (!walletClient) {
      setError('Wallet client not available')
      return
    }
    if (!publicClient) {
      setError('Public client not available')
      return
    }

    try {
      setError('')
      setIsSigning(true)

      const depositAmount = parseEther(amount)
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600) // 1 hour from now
      const currentNonce = (nonce as bigint) + 1n // Use next nonce

      // Create the EIP-712 message
      const message = {
        owner: address,
        spender: CONTRACTS.BANK,
        value: depositAmount,
        nonce: currentNonce,
        deadline: deadline,
      }

      // Sign the EIP-712 message
      const signature = await walletClient.signTypedData({
        domain: PERMIT_DOMAIN,
        types: PERMIT_TYPES,
        primaryType: 'Permit',
        message: message,
      })

      // Parse the signature to get v, r, s
      const { v, r, s } = hexToSignature(signature)

      // Call permitDeposit
      writeContract({
        address: CONTRACTS.BANK,
        abi: ABIS.BANK,
        functionName: 'permitDeposit',
        args: [address, depositAmount, deadline, v, r, s],
      })

    } catch (err) {
      console.error('Permit deposit error:', err)
      setError(err instanceof Error ? err.message : 'Failed to deposit')
    } finally {
      setIsSigning(false)
    }
  }

  if (!address) {
    return <div>Please connect your wallet</div>
  }

  return (
    <div className="permit-deposit">
      <h3>Permit Deposit</h3>
      <p>Deposit tokens using EIP-712 signature (no approval needed)</p>
      <p className="note">This will prompt you to sign a message in your wallet to authorize the deposit.</p>

      <div className="deposit-form">
        <div className="input-group">
          <label htmlFor="amount">Amount (DToken):</label>
          <input
            id="amount"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="Enter amount"
            min="0"
            step="0.01"
          />
        </div>

        <div className="nonce-info">
          <p>Current Nonce: {nonceLoading ? 'Loading...' : nonce?.toString()}</p>
          <p>Next Nonce: {nonceLoading ? 'Loading...' : nonce !== undefined && nonce !== null ? (nonce as bigint + 1n).toString() : 'N/A'}</p>
          <p>Deadline: {nonceLoading ? 'Loading...' : new Date(Date.now() + 3600000).toLocaleString()}</p>
        </div>

        <button
          onClick={handlePermitDeposit}
          disabled={!amount || isPending || isConfirming || isSigning}
          className="deposit-button"
        >
          {isSigning ? 'Signing...' :
           isPending ? 'Confirming...' :
           isConfirming ? 'Processing...' :
           'Permit Deposit'}
        </button>

        {error && <div className="error">{error}</div>}

        {isSuccess && (
          <div className="success">
            <p>✅ Deposit successful!</p>
            <p>Transaction: {hash}</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default PermitDeposit
