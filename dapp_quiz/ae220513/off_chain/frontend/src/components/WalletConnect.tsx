import { useAccount, useDisconnect } from 'wagmi'
import { ConnectButton } from '@rainbow-me/rainbowkit'

export function WalletConnect() {
  const { address, isConnected } = useAccount()
  const { disconnect } = useDisconnect()

  return (
    <div className="flex flex-col items-center space-y-4">
      <div className="flex items-center space-x-3">
        <ConnectButton />
        {isConnected && (
          <button
            onClick={() => disconnect()}
            className="bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white font-medium py-2 px-4 rounded-xl transition-all duration-200 shadow-lg hover:shadow-xl transform hover:scale-105"
          >
            Disconnect
          </button>
        )}
      </div>

      {isConnected && address && (
        <div className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-2xl p-4 w-full max-w-md shadow-lg">
          <div className="flex items-center space-x-3 mb-3">
            <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
            <h3 className="text-sm font-semibold text-green-800">
              Connected Wallet
            </h3>
          </div>
          <div className="bg-white/60 rounded-xl p-3">
            <p className="text-xs text-green-700 break-all font-mono">
              {address}
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
