// Contract addresses - update these with your deployed contract addresses
export const CONTRACTS = {
  ERC20: "0x5FbDB2315678afecb367f032d93F642f64180aa3", // Update with your ERC20 address
  TOKENBANK: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0", // Update with your TokenBank address
  DELEGATOR: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9", // Update with your Delegator address
} as const

// ERC20 ABI
export const ERC20_ABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      }
    ],
    "name": "allowance",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const

// TokenBank ABI
export const TOKENBANK_ABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "getUserBalance",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const
