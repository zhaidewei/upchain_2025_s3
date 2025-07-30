import { useChainId } from 'wagmi'
import { useState } from 'react'

function NetworkHelper() {
  const chainId = useChainId()
  const [showNetworkInfo, setShowNetworkInfo] = useState(false)

  const addAnvilNetwork = async () => {
    if (typeof window !== 'undefined' && window.ethereum) {
      try {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: '0x7A69', // 31337 in hex
              chainName: 'Anvil Local',
              nativeCurrency: {
                name: 'Ether',
                symbol: 'ETH',
                decimals: 18,
              },
              rpcUrls: ['http://localhost:8545'],
              blockExplorerUrls: [],
            },
          ],
        })
      } catch (error) {
        console.error('Error adding network:', error)
      }
    }
  }

  const switchToAnvil = async () => {
    if (typeof window !== 'undefined' && window.ethereum) {
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: '0x7A69' }], // 31337 in hex
        })
      } catch (error) {
        console.error('Error switching network:', error)
      }
    }
  }

  if (chainId === 31337) {
    return null // Don't show helper if already on correct network
  }

  return (
    <div style={{
      backgroundColor: '#fff3cd',
      border: '1px solid #ffeaa7',
      padding: '15px',
      margin: '10px 0',
      borderRadius: '5px',
      textAlign: 'center'
    }}>
      <h4>⚠️ Network Configuration Required</h4>
      <p>You need to connect to the Anvil Local Network (Chain ID: 31337)</p>

      <div style={{ marginTop: '10px' }}>
        <button
          onClick={addAnvilNetwork}
          style={{
            backgroundColor: '#007bff',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            marginRight: '10px',
            cursor: 'pointer'
          }}
        >
          Add Anvil Network
        </button>

        <button
          onClick={switchToAnvil}
          style={{
            backgroundColor: '#28a745',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            marginRight: '10px',
            cursor: 'pointer'
          }}
        >
          Switch to Anvil
        </button>

        <button
          onClick={() => setShowNetworkInfo(!showNetworkInfo)}
          style={{
            backgroundColor: '#6c757d',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          {showNetworkInfo ? 'Hide' : 'Show'} Manual Config
        </button>
      </div>

      {showNetworkInfo && (
        <div style={{
          marginTop: '15px',
          textAlign: 'left',
          backgroundColor: '#f8f9fa',
          padding: '10px',
          borderRadius: '4px',
          fontSize: '12px'
        }}>
          <h5>Manual Network Configuration:</h5>
          <p><strong>Network Name:</strong> Anvil Local</p>
          <p><strong>RPC URL:</strong> http://localhost:8545</p>
          <p><strong>Chain ID:</strong> 31337</p>
          <p><strong>Currency Symbol:</strong> ETH</p>
          <p><strong>Block Explorer URL:</strong> (leave empty)</p>
        </div>
      )}
    </div>
  )
}

export default NetworkHelper
