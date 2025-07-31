// Goal, generate a EIP 712 signature
// https://viem.sh/docs/accounts/local/signTypedData
import { privateKeyToAccount } from 'viem/accounts'

// Get values from environment variables or use defaults
const ERC20_CONTRACT = process.env.ERC20_CONTRACT || '0x5FbDB2315678afecb367f032d93F642f64180aa3'
const OWNER_PRIVATE_KEY = process.env.OWNER_PRIVATE_KEY || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
const SPENDER_ADDRESS = process.env.SPENDER_ADDRESS || '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
const VALUE = process.env.VALUE || '10000000000000000000'
const DEADLINE = process.env.DEADLINE || '1753977600'
const NONCE = process.env.NONCE || '0'

// Domain Separator
async function main() {
const domain = {
    name: 'DeweiERC2612',
    version: '1.0',
    chainId: 31337,
    verifyingContract: ERC20_CONTRACT as `0x${string}`,
  }

// Types(the function that will be called with this signature)
// Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)
const types = {
    Permit: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
      { name: 'value', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  }

// data
const account = privateKeyToAccount(OWNER_PRIVATE_KEY as `0x${string}`)

//
const signature = await account.signTypedData({
    domain,
    types,
    primaryType: 'Permit',
    message: {
      owner: account.address,
      spender: SPENDER_ADDRESS,
      value: BigInt(VALUE),
      nonce: BigInt(NONCE),
      deadline: BigInt(DEADLINE),
    }
  })

  // Process the signature to extract v, r, s
  // Remove the '0x' prefix and split into r, s, v
  const signatureWithoutPrefix = signature.slice(2)

  // Extract r (first 32 bytes = 64 hex characters)
  const r = '0x' + signatureWithoutPrefix.slice(0, 64)

  // Extract s (next 32 bytes = 64 hex characters)
  const s = '0x' + signatureWithoutPrefix.slice(64, 128)

  // Extract v (last byte = 2 hex characters)
  const vHex = signatureWithoutPrefix.slice(128, 130)
  const v = parseInt(vHex, 16)

  console.log(JSON.stringify({ v, r, s }));
}

main()
