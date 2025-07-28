import { http } from 'wagmi'
import { anvil } from 'wagmi/chains'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { WagmiProvider } from 'wagmi'
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit'
import '@rainbow-me/rainbowkit/styles.css'

// 创建查询客户端
const queryClient = new QueryClient()

// 配置 RainbowKit
const config = getDefaultConfig({
  appName: 'ERC20 Transfer Viewer',
  projectId: 'YOUR_PROJECT_ID', // 可选
  chains: [anvil],
  transports: {
    [anvil.id]: http('http://127.0.0.1:8545'),
  },
})

export { config, queryClient }
export { WagmiProvider, RainbowKitProvider, QueryClientProvider }
