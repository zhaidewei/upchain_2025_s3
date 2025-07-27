# TokenBank Frontend

A React dApp for interacting with the TokenBank smart contract using EIP-2612 permit functionality.

## Features

- 🔗 MetaMask wallet connection
- 💰 View token and bank balances
- 📝 EIP-712 signature-based deposits (permit deposit)
- 🎨 Clean, modern UI

## Prerequisites

- Node.js (v16 or higher)
- MetaMask browser extension
- Anvil local blockchain running on `http://localhost:8545`

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Open your browser and navigate to `http://localhost:5173`

## Contract Addresses

The frontend is configured to work with the following deployed contracts on Anvil:

- **Token Contract (Erc20Eip2612Compatiable)**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **Bank Contract (TokenBank)**: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`

## Usage

### 1. Connect Wallet
- Click "Connect MetaMask" to connect your wallet
- Ensure you're connected to the Anvil network (Chain ID: 31337)

### 2. View Balances
- Navigate to the "View Balances" tab
- See your token balance, bank balance, and allowance

### 3. Permit Deposit
- Navigate to the "Permit Deposit" tab
- Enter the amount you want to deposit
- Click "Permit Deposit" to sign and deposit tokens

## Technical Details

### EIP-2612 Implementation
The frontend implements EIP-2612 permit functionality for gasless token approvals:

1. **Nonce Management**: Automatically fetches and increments nonces
2. **EIP-712 Signing**: Creates structured data for wallet signing
3. **Permit Deposit**: Uses signature to approve and deposit tokens in one transaction

### Architecture
- **React 18** with TypeScript
- **Wagmi v2** for Ethereum interactions
- **Viem** for blockchain utilities
- **Vite** for fast development

## Development

### Project Structure
```
src/
├── components/
│   ├── TokenBankApp.tsx      # Main app component
│   ├── BalanceDisplay.tsx    # Balance viewing component
│   ├── PermitDeposit.tsx     # Permit deposit component
│   └── *.css                 # Component styles
├── config/
│   ├── wagmi.ts             # Wagmi configuration
│   └── contracts.ts         # Contract addresses and ABIs
└── App.tsx                  # Root component
```

### Adding Features
1. Create new components in `src/components/`
2. Add contract interactions using Wagmi hooks
3. Update styles in corresponding CSS files
4. Test with Anvil local blockchain

## Troubleshooting

### Common Issues

1. **"Failed to fetch" errors**: Ensure Anvil is running on port 8545
2. **"User rejected" errors**: Check MetaMask connection and network
3. **"Invalid signature" errors**: Verify nonce values and deadline

### Network Configuration
Make sure MetaMask is configured for Anvil:
- Network Name: Anvil
- RPC URL: http://localhost:8545
- Chain ID: 31337
- Currency Symbol: ETH

## License

MIT
