/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_INFURA_API_KEY: string
  readonly VITE_ALCHEMY_ID: string
  readonly VITE_WALLETCONNECT_PROJECT_ID: string
  readonly VITE_TOKEN_ADDRESS: string
  readonly VITE_TOKENBANK_ADDRESS: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
