import { walletClientEoa, eoa } from './config'
import { abi, contractAddress } from './contract'

// anvil user1

// 1. Authorize designation of the Contract onto the EOA.
const authorization = await walletClientEoa.signAuthorization({
    contractAddress,
    // executor: 'self'
    account: eoa,
})

console.log(authorization)


// 2. Designate the Contract on the EOA, and invoke the
//   `initialize` function.

const hash = await walletClientEoa.writeContract(
    {
        abi,
        address: walletClientEoa.account.address,
        authorizationList: [authorization],
        functionName: 'initialize',
        args: []
    }
)


console.log(hash)
