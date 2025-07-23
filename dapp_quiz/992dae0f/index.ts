#!/usr/bin/env ts-node
import dotenv from 'dotenv'
dotenv.config()
import { generatePrivateKey } from 'viem/accounts'
import { privateKeyToAccount } from 'viem/accounts'
import { argv } from './src/parse'
import { formatEther, parseEther } from 'viem'
import { anvil, mainnet } from 'viem/chains'
import { Chain, createWalletClient, http, publicActions, parseGwei, encodeFunctionData, parseAbi  } from 'viem'
import { mySepolia } from './src/mySepolia'

// step 1: private key -> account
// 当genPrivateKey和privateKey都没有配置时，会取到env var
let privateKey: string | undefined;
if (argv.genPrivateKey) {
  privateKey = generatePrivateKey();
} else if (argv.privateKey) {
  privateKey = argv.privateKey;
} else if (process.env.PRIVATE_KEY) {
  privateKey = process.env.PRIVATE_KEY;
} else {
  privateKey = undefined;
}

if (!privateKey) {
  console.error('No private key provided. Please use --genPrivateKey to generate one or provide --privateKey or set PRIVATE_KEY in environment variables.');
  process.exit(1);
}

const account = privateKeyToAccount(privateKey as `0x${string}`)
console.log(`Using account: ${account.address}`)

// Step 2: Get Wallet Client


const mapping = {
    'anvil': anvil,
    'sepolia': mySepolia,
    'mainnet': mainnet
}
const chain = mapping[argv.chain as keyof typeof mapping] || anvil;
const walletClient = createWalletClient({
    account: account,
    chain: chain,
    transport: http()
  }).extend(publicActions)

// Step 3: Get ETH Balance of the account at the chain
walletClient.getBalance({
  address: account.address,
}).then((balance) => {
  console.log(`The account has ${balance} ETH`);
});


//Step 4: Before transfer, check the Token balance of the admin account
/*
export ERC20=0x264C4E0c7AD58d979e8648428791FbE06edAA23F
export OWNER=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2

cast call $ERC20 "balanceOf(address)(uint256)" $OWNER --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
*/


const txParams = {
    gas: BigInt(50000),
    maxFeePerGas: parseGwei('20'),
    maxPriorityFeePerGas: parseGwei('3'),
  to: process.env.ERC20_ADDR as `0x${string}`,
  value: BigInt(0),
  data: encodeFunctionData({
    abi: parseAbi(['function balanceOf(address) view returns (uint256)']),
    functionName: 'balanceOf',
    args: [process.env.OWNER as `0x${string}`],
  })
};

(async () => {
    const request = await walletClient.prepareTransactionRequest(txParams);
    // Step 4: Sign transaction
    const signature = await walletClient.signTransaction(request as any);
    // Step 5: Send signed transaction
    const hash = await walletClient.sendRawTransaction({ serializedTransaction: signature });
    console.log('Transaction hash:', hash);
})();


//Step 5: Transfer Token
/*

TO_ADDR=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
ERC20=0x264C4E0c7AD58d979e8648428791FbE06edAA23F
OWNER=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2

cast call $ERC20 "balanceOf(address)(uint256)" $OWNER --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call $ERC20 "balanceOf(address)(uint256)" $TO_ADDR --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
*/
const txParams2 = {
    gas: BigInt(500000),
    maxFeePerGas: parseGwei('20'),
    maxPriorityFeePerGas: parseGwei('3'),
  to: process.env.ERC20_ADDR as `0x${string}`,
  value: BigInt(0),
  data: encodeFunctionData({
    abi: parseAbi(['function transfer(address _to, uint256 _value) returns (bool)']),
    functionName: 'transfer',
    args: [process.env.TO_ADDR as `0x${string}`, BigInt(1000000000)],
  })
};

(async () => {
    const request = await walletClient.prepareTransactionRequest(txParams2);
    // Step 4: Sign transaction
    const signature = await walletClient.signTransaction(request as any);
    // Step 5: Send signed transaction
    const hash = await walletClient.sendRawTransaction({ serializedTransaction: signature });
    console.log('Transaction hash:', hash);
})();

