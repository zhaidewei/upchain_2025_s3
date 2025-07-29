import { useState } from 'react'
import { useAccount } from 'wagmi'
import { CONTRACTS } from '../config/contracts'
import './NonceChecker.css'

function NonceChecker() {
  const { address } = useAccount()
  const [nonce, setNonce] = useState('')
  const [isChecking, setIsChecking] = useState(false)
  const [nonceStatus, setNonceStatus] = useState<{
    isUsed: boolean
    wordPos: number
    bitPos: number
    bitmap: string
  } | null>(null)

  const checkNonce = async () => {
    if (!address || !nonce) return

    setIsChecking(true)
    try {
      const nonceValue = BigInt(nonce)
      const wordPos = Number(nonceValue / 256n)
      const bitPos = Number(nonceValue % 256n)

      // Read nonceBitmap
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

      setNonceStatus({
        isUsed,
        wordPos,
        bitPos,
        bitmap: bitmapValue.toString(16)
      })
    } catch (error) {
      console.error('Error checking nonce:', error)
      alert('Error checking nonce. Please try again.')
    } finally {
      setIsChecking(false)
    }
  }

  const findUnusedNonce = async () => {
    if (!address) return

    setIsChecking(true)
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
          setNonceStatus({
            isUsed: false,
            wordPos,
            bitPos,
            bitmap: bitmapValue.toString(16)
          })
          break
        }

        currentNonce++
      }
    } catch (error) {
      console.error('Error finding unused nonce:', error)
      alert('Error finding unused nonce. Please try again.')
    } finally {
      setIsChecking(false)
    }
  }

  if (!address) {
    return <div>Please connect your wallet</div>
  }

  return (
    <div className="nonce-checker">
      <h2>Check Nonce Status</h2>
      <p>Check if a specific nonce has been used in Permit2</p>

      <div className="nonce-form">
        <div className="input-group">
          <label htmlFor="nonce">Nonce Value:</label>
          <input
            id="nonce"
            type="number"
            value={nonce}
            onChange={(e) => setNonce(e.target.value)}
            placeholder="Enter nonce value (e.g., 0, 1, 2...)"
            min="0"
          />
        </div>

        <div className="button-group">
          <button
            onClick={checkNonce}
            disabled={!nonce || isChecking}
            className="check-button"
          >
            {isChecking ? 'Checking...' : 'Check Nonce'}
          </button>
          <button
            onClick={findUnusedNonce}
            disabled={isChecking}
            className="find-button"
          >
            {isChecking ? 'Finding...' : 'Find Unused Nonce'}
          </button>
        </div>
      </div>

      {nonceStatus && (
        <div className="nonce-result">
          <h3>Nonce Status</h3>
          <div className="status-grid">
            <div className="status-item">
              <strong>Nonce:</strong> {nonce}
            </div>
            <div className="status-item">
              <strong>Status:</strong>
              <span className={nonceStatus.isUsed ? 'used' : 'unused'}>
                {nonceStatus.isUsed ? '❌ Used' : '✅ Unused'}
              </span>
            </div>
            <div className="status-item">
              <strong>Word Position:</strong> {nonceStatus.wordPos}
            </div>
            <div className="status-item">
              <strong>Bit Position:</strong> {nonceStatus.bitPos}
            </div>
            <div className="status-item">
              <strong>Bitmap:</strong>
              <code>{nonceStatus.bitmap}</code>
            </div>
          </div>
        </div>
      )}

      <div className="info-box">
        <h3>How Nonces Work</h3>
        <ul>
          <li>Nonces can be any value (0, 1, 2, 100, etc.)</li>
          <li>Each nonce can only be used once</li>
          <li>Permit2 uses a bitmap system to track used nonces</li>
          <li>You can use any unused nonce value</li>
        </ul>
      </div>
    </div>
  )
}

export default NonceChecker
