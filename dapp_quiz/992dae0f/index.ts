#!/usr/bin/env ts-node
import { generatePrivateKey } from 'viem/accounts'
import { privateKeyToAccount } from 'viem/accounts'
import { argv } from './src/parse'
import { formatEther, parseEther } from 'viem'
import { anvil, baseSepolia, mainnet } from 'viem/chains'
import { Chain, createWalletClient, http, publicActions } from 'viem'

const privateKey = argv.genPrivateKey ? generatePrivateKey() : argv.privateKey

const mapping = {
    'anvil': anvil,
    'sepolia': baseSepolia,
    'mainnet': mainnet
}
console.log(`Using chain: ${argv.chain}`)

if (!privateKey) {
  console.error('No private key provided. Please use --genPrivateKey to generate one or provide --privateKey.');
  process.exit(1);
}

console.log(`Using private key: ${privateKey}`)

const account = privateKeyToAccount(privateKey as `0x${string}`)
console.log(`Using account: ${account.address}`)

console.log(`step 0: Get wallet client`)

const walletClient = createWalletClient({
    account: account,
    chain: mapping[argv.chain as keyof typeof mapping] || anvil,
    transport: http()
  }).extend(publicActions)

console.log('Step 1: Getting balance...')
walletClient.getBalance({
  address: account.address,
}).then((balance) => {
  console.log(`The account has ${formatEther(balance)} ETH`);
});

console.log(`Step 2: Sending transaction...`);

(async () => {
  const hash = await walletClient.sendTransaction({
    to: argv.to as `0x${string}`,
    value: parseEther(argv.value as string),
    data: argv.data as `0x${string}`
  })
  console.log('Transaction hash:', hash)
})()
