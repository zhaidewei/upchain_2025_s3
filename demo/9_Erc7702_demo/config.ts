// goal: make wallet client

import { createWalletClient, http } from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// anvil admin
export const relay = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");

export const walletClient = createWalletClient(
    {
        account: relay,
        chain: anvil,
        transport: http("http://localhost:8545"),
    }
)

// anvil user1
export const eoa = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");

export const walletClientEoa = createWalletClient(
    {
        account: eoa,
        chain: anvil,
        transport: http("http://localhost:8545"),
    }
)
