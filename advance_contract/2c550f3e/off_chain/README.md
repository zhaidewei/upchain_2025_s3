# TokenBank Frontend

A simple React frontend for the TokenBank project with MetaMask integration and EIP-7702 delegation support.

## Features

- MetaMask wallet connection
- Display ERC20 token balance
- Display TokenBank balance
- Contract address display
- Modern UI with dark/light theme support

## Setup

1. Install dependencies:
```bash
npm install
```

2. Update contract addresses in `src/config/contracts.ts` with your deployed contract addresses:
```typescript
export const CONTRACTS = {
  ERC20: "YOUR_ERC20_ADDRESS",
  TOKENBANK: "YOUR_TOKENBANK_ADDRESS",
  DELEGATOR: "YOUR_DELEGATOR_ADDRESS",
}
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to `http://localhost:5173`

## Usage

1. Connect your MetaMask wallet
2. View your ERC20 token balance
3. View your TokenBank balance
4. See contract addresses for reference

## Prerequisites

- Node.js 18+
- MetaMask browser extension
- Local Anvil node running on `http://localhost:8545`
- Deployed contracts (ERC20, TokenBank, Delegator)

## Development

- Built with React 18 + TypeScript
- Uses Wagmi for Ethereum interactions
- Vite for fast development and building
- Tailwind CSS for styling (can be added if needed)
