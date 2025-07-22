import { useAccount, useDisconnect } from 'wagmi'
import { useWeb3Modal } from '@web3modal/wagmi/react'
import { Wallet, LogOut } from 'lucide-react'

export default function Header() {
  const { open } = useWeb3Modal()
  const { address, isConnected } = useAccount()
  const { disconnect } = useDisconnect()

    return (
    <header className="bg-white shadow-sm border-b">
      <div className="container mx-auto px-4 py-4">
        <div className="flex justify-between items-start">
          <div className="flex flex-col">
            <h1 className="text-2xl font-bold text-gray-900">NFT Market</h1>
            {isConnected && (
              <div className="flex flex-col">
                <span className="text-sm text-gray-600">
                  当前账号: {address?.slice(0, 6)}...{address?.slice(-4)}
                </span>
                <span className="text-xs text-gray-500">
                  想切换账号？请在MetaMask中选择不同账号后重新连接
                </span>
              </div>
            )}
          </div>

          <div className="flex items-center gap-4">
            {isConnected ? (
              <button
                onClick={() => disconnect()}
                className="flex items-center gap-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
              >
                <LogOut size={16} />
                断开连接
              </button>
            ) : (
              <button
                onClick={() => open()}
                className="flex items-center gap-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors"
              >
                <Wallet size={16} />
                连接钱包
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}
