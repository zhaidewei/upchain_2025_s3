import { useState } from 'react'
import { useNetwork, useSwitchNetwork } from 'wagmi'
import { Network, AlertCircle, CheckCircle } from 'lucide-react'
import toast from 'react-hot-toast'

const ANVIL_NETWORK = {
  id: 31337,
  name: 'Anvil Local',
  network: 'anvil',
  nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['http://127.0.0.1:8545'] },
    public: { http: ['http://127.0.0.1:8545'] },
  },
}

export default function NetworkSwitcher() {
  const { chain } = useNetwork()
  const { chains, switchNetwork } = useSwitchNetwork()
  const [isAdding, setIsAdding] = useState(false)

  const addAnvilNetwork = async () => {
    if (!window.ethereum) {
      toast.error('MetaMask is not installed')
      return
    }

    setIsAdding(true)
    try {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: `0x${ANVIL_NETWORK.id.toString(16)}`,
          chainName: ANVIL_NETWORK.name,
          nativeCurrency: ANVIL_NETWORK.nativeCurrency,
          rpcUrls: [ANVIL_NETWORK.rpcUrls.default.http[0]],
        }],
      })
      toast.success('Anvil network added successfully!')
    } catch (error: any) {
      console.error('Error adding network:', error)
      toast.error(`Failed to add network: ${error.message}`)
    } finally {
      setIsAdding(false)
    }
  }

  const handleSwitchNetwork = (chainId: number) => {
    if (switchNetwork) {
      switchNetwork(chainId)
    }
  }

  const isOnAnvil = chain?.id === 31337

  return (
    <div className="card">
      <div className="card-header">
        <h3 className="text-lg font-semibold flex items-center">
          <Network className="w-5 h-5 mr-2 text-blue-600" />
          Network Status
        </h3>
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div className="flex items-center">
            {isOnAnvil ? (
              <CheckCircle className="w-5 h-5 text-green-600 mr-2" />
            ) : (
              <AlertCircle className="w-5 h-5 text-orange-500 mr-2" />
            )}
            <div>
              <div className="font-medium">
                Current Network: {chain?.name || 'Unknown'}
              </div>
              <div className="text-sm text-gray-600">
                Chain ID: {chain?.id || 'N/A'}
              </div>
            </div>
          </div>
        </div>

        {!isOnAnvil && (
          <div className="bg-orange-50 p-4 rounded-lg">
            <div className="flex items-start">
              <AlertCircle className="w-5 h-5 text-orange-500 mr-2 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-orange-900 mb-1">
                  Switch to Anvil Network
                </h4>
                <p className="text-sm text-orange-800 mb-3">
                  To interact with the local contracts, you need to connect to the Anvil network.
                </p>
                <div className="space-y-2">
                  <button
                    onClick={addAnvilNetwork}
                    disabled={isAdding}
                    className="btn-secondary text-sm mr-2"
                  >
                    {isAdding ? 'Adding...' : 'Add Anvil Network'}
                  </button>
                  {chains.find(c => c.id === 31337) && (
                    <button
                      onClick={() => handleSwitchNetwork(31337)}
                      className="btn-primary text-sm"
                    >
                      Switch to Anvil
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {isOnAnvil && (
          <div className="bg-green-50 p-4 rounded-lg">
            <div className="flex items-center">
              <CheckCircle className="w-5 h-5 text-green-600 mr-2" />
              <div>
                <h4 className="text-sm font-medium text-green-900">
                  Connected to Anvil
                </h4>
                <p className="text-sm text-green-800">
                  You're ready to interact with local contracts!
                </p>
              </div>
            </div>
          </div>
        )}

        <div className="text-xs text-gray-500">
          <p><strong>Anvil Network Details:</strong></p>
          <p>• RPC URL: http://localhost:8545</p>
          <p>• Chain ID: 31337</p>
          <p>• Currency: ETH</p>
        </div>
      </div>
    </div>
  )
}
