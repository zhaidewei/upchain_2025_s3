import { createWeb3Modal } from '@web3modal/wagmi/react'
import { defaultWagmiConfig } from '@web3modal/wagmi/react/config'
import { WagmiProvider } from 'wagmi'
import { arbitrum, mainnet, localhost } from 'wagmi/chains'

// 1. Get projectId at https://cloud.walletconnect.com
// 注意：这是一个测试用的Project ID，生产环境请使用真实的Project ID
const projectId = import.meta.env.VITE_PROJECT_ID || 'c32cb9b0b86a4fa75e6bb1a6d0e88e93'

// 2. Create wagmiConfig
const metadata = {
  name: 'NFT Market',
  description: 'NFT Marketplace with WalletConnect',
  url: 'https://web3modal.com',
  icons: ['https://avatars.githubusercontent.com/u/37784886']
}

// 定义本地测试网络
const anvil = {
  id: 31337,
  name: 'Anvil',
  network: 'anvil',
  nativeCurrency: {
    decimals: 18,
    name: 'Ethereum',
    symbol: 'ETH',
  },
  rpcUrls: {
    public: { http: ['http://127.0.0.1:8545'] },
    default: { http: ['http://127.0.0.1:8545'] },
  },
} as const

const chains = [mainnet, arbitrum, anvil] as const
export const config = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
})

// 3. Create modal
createWeb3Modal({
  wagmiConfig: config,
  projectId,
  enableAnalytics: true,
})
