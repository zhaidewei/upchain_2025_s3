import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount } from 'wagmi'
import { Wallet, Coins, TrendingUp } from 'lucide-react'

import TokenBalance from './components/TokenBalance'
import DepositForm from './components/DepositForm'
import WithdrawForm from './components/WithdrawForm'
import UserDeposits from './components/UserDeposits'
import TopDepositors from './components/TopDepositors'

function App() {
  const { isConnected } = useAccount()

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-3">
              <div className="bg-primary-600 p-2 rounded-lg">
                <Coins className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">TokenBank DApp</h1>
                <p className="text-sm text-gray-500">Decentralized Token Banking</p>
              </div>
            </div>
            <ConnectButton />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {!isConnected ? (
          /* Welcome Screen */
          <div className="text-center py-16">
            <div className="bg-primary-100 w-24 h-24 rounded-full flex items-center justify-center mx-auto mb-6">
              <Wallet className="w-12 h-12 text-primary-600" />
            </div>
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Welcome to TokenBank DApp
            </h2>
            <p className="text-lg text-gray-600 mb-8 max-w-2xl mx-auto">
              A decentralized application for depositing and withdrawing ETH.
              Connect your wallet to get started with secure token banking.
            </p>
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 max-w-md mx-auto">
              <h3 className="text-lg font-semibold mb-4">Features:</h3>
              <ul className="text-left space-y-2 text-gray-600">
                <li className="flex items-center">
                  <span className="w-2 h-2 bg-primary-500 rounded-full mr-3"></span>
                  Deposit ETH securely
                </li>
                <li className="flex items-center">
                  <span className="w-2 h-2 bg-primary-500 rounded-full mr-3"></span>
                  Withdraw your deposits anytime
                </li>
                <li className="flex items-center">
                  <span className="w-2 h-2 bg-primary-500 rounded-full mr-3"></span>
                  View top depositors leaderboard
                </li>
                <li className="flex items-center">
                  <span className="w-2 h-2 bg-primary-500 rounded-full mr-3"></span>
                  Track your deposit history
                </li>
              </ul>
            </div>
          </div>
        ) : (
          /* Connected Dashboard */
          <div className="space-y-8">
            {/* User Overview */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <TokenBalance />
              <UserDeposits />
              <div className="card">
                <div className="card-header">
                  <h3 className="text-lg font-semibold flex items-center">
                    <TrendingUp className="w-5 h-5 mr-2 text-primary-600" />
                    Quick Actions
                  </h3>
                </div>
                <div className="space-y-4">
                  <p className="text-sm text-gray-600">
                    Manage your ETH deposits and withdrawals
                  </p>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="text-center p-3 bg-green-50 rounded-lg">
                      <div className="text-2xl font-bold text-green-600">Deposit</div>
                      <div className="text-xs text-green-700">Earn rewards</div>
                    </div>
                    <div className="text-center p-3 bg-blue-50 rounded-lg">
                      <div className="text-2xl font-bold text-blue-600">Withdraw</div>
                      <div className="text-xs text-blue-700">Access funds</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Forms */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <DepositForm />
              <WithdrawForm />
            </div>

            {/* Top Depositors */}
            <TopDepositors />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center text-gray-500">
            <p>&copy; 2024 TokenBank DApp. Built with React, Wagmi, and ConnectKit.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App
