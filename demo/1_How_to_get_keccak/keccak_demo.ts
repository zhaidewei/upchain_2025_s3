
import { keccak256, toBytes} from "viem";

const hash = keccak256(toBytes("Hello"));

console.log(hash);

// npm install tsx -g
// tsx keccak_demo.ts
// 0x06b3dfaec148fb1bb2b066f10ec285e7c9bf402ab32aa78a5d38e34566810cd2
