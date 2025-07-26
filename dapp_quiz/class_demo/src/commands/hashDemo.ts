import { Command } from '../utils/types';
import { hashMessage } from "viem";
import {keccak256, stringToHex} from "viem";

export class HashDemoCommand implements Command {
  name = 'hash';
  description = 'Demo hash functions';

  async execute(args: any): Promise<void> {
    console.log('Running hash demo...');

    const message = "Hello, world!";
    console.log(`message: ${message}`);
    const hash = hashMessage(message);
    console.log(`normal hash: ${hash}`);

    function eip191EncodeAndHash(message: string) {
        const prefix =`\x19Ethereum Signed Message:\n${message.length}`;
        const prefixMessage = prefix + message;
        // 打印 prefixMessage 的 bytes 串（16进制），可以看到 0x19
        const prefixMessageHex = stringToHex(prefixMessage);
        console.log(`prefixMessage: ${prefixMessage}`);
        return keccak256(stringToHex(prefixMessage));
    }

    const hash2 = eip191EncodeAndHash(message);
    console.log(`eip191 hash: ${hash2}`);

    //可以看到两者的值是一样的，这是因为viem已经将hashMessage默认实现成了eip191的hash方式

    function legacyMessageHash(message: string) {
        return keccak256(stringToHex(message));
    }

    const hash3 = legacyMessageHash(message);
    console.log(`legacy hash: ${hash3}`);
  }
}
