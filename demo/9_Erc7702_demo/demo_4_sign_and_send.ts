import { walletClient, eoa, walletClientEoa } from './config'
import { abi, contractAddress } from './contract'

const authorization = await walletClient.signAuthorization({
  account: eoa,
  contractAddress: contractAddress,
})

// Create bytecode to call the initialize() function
// This is the encoded function call for initialize()
const initializeData = "0x8129fc1c" // keccak256("initialize()")[:4]

const hash = await walletClient.sendTransaction({
  authorizationList: [authorization],
  data: initializeData,
  to: eoa.address,
})

console.log("Transaction hash:", hash)
