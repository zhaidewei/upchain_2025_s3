import { keccak256, toEventSignature, stringToHex, toBytes } from 'viem'

function getEventSignatureHash(eventSignature: string): string {
  const normalizedSignature = toEventSignature(eventSignature.trim())
  return keccak256(toBytes(normalizedSignature))
}

const eventSignature = "Transfer(address indexed from, address indexed to, uint256 value)"

const signatureHash = getEventSignatureHash(eventSignature)

console.log(`Event signature: ${eventSignature}`)
console.log(`Signature hash (topic0): ${signatureHash}`)

//0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
