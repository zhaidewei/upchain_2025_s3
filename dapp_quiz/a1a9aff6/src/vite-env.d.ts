/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_PROJECT_ID: string
  readonly VITE_ERC20_ADDRESS: string
  readonly VITE_ERC721_ADDRESS: string
  readonly VITE_NFT_MARKET_ADDRESS: string
  readonly VITE_ANVIL_RPC_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
