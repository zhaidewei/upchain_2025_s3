# TokenBank Frontend

A simple React frontend for the TokenBank project with MetaMask integration and EIP-7702 delegation support.

## Features

- MetaMask wallet connection
- Display ERC20 token balance
- Display TokenBank balance
- Contract address display
- **EIP-7702 Multicall functionality** - Approve and deposit tokens in a single transaction
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
4. **Use EIP-7702 Multicall**: Enter an amount and click "Execute Multicall" to approve and deposit tokens in one transaction
5. See contract addresses for reference

## EIP-7702 Multicall

The frontend implements EIP-7702 delegation to allow users to:
- Approve ERC20 tokens for TokenBank in a single transaction
- Deposit tokens to TokenBank in the same transaction
- All through the user's EOA wallet with proper authorization

This eliminates the need for separate approve and deposit transactions, improving user experience and reducing gas costs.

## Prerequisites

- Node.js 18+
- MetaMask browser extension
- Local Anvil node running on `http://localhost:8545`
- Deployed contracts (ERC20, TokenBank, Delegator)

## Development

- Built with React 18 + TypeScript
- Uses Wagmi for Ethereum interactions
- Vite for fast development and building
- EIP-7702 delegation for multicall functionality
