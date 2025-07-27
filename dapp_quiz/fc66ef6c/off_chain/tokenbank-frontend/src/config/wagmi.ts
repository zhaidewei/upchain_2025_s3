import { createConfig, http } from 'wagmi'
import { mainnet, sepolia, localhost } from 'wagmi/chains'
import { metaMask } from 'wagmi/connectors'

// Create a custom chain for Anvil
const anvil = {
  ...localhost,
  id: 31337,
  name: 'Anvil Local',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['http://localhost:8545'] },
    public: { http: ['http://localhost:8545'] },
  },
} as const

// Set up wagmi config
export const config = createConfig({
  chains: [anvil, mainnet, sepolia],
  connectors: [
    metaMask()
  ],
  transports: {
    [anvil.id]: http('http://localhost:8545'),
    [mainnet.id]: http(),
    [sepolia.id]: http(),
  },
})
