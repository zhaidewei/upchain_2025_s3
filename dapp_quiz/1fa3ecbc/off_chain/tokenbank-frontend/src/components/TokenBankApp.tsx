import { useState } from 'react'
import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { injected } from 'wagmi/connectors'
import BalanceDisplay from './BalanceDisplay'
import Permit2Deposit from './Permit2Deposit'
import NonceChecker from './NonceChecker'
import './TokenBankApp.css'

function TokenBankApp() {
  const [activeTab, setActiveTab] = useState<'balances' | 'deposit' | 'nonce'>('balances')
  const { address, isConnected } = useAccount()
  const { connect } = useConnect()
  const { disconnect } = useDisconnect()

  const handleConnect = () => {
    connect({ connector: injected() })
  }

  const handleDisconnect = () => {
    disconnect()
  }

  if (!isConnected) {
    return (
      <div className="app">
        <header>
          <h1>TokenBank Permit2 Frontend</h1>
          <p>Connect your wallet to start using TokenBank with Permit2</p>
        </header>
        <main>
          <button onClick={handleConnect} className="connect-button">
            Connect MetaMask
          </button>
        </main>
      </div>
    )
  }

  return (
    <div className="app">
      <header>
        <h1>TokenBank Permit2 Frontend</h1>
        <div className="wallet-info">
          <span>Connected: {address?.slice(0, 6)}...{address?.slice(-4)}</span>
          <button onClick={handleDisconnect} className="disconnect-button">
            Disconnect
          </button>
        </div>
      </header>

      <nav className="tabs">
        <button
          className={activeTab === 'balances' ? 'active' : ''}
          onClick={() => setActiveTab('balances')}
        >
          View Balances
        </button>
        <button
          className={activeTab === 'deposit' ? 'active' : ''}
          onClick={() => setActiveTab('deposit')}
        >
          Permit2 Deposit
        </button>
        <button
          className={activeTab === 'nonce' ? 'active' : ''}
          onClick={() => setActiveTab('nonce')}
        >
          Check Nonce
        </button>
      </nav>

      <main>
        {activeTab === 'balances' && <BalanceDisplay />}
        {activeTab === 'deposit' && <Permit2Deposit />}
        {activeTab === 'nonce' && <NonceChecker />}
      </main>
    </div>
  )
}

export default TokenBankApp
