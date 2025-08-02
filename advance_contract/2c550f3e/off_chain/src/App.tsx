import { useAccount, useConnect, useDisconnect, useReadContract } from 'wagmi'
import { CONTRACTS, ERC20_ABI, TOKENBANK_ABI } from './config/contracts'
import { formatEther } from 'viem'
import { DepositForm } from './components/DepositForm'

function App() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()

  // Read ERC20 balance
  const { data: erc20Balance, isLoading: erc20Loading } = useReadContract({
    address: CONTRACTS.ERC20 as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read TokenBank balance
  const { data: tokenBankBalance, isLoading: tokenBankLoading } = useReadContract({
    address: CONTRACTS.TOKENBANK as `0x${string}`,
    abi: TOKENBANK_ABI,
    functionName: 'getUserBalance',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  const handleConnect = () => {
    const metaMaskConnector = connectors.find(connector => connector.name === 'MetaMask')
    if (metaMaskConnector) {
      connect({ connector: metaMaskConnector })
    }
  }

  return (
    <div className="App">
      <h1>TokenBank Frontend</h1>

      {!isConnected ? (
        <div>
          <p>Please connect your MetaMask wallet to continue</p>
          <button onClick={handleConnect}>
            Connect MetaMask
          </button>
        </div>
      ) : (
        <div>
          <div style={{ marginBottom: '20px' }}>
            <p>Connected: {address}</p>
            <button onClick={() => disconnect()}>
              Disconnect
            </button>
          </div>

          <div style={{ display: 'flex', gap: '20px', justifyContent: 'center' }}>
            <div className="card">
              <h3>ERC20 Token Balance</h3>
              {erc20Loading ? (
                <p>Loading...</p>
              ) : (
                <p>{erc20Balance ? formatEther(erc20Balance) : '0'} tokens</p>
              )}
              <p><small>Contract: {CONTRACTS.ERC20}</small></p>
            </div>

            <div className="card">
              <h3>TokenBank Balance</h3>
              {tokenBankLoading ? (
                <p>Loading...</p>
              ) : (
                <p>{tokenBankBalance ? formatEther(tokenBankBalance) : '0'} tokens</p>
              )}
              <p><small>Contract: {CONTRACTS.TOKENBANK}</small></p>
            </div>
          </div>

          <div style={{ marginTop: '20px' }}>
            <p><small>Delegator Contract: {CONTRACTS.DELEGATOR}</small></p>
          </div>

          {/* EIP-7702 Multicall Deposit Form */}
          <DepositForm />
        </div>
      )}
    </div>
  )
}

export default App
