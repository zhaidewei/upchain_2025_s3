import { privateKeyToAccount } from 'viem/accounts'
import { walletClient, walletClientEoa } from './config'
import { abi, contractAddress } from './contract'

// anvil user1
const eoa = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");

console.log("=== 测试 1: 使用 relay walletClient ===")
console.log("walletClient 的 account:", walletClient.account?.address)
console.log("eoa 地址:", eoa.address)

// 测试 1: 使用 relay walletClient
const auth1 = await walletClient.signAuthorization({
    account: eoa,
    contractAddress,
})
console.log("Authorization 1:", auth1)

console.log("\n=== 测试 2: 使用 eoa walletClient ===")
console.log("walletClientEoa 的 account:", walletClientEoa.account?.address)

// 测试 2: 使用 eoa walletClient
const auth2 = await walletClientEoa.signAuthorization({
    account: eoa,
    contractAddress,
})
console.log("Authorization 2:", auth2)

console.log("\n=== 比较两个 authorization ===")
console.log("auth1 === auth2:", auth1 === auth2)
