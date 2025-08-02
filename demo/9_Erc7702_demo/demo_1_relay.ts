import { privateKeyToAccount } from 'viem/accounts'
import { walletClient } from './config'
import { abi, contractAddress } from './contract'

/*
EOA 用户签名授权：用户用自己的私钥签名，授权 relay 代表自己执行代码
Relay 执行交易：Relay 使用这个授权来调用合约，但执行上下文是用户的 EOA
执行上下文：代码在用户的 EOA 上下文下执行，不是 relay 的上下文
*/

// anvil user1
const eoa = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");


// 1. Authorize designation of the Contract onto the EOA.
const authorization = await walletClient.signAuthorization({
    account: eoa,
    contractAddress,
})


// 2. Designate the Contract on the EOA, and invoke the
//   `initialize` function.

const hash = await walletClient.writeContract(
    {
        abi,
        address: eoa.address,
        authorizationList: [authorization],
        functionName: 'initialize',
        args: []
    }
)

console.log(hash)

// 3. Direct contact, after authorization

const hash2 = await walletClient.writeContract({
    abi,
    address: eoa.address,
    functionName: 'ping',
})

console.log(hash2)
