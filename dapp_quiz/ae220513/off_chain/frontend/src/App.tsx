import { WagmiProvider } from 'wagmi'
import { QueryClientProvider } from '@tanstack/react-query'
import { RainbowKitProvider } from '@rainbow-me/rainbowkit'
import { config, queryClient } from './config/wagmi'
import { WalletConnect } from './components/WalletConnect'
import { TransferHistory } from './components/TransferHistory'
import { TransferStats } from './components/TransferStats'
import '@rainbow-me/rainbowkit/styles.css'

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
            {/* Header */}
            <div className="bg-white/80 backdrop-blur-sm border-b border-gray-200 sticky top-0 z-50">
              <div className="container mx-auto px-4 py-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                      <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                      </svg>
                    </div>
                    <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                      ERC20 Transfer Viewer
                    </h1>
                  </div>
                  <div className="hidden md:block">
                    <WalletConnect />
                  </div>
                </div>
              </div>
            </div>

            {/* Main Content */}
            <div className="container mx-auto px-4 py-8">
              <div className="max-w-7xl mx-auto space-y-8">
                {/* Mobile Wallet Connection */}
                <div className="md:hidden">
                  <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-xl border border-gray-200 p-6">
                    <h2 className="text-lg font-semibold text-gray-900 mb-4">
                      Connect Wallet
                    </h2>
                    <WalletConnect />
                  </div>
                </div>

                {/* Transfer Statistics */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <div className="lg:col-span-2">
                    <TransferStats />
                  </div>
                  <div className="lg:col-span-1">
                    <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-xl border border-gray-200 p-6 h-full">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">
                        Quick Stats
                      </h3>
                      <div className="space-y-4">
                        <div className="flex items-center justify-between p-3 bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl">
                          <span className="text-sm font-medium text-blue-700">Total Transfers</span>
                          <span className="text-lg font-bold text-blue-900">5</span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gradient-to-r from-green-50 to-green-100 rounded-xl">
                          <span className="text-sm font-medium text-green-700">Unique Addresses</span>
                          <span className="text-lg font-bold text-green-900">7</span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gradient-to-r from-purple-50 to-purple-100 rounded-xl">
                          <span className="text-sm font-medium text-purple-700">Network</span>
                          <span className="text-lg font-bold text-purple-900">Anvil</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Transfer History */}
                <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-xl border border-gray-200 p-6">
                  <TransferHistory />
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="mt-16 py-8 border-t border-gray-200">
              <div className="container mx-auto px-4 text-center">
                <p className="text-gray-600 text-sm">
                  Built with React, Wagmi, and Tailwind CSS
                </p>
              </div>
            </div>
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
