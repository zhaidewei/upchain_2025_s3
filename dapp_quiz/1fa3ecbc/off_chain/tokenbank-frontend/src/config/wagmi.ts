import { createConfig, http } from 'wagmi'
import { anvil } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'

export const config = createConfig({
  chains: [anvil],
  connectors: [
    injected(),
  ],
  transports: {
    [anvil.id]: http('http://127.0.0.1:8545'),
  },
})
