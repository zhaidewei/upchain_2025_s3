import { Command } from '../utils/types';
import { privateKeyToAccount } from "viem/accounts";

function parseSignature(signature: string) {
    const sig = signature.slice(2) // 去掉0x
    const r = '0x' + sig.slice(0, 64); // 前64位, 32字节
    const s = '0x' + sig.slice(64, 128); // 后64位, 32字节
    const v = parseInt(sig.slice(128, 130), 16); // 最后2位, 1字节
    return {r, s, v};
}

export class SignDemoCommand implements Command {
  name = 'sign';
  description = 'Demo sign functions';

  async execute(args: any): Promise<void> {
    console.log('Running sign demo...');
    const message = "Hello World!";
    const account = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
    console.log(`account: ${account}`);
    // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    const signature = await account.signMessage({message});
    console.log(`signature: ${signature}`);
    const {r, s, v} = parseSignature(signature);
    console.log(`r: ${r}`);
    console.log(`s: ${s}`);
    console.log(`v: ${v}`);
  }
}
