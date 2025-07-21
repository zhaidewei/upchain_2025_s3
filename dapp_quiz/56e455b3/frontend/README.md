# TokenBank DApp Frontend

A modern React + TypeScript frontend for the TokenBank decentralized application. This application allows users to deposit and withdraw ETH through a smart contract, view their balances, and see a leaderboard of top depositors.

## 🌟 Features

- **Wallet Connection**: Connect with MetaMask, WalletConnect, and other popular wallets
- **ETH Deposits**: Securely deposit ETH to the TokenBank smart contract
- **ETH Withdrawals**: Withdraw your deposited ETH anytime
- **Real-time Balances**: View your wallet balance and deposited amounts
- **Leaderboard**: See the top 3 depositors in real-time
- **Responsive Design**: Works seamlessly on desktop and mobile
- **Transaction Tracking**: Monitor transaction status with real-time updates

## 🛠 Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Styling framework
- **Wagmi** - React hooks for Ethereum
- **Viem** - TypeScript interface for Ethereum
- **ConnectKit** - Wallet connection UI
- **React Hot Toast** - Toast notifications
- **Lucide React** - Icon library

## 📋 Prerequisites

- Node.js 16+ and npm/yarn
- A Web3 wallet (MetaMask recommended)
- ETH for gas fees (testnet ETH for testing)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
# or
yarn install
```

### 2. Environment Setup

Copy the example environment file and fill in your values:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```env
# API Keys
VITE_INFURA_API_KEY=your_infura_api_key_here
VITE_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id

# Contract Addresses (filled after deployment)
VITE_TOKEN_ADDRESS=0x...
VITE_TOKENBANK_ADDRESS=0x...
```

### 3. Deploy Contracts First

Before running the frontend, you need to deploy the smart contracts:

```bash
cd ../contracts
# Follow the deployment instructions in contracts/DEPLOYMENT.md
```

Update your `.env` file with the deployed contract addresses.

### 4. Start Development Server

```bash
npm run dev
# or
yarn dev
```

The app will be available at `http://localhost:3000`

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_INFURA_API_KEY` | Infura project API key for RPC | Yes |
| `VITE_ALCHEMY_ID` | Alchemy API key (alternative to Infura) | No |
| `VITE_WALLETCONNECT_PROJECT_ID` | WalletConnect project ID | Yes |
| `VITE_TOKEN_ADDRESS` | Deployed ERC20 token contract address | Yes |
| `VITE_TOKENBANK_ADDRESS` | Deployed TokenBank contract address | Yes |
| `VITE_DEFAULT_NETWORK` | Default network (foundry/sepolia/mainnet) | No |

### Supported Networks

- **Foundry (Local)**: For development and testing
- **Sepolia Testnet**: For testnet deployment
- **Ethereum Mainnet**: For production deployment

## 📱 Usage Guide

### 1. Connect Wallet
- Click "Connect Wallet" in the top right
- Choose your preferred wallet (MetaMask, WalletConnect, etc.)
- Approve the connection

### 2. View Balances
- Your ETH balance is displayed in the top left card
- Your deposited ETH balance is shown in the top middle card

### 3. Deposit ETH
- Enter the amount of ETH you want to deposit
- Click "Deposit ETH" button
- Approve the transaction in your wallet
- Wait for confirmation

### 4. Withdraw ETH
- Enter the amount you want to withdraw (up to your deposited balance)
- Click "Withdraw ETH" button
- Approve the transaction in your wallet
- Wait for confirmation

### 5. View Leaderboard
- The bottom section shows the top 3 depositors
- Rankings update in real-time
- Your position will appear if you're in the top 3

## 🏗 Project Structure

```
src/
├── components/           # React components
│   ├── TokenBalance.tsx  # Display wallet ETH balance
│   ├── UserDeposits.tsx  # Display user's deposits
│   ├── DepositForm.tsx   # Deposit ETH form
│   ├── WithdrawForm.tsx  # Withdraw ETH form
│   └── TopDepositors.tsx # Leaderboard component
├── utils/
│   ├── config.ts         # Wagmi and network configuration
│   └── contracts.ts      # Contract addresses and ABIs
├── App.tsx              # Main app component
├── main.tsx             # App entry point
└── index.css            # Global styles and Tailwind
```

## 🔍 Component Details

### TokenBalance
- Displays user's wallet ETH balance
- Updates in real-time
- Shows wallet address

### UserDeposits
- Shows ETH deposited in TokenBank
- Real-time balance updates
- Visual indicators for deposit status

### DepositForm
- Form for depositing ETH
- Input validation
- Transaction status tracking
- Quick amount buttons

### WithdrawForm
- Form for withdrawing ETH
- Balance validation
- Max withdraw functionality
- Transaction status tracking

### TopDepositors
- Leaderboard of top 3 depositors
- Real-time rankings
- Visual rank indicators (trophy, medal, award)
- Formatted addresses and amounts

## 🛠 Development

### Available Scripts

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

### Code Style

- TypeScript for type safety
- ESLint for code linting
- Prettier for code formatting (recommended)
- Tailwind CSS for styling

### Adding New Features

1. Create new components in `src/components/`
2. Add contract interactions using Wagmi hooks
3. Update types in `src/types/` if needed
4. Add new routes if building a multi-page app

## 🐛 Troubleshooting

### Common Issues

1. **"Cannot connect to wallet"**
   - Ensure you have a Web3 wallet installed
   - Check if the wallet is unlocked
   - Try refreshing the page

2. **"Contract interaction failed"**
   - Verify contract addresses in `.env`
   - Check if you're on the correct network
   - Ensure you have enough ETH for gas

3. **"Transaction failed"**
   - Check if you have sufficient ETH balance
   - Verify gas price settings
   - Ensure contract is properly deployed

4. **"RPC connection error"**
   - Verify your Infura/Alchemy API key
   - Check network connectivity
   - Try switching RPC providers

### Debug Mode

Enable debug mode by adding to your `.env`:

```env
VITE_DEBUG=true
```

This will show additional logging in the browser console.

## 🚀 Deployment

### Build for Production

```bash
npm run build
```

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

### Deploy to Netlify

```bash
# Build the project
npm run build

# Upload dist/ folder to Netlify
```

### Environment Variables for Production

Make sure to set these in your hosting platform:

- `VITE_INFURA_API_KEY`
- `VITE_WALLETCONNECT_PROJECT_ID`
- `VITE_TOKEN_ADDRESS`
- `VITE_TOKENBANK_ADDRESS`

## 📸 Screenshots

After successful deployment and usage, add screenshots showing:

1. **Connected Wallet View**: Dashboard with balances
2. **Deposit Process**: Form filled out and transaction pending
3. **After Deposit**: Updated balances and transaction success
4. **Withdrawal Process**: Withdraw form and confirmation
5. **Leaderboard**: Top depositors displayed

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Run tests: `npm run test`
5. Commit changes: `git commit -am 'Add feature'`
6. Push to branch: `git push origin feature-name`
7. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Smart Contracts](../contracts/) - Backend smart contracts
- [Wagmi Documentation](https://wagmi.sh/) - React hooks for Ethereum
- [ConnectKit Documentation](https://docs.family.co/connectkit) - Wallet connection
- [Tailwind CSS](https://tailwindcss.com/) - Styling framework
- [Vite Documentation](https://vitejs.dev/) - Build tool

## 📞 Support

If you encounter any issues or have questions:

1. Check the troubleshooting section above
2. Review the [GitHub Issues](../../issues)
3. Create a new issue with detailed information
4. Join our [Discord community](https://discord.gg/your-server) for real-time help
