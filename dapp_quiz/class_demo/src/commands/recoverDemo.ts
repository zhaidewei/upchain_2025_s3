import { Command } from '../utils/types';
import { hashMessage, recoverAddress, hexToBytes } from 'viem';

export class RecoverDemoCommand implements Command {
  name = 'recover';
  description = 'Demo address recovery from signature';

  async execute(args: any): Promise<void> {
    console.log('Running address recovery demo...');

    // 示例数据
    const message = "Hello, world!";
    const signature = "0xdd407c5cdfa26c1200e805eeed07d9195ce3aacc0d0d3e97e3f542eb474a8a167abf7e0310b5d2e35d2fd39ef59935672fae3d235b6757c5f66396f3df42fee61c";

    console.log(`Original message: ${message}`);
    console.log(`Signature: ${signature}`);

    // 方法1: 直接使用 viem 的 recoverAddress
    try {
      const recoveredAddress1 = await recoverAddress({
        hash: hashMessage(message),
        signature: signature as `0x${string}`,
      });
      console.log(`\n方法1 - 使用 viem recoverAddress:`);
      console.log(`Recovered address: ${recoveredAddress1}`);
    } catch (error) {
      console.error('方法1 失败:', error);
    }

    // 方法2: 手动分离 r、s、v 然后恢复
    console.log(`\n方法2 - 手动分离 r、s、v:`);
    const { r, s, v } = this.parseSignature(signature);
    console.log(`r: ${r}`);
    console.log(`s: ${s}`);
    console.log(`v: ${v} (decimal: ${parseInt(v, 16)})`);

    try {
      const recoveredAddress2 = await recoverAddress({
        hash: hashMessage(message),
        signature: {
          r: r as `0x${string}`,
          s: s as `0x${string}`,
          v: BigInt(parseInt(v, 16)),
        },
      });
      console.log(`Recovered address: ${recoveredAddress2}`);
    } catch (error) {
      console.error('方法2 失败:', error);
    }

    // 方法3: 使用 recoverMessageAddress (更直接)
    try {
      const { recoverMessageAddress } = await import('viem');
      const recoveredAddress3 = await recoverMessageAddress({
        message,
        signature: signature as `0x${string}`,
      });
      console.log(`\n方法3 - 使用 recoverMessageAddress:`);
      console.log(`Recovered address: ${recoveredAddress3}`);
    } catch (error) {
      console.error('方法3 失败:', error);
    }
  }

  private parseSignature(signature: string): { r: string; s: string; v: string } {
    const sig = signature.slice(2); // 移除 0x
    const r = '0x' + sig.slice(0, 64);   // 前32字节 (64个十六进制字符)
    const s = '0x' + sig.slice(64, 128); // 中32字节
    const v = sig.slice(128, 130);       // 最后1字节 (2个十六进制字符)

    return { r, s, v };
  }
}
