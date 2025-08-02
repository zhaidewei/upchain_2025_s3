import { walletClient, eoa, walletClientEoa } from './config'
import { abi, contractAddress } from './contract'

const authorization = await walletClient.signAuthorization({
  account: eoa,
  contractAddress: contractAddress,
})

// Create bytecode to call the ping() function
// This is the encoded function call for ping()
const pingData = "0x5c36b186" // keccak256("ping()")[:4]

const hash = await walletClient.sendTransaction({
  authorizationList: [authorization],
  data: pingData,
  to: eoa.address,
})

console.log("Transaction hash:", hash)
