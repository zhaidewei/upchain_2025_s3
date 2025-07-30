import { useAccount, useReadContract } from 'wagmi'
import { CONTRACTS, ABIS } from '../config/contracts'
import { formatEther, parseEther } from 'viem'
import './BalanceDisplay.css'
import { useState, useEffect } from 'react'

function BalanceDisplay() {
  const { address } = useAccount()
  const [debugInfo, setDebugInfo] = useState<string[]>([])

  // Add debug logging
  const addDebugInfo = (message: string) => {
    console.log(`[DEBUG] ${message}`)
    setDebugInfo(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`])
  }

  useEffect(() => {
    addDebugInfo(`Component mounted. Address: ${address}`)
    addDebugInfo(`Token contract address: ${CONTRACTS.TOKEN}`)
    addDebugInfo(`Bank contract address: ${CONTRACTS.BANK}`)
  }, [address])

  // Read token balance with error handling
  const {
    data: tokenBalance,
    isLoading: tokenLoading,
    error: tokenError,
    isError: tokenIsError
  } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read bank balance with error handling
  const {
    data: bankBalance,
    isLoading: bankLoading,
    error: bankError,
    isError: bankIsError
  } = useReadContract({
    address: CONTRACTS.BANK,
    abi: ABIS.BANK,
    functionName: 'getUserBalance',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read token allowance for bank with error handling
  const {
    data: allowance,
    isLoading: allowanceLoading,
    error: allowanceError,
    isError: allowanceIsError
  } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'allowance',
    args: [address!, CONTRACTS.BANK],
    query: {
      enabled: !!address,
    },
  })

  // Log errors and data
  useEffect(() => {
    if (tokenIsError) {
      addDebugInfo(`Token balance error: ${tokenError?.message}`)
    }
    if (bankIsError) {
      addDebugInfo(`Bank balance error: ${bankError?.message}`)
    }
    if (allowanceIsError) {
      addDebugInfo(`Allowance error: ${allowanceError?.message}`)
    }

    if (tokenBalance !== undefined) {
      addDebugInfo(`Token balance loaded: ${formatEther(tokenBalance as bigint)}`)
    }
    if (bankBalance !== undefined) {
      addDebugInfo(`Bank balance loaded: ${formatEther(bankBalance as bigint)}`)
    }
    if (allowance !== undefined) {
      addDebugInfo(`Allowance loaded: ${formatEther(allowance as bigint)}`)
    }
  }, [tokenBalance, bankBalance, allowance, tokenError, bankError, allowanceError])

  if (!address) {
    return <div>Please connect your wallet</div>
  }

  return (
    <div className="balance-display">
      <h3>Account Balances</h3>

      {/* Debug Information Panel */}
      <div className="debug-panel" style={{
        backgroundColor: '#f5f5f5',
        padding: '10px',
        margin: '10px 0',
        borderRadius: '5px',
        fontSize: '12px',
        maxHeight: '200px',
        overflowY: 'auto'
      }}>
        <h4>Debug Information</h4>
        <div>
          <p><strong>Connected Address:</strong> {address}</p>
          <p><strong>Token Contract:</strong> {CONTRACTS.TOKEN}</p>
          <p><strong>Bank Contract:</strong> {CONTRACTS.BANK}</p>
          <p><strong>Network:</strong> Anvil Local (31337)</p>
        </div>

        {/* Error Display */}
        <div style={{ marginTop: '10px' }}>
          {tokenIsError && (
            <div style={{ color: 'red', marginBottom: '5px' }}>
              <strong>Token Error:</strong> {tokenError?.message}
            </div>
          )}
          {bankIsError && (
            <div style={{ color: 'red', marginBottom: '5px' }}>
              <strong>Bank Error:</strong> {bankError?.message}
            </div>
          )}
          {allowanceIsError && (
            <div style={{ color: 'red', marginBottom: '5px' }}>
              <strong>Allowance Error:</strong> {allowanceError?.message}
            </div>
          )}
        </div>

        {/* Debug Log */}
        <div style={{ marginTop: '10px' }}>
          <strong>Debug Log:</strong>
          <div style={{
            backgroundColor: '#000',
            color: '#0f0',
            padding: '5px',
            borderRadius: '3px',
            fontFamily: 'monospace',
            fontSize: '10px',
            maxHeight: '100px',
            overflowY: 'auto'
          }}>
            {debugInfo.map((log, index) => (
              <div key={index}>{log}</div>
            ))}
          </div>
        </div>
      </div>

      <div className="balance-grid">
        <div className="balance-card">
          <h4>Token Balance</h4>
          {tokenLoading ? (
            <p>Loading...</p>
          ) : tokenIsError ? (
            <p style={{ color: 'red' }}>Error loading token balance</p>
          ) : (
            <p className="balance-amount">
              {tokenBalance ? formatEther(tokenBalance as bigint) : '0'} DToken
            </p>
          )}
        </div>

        <div className="balance-card">
          <h4>Bank Balance</h4>
          {bankLoading ? (
            <p>Loading...</p>
          ) : bankIsError ? (
            <p style={{ color: 'red' }}>Error loading bank balance</p>
          ) : (
            <p className="balance-amount">
              {bankBalance ? formatEther(bankBalance as bigint) : '0'} DToken
            </p>
          )}
        </div>

        <div className="balance-card">
          <h4>Bank Allowance</h4>
          {allowanceLoading ? (
            <p>Loading...</p>
          ) : allowanceIsError ? (
            <p style={{ color: 'red' }}>Error loading allowance</p>
          ) : (
            <p className="balance-amount">
              {allowance ? formatEther(allowance as bigint) : '0'} DToken
            </p>
          )}
        </div>
      </div>

      <div className="address-info">
        <p><strong>Your Address:</strong> {address}</p>
        <p><strong>Token Contract:</strong> {CONTRACTS.TOKEN}</p>
        <p><strong>Bank Contract:</strong> {CONTRACTS.BANK}</p>
      </div>

      {/* Troubleshooting Tips */}
      <div style={{
        backgroundColor: '#fff3cd',
        border: '1px solid #ffeaa7',
        padding: '10px',
        margin: '10px 0',
        borderRadius: '5px'
      }}>
        <h4>Troubleshooting Tips:</h4>
        <ul style={{ margin: '5px 0', paddingLeft: '20px' }}>
          <li>Make sure your local Anvil node is running on port 8545</li>
          <li>Verify that contracts are deployed to the correct addresses</li>
          <li>Check that MetaMask is connected to the Anvil network (Chain ID: 31337)</li>
          <li>Ensure the contract ABIs match the deployed contracts</li>
          <li>Try refreshing the page if you've recently deployed contracts</li>
        </ul>
      </div>

    </div>
  )
}

export default BalanceDisplay
