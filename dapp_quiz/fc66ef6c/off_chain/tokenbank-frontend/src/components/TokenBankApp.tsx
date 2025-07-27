import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { useState } from 'react'
import BalanceDisplay from './BalanceDisplay'
import PermitDeposit from './PermitDeposit'
import './TokenBankApp.css'

function TokenBankApp() {
  const { address, isConnected } = useAccount()
  const { connect, connectors, error } = useConnect()
  const { disconnect } = useDisconnect()
  const [activeTab, setActiveTab] = useState<'balance' | 'deposit'>('balance')

    // Check if MetaMask is installed
  const isMetaMaskInstalled = typeof window !== 'undefined' && window.ethereum

    if (!isConnected) {
    return (
      <div className="tokenbank-app">
        <div className="header">
          <h2>TokenBank dApp</h2>
        </div>

        <div className="tabs">
          <button
            className="tab"
            disabled
          >
            View Balances
          </button>
          <button
            className="tab"
            disabled
          >
            Permit Deposit
          </button>
          <button
            className="tab connect-tab"
            onClick={() => {
              if (connectors.length > 0) {
                connect({ connector: connectors[0] })
              }
            }}
          >
            Connect MetaMask
          </button>
        </div>

        <div className="content">
          <div className="connect-message">
            <h3>Welcome to TokenBank</h3>
            <p>Please connect your MetaMask wallet to continue.</p>
            {error && <div className="error">Error: {error.message}</div>}
            {connectors.length === 0 && (
              <div className="error">No connectors available. Please install MetaMask.</div>
            )}
            {!isMetaMaskInstalled && (
              <div className="error">MetaMask is not installed. Please install MetaMask extension.</div>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="tokenbank-app">
      <div className="header">
        <div className="wallet-info">
          <span>Connected: {address?.slice(0, 6)}...{address?.slice(-4)}</span>
        </div>
      </div>

      <div className="tabs">
        <button
          className={`tab ${activeTab === 'balance' ? 'active' : ''}`}
          onClick={() => setActiveTab('balance')}
        >
          View Balances
        </button>
        <button
          className={`tab ${activeTab === 'deposit' ? 'active' : ''}`}
          onClick={() => setActiveTab('deposit')}
        >
          Permit Deposit
        </button>
        <button
          className="tab connect-tab"
          onClick={() => disconnect()}
        >
          Disconnect
        </button>
      </div>

      <div className="content">
        {activeTab === 'balance' && <BalanceDisplay />}
        {activeTab === 'deposit' && <PermitDeposit />}
      </div>
    </div>
  )
}

export default TokenBankApp
