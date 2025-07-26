import { Command } from '../utils/types';
import { hashMessage } from "viem";
import {keccak256, stringToHex, parseEther} from "viem";

import { privateKeyToAccount } from "viem/accounts";
import { createWalletClient, http } from "viem";
import { anvil } from "viem/chains";

export class SignEip712Command implements Command {
  name = 'signEip712';
  description = 'Demo signEip712';

  async execute(args: any): Promise<void> {
    console.log('Running signEip712 demo...');
    // 1. Domain part
    const domain = {
        name: 'EIP712Verifier',
        version: '1.0.0',
        chainId: Number(31337), // anvil chainId
        // 使用普通地址与测试保持一致，避免预编译地址
        verifyingContract: '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720' as `0x${string}`,
        };
    console.log('Domain:', JSON.stringify(domain, null, 2));
    // 2. Types part
    const types = {
        Send: [
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        ]};
    const msg = {
        to: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" as `0x${string}`,
        value: parseEther("0.001"), // 1GWei
        };
    console.log('Message:', JSON.stringify(msg, (key, value) => {
        return typeof value === 'bigint' ? value.toString() : value;
      }, 2));

      // get Wallet
    const account = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
    const wallet = createWalletClient(
        {
            account,
            chain: anvil,
            transport: http(),
        }
    )
    const signature = await wallet.signTypedData({
        account:account,
        domain:domain,
        types:types,
        primaryType: 'Send',
        message: msg,
    });
    console.log('Signature:', signature);
    // 0xf46c78c8b2576e06117fa5cbb2ae13fa1c5ff849bef76fa60ebdd92f5643ff113e36970120db648fd8dc28deeffaf2ac84ca4270f5515fc8775152122744fec71b
  }
}
