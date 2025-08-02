// imports
import { createWalletClient, http, encodeFunctionData } from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// Hardcode address and private keys.

const DELEGATE_ADDRESS = process.env.DELEGATOR_ADDRESS || "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
const USER1_PRIVATE_KEY = process.env.USER1_PRIVATE_KEY || "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

// create user1's wallet from private key
const walletClient = createWalletClient({
    account: privateKeyToAccount(USER1_PRIVATE_KEY as `0x${string}`),
    chain: anvil,
    transport: http("http://localhost:8545"),
});

// user1 authorize delegate contract. EIP7702

const signedAuthorization = await walletClient.signAuthorization(
    {
        address: DELEGATE_ADDRESS as `0x${string}`,
        executor: 'self'
    }
)

// Get contract addresses from environment
const ERC20_ADDRESS = process.env.ERC20_ADDRESS || "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const TOKENBANK_ADDRESS = process.env.TOKENBANK_ADDRESS || "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

// Construct call data for ERC20 approve
const approveCallData = encodeFunctionData({
    abi: [
        {
            "type": "function",
            "name": "approve",
            "inputs": [
                {
                    "name": "spender",
                    "type": "address"
                },
                {
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "outputs": [
                {
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable"
        }
    ],
    functionName: 'approve',
    args: [TOKENBANK_ADDRESS as `0x${string}`, 10000000000000000000n] // 10 tokens
});

// Construct call data for TokenBank deposit
const depositCallData = encodeFunctionData({
    abi: [
        {
            "type": "function",
            "name": "deposit",
            "inputs": [
                {
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "nonpayable"
        }
    ],
    functionName: 'deposit',
    args: [10000000000000000000n] // 10 tokens
});

console.log("approveCallData:", approveCallData);
console.log("depositCallData:", depositCallData);

// use EOA wallet to run the erc7702 delegated contract's multicall method

const abi = [
    {
        "type": "function",
        "name": "multicall",
        "inputs": [
            {
                "name": "targets",
                "type": "address[]",
                "internalType": "address[]"
            },
            {
                "name": "data",
                "type": "bytes[]",
                "internalType": "bytes[]"
            }
        ],
        "outputs": [
            {
                "name": "results",
                "type": "bytes[]",
                "internalType": "bytes[]"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "error",
        "name": "AddressEmptyCode",
        "inputs": [
            {
                "name": "target",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "FailedCall",
        "inputs": []
    }
]

const hash = await walletClient.writeContract(
    {
        abi,
        address: walletClient.account.address,
        authorizationList: [signedAuthorization],
        functionName: 'multicall',
        args: [
            [ERC20_ADDRESS as `0x${string}`, TOKENBANK_ADDRESS as `0x${string}`],
            [
                approveCallData,
                depositCallData
            ]
        ]
    }
)

console.log("hash:", hash)
// depositCallData
// TOKENBANK_ADDRESS as `0x${string}`
