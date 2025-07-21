import { createConfig, configureChains } from 'wagmi'
import { foundry, sepolia, mainnet } from 'wagmi/chains'
import { publicProvider } from 'wagmi/providers/public'
import { infuraProvider } from 'wagmi/providers/infura'
import { getDefaultWallets } from '@rainbow-me/rainbowkit'

// Configure chains and providers
const { chains, publicClient } = configureChains(
  [foundry, sepolia, mainnet],
  [
    infuraProvider({
      apiKey: import.meta.env.VITE_INFURA_API_KEY || 'demo'
    }),
    publicProvider(),
  ]
)

const { connectors } = getDefaultWallets({
  appName: 'TokenBank DApp',
  projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || 'demo',
  chains,
})

// Create wagmi config with RainbowKit
export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
})

export { chains }
