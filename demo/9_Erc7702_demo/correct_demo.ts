import { privateKeyToAccount } from 'viem/accounts'
import { walletClient, walletClientEoa } from './config'
import { abi, contractAddress } from './contract'

// anvil user1
const eoa = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");

console.log("=== ERC-7702 授权机制详解 ===")
console.log("Relay 地址:", walletClient.account?.address)
console.log("EOA 地址:", eoa.address)

// 方式 1: Relay 授权自己代表 EOA 执行
console.log("\n--- 方式 1: Relay 代理授权 ---")
const relayAuth = await walletClient.signAuthorization({
    account: eoa,  // 被代理的账户
    contractAddress,
})
console.log("Relay 签名的授权:", relayAuth)

// 方式 2: EOA 自己授权（更常见的方式）
console.log("\n--- 方式 2: EOA 自己授权 ---")
const eoaAuth = await walletClientEoa.signAuthorization({
    account: eoa,  // 自己授权自己
    contractAddress,
})
console.log("EOA 签名的授权:", eoaAuth)

// 使用授权执行合约调用
console.log("\n--- 使用授权执行合约调用 ---")
const hash = await walletClient.writeContract({
    abi,
    address: eoa.address,  // 目标：EOA 地址
    authorizationList: [relayAuth],  // 使用 relay 的授权
    functionName: 'initialize',
    args: []
})

console.log("交易哈希:", hash)
console.log("\n注意：虽然 relay 签名了授权，但合约调用是在 EOA 的上下文中执行的")
console.log("msg.sender 会是 EOA 地址，不是 relay 地址")
