import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from './config/wagmi'
import TokenBankApp from './components/TokenBankApp'

const queryClient = new QueryClient()

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <TokenBankApp />
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
