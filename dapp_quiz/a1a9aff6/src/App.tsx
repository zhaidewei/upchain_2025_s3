import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from './config/wagmi'
import Header from './components/Header'
import NFTMarket from './components/NFTMarket'

const queryClient = new QueryClient()

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <div className="min-h-screen bg-gray-100">
          <Header />
          <main className="container mx-auto px-4 py-8">
            <NFTMarket />
          </main>
        </div>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
