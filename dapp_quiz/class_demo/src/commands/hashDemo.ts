import { Command } from '../utils/types';
import { hashMessage } from "viem";
import {keccak256, stringToHex} from "viem";

function legacyMessageHash(message: string) {
  return keccak256(stringToHex(message));
}

function eip191EncodeAndHash(message: string) {
  const prefix =`\x19Ethereum Signed Message:\n${message.length}`;
  const prefixMessage = prefix + message;
  return keccak256(stringToHex(prefixMessage));
}

export class HashDemoCommand implements Command {
  name = 'hash';
  description = 'Demo hash functions';

  async execute(args: any): Promise<void> {
    console.log('Running hash demo...');

    const message = "Hello, world!";
    console.log(`Raw message:\n${message}`);
    const hash = hashMessage(message);
    console.log(`Default viem hashMessage:\n${hash}`);

    const hash2 = eip191EncodeAndHash(message);
    console.log(`EIP-191 hash:\n${hash2}`);

    const hash3 = legacyMessageHash(message);
    console.log(`legacy hash:\n${hash3}`);
  }
}
