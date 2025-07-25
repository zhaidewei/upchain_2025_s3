import { hashMessage } from "viem";

const message = "Hello, world!";
const hash = hashMessage(message);
console.log(hash);
