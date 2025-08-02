import { privateKeyToAccount } from 'viem/accounts'
import { walletClient } from './config'
import { abi, contractAddress } from './contract'

// anvil user1
const eoa = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");


// 1. Authorize designation of the Contract onto the EOA.
const authorization = await walletClient.prepareAuthorization(
     {
        chainId: 31337,
        contractAddress: contractAddress,
        nonce: 1,
        account: eoa,
     }
)

const signature = await walletClient.signAuthorization(authorization)

console.log(signature)

// 2. Designate the Contract on the EOA, and invoke the
//   `initialize` function.

const hash = await walletClient.writeContract(
    {
        abi,
        address: eoa.address,
        authorizationList: [signature],
        functionName: 'initialize',
        args: []
    }
)

console.log(hash)
