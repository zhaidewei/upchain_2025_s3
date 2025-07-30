import tokenABI from '../abi_Erc20Eip2612Compatiable.json'
import bankABI from '../abi_TokenBank.json'

// Contract addresses from deployment
export const CONTRACTS = {
  TOKEN: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' as const,
  BANK: '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0' as const,
} as const

// Contract ABIs
export const ABIS = {
  TOKEN: tokenABI,
  BANK: bankABI,
} as const

// EIP-712 Domain for permit
export const PERMIT_DOMAIN = {
  name: 'DeweiERC2612',
  version: '1.0',
  chainId: 31337, // Anvil local network
  verifyingContract: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' as const,
} as const

// Chain configuration
export const CHAIN_CONFIG = {
  id: 31337,
  name: 'Anvil Local',
  rpcUrl: 'http://localhost:8545',
} as const

// Permit types for EIP-712
export const PERMIT_TYPES = {
  Permit: [
    { name: 'owner', type: 'address' },
    { name: 'spender', type: 'address' },
    { name: 'value', type: 'uint256' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
  ],
} as const
