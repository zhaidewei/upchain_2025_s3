import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from './config/wagmi'
import TokenBankApp from './components/TokenBankApp'
import './App.css'

const queryClient = new QueryClient()

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <div className="App">
          <header className="App-header">
            <h1>TokenBank dApp</h1>
          </header>
          <main>
            <TokenBankApp />
          </main>
        </div>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
