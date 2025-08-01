import { encodePacked, keccak256 } from 'viem';
import { MerkleTree } from "merkletreejs";

// Parse command line arguments
const args = process.argv.slice(2)
const argMap: { [key: string]: string } = {}

// Parse arguments in format: --key=value or -k=value
for (const arg of args) {
  if (arg.startsWith('--') || arg.startsWith('-')) {
    const [key, value] = arg.replace(/^--?/, '').split('=')
    if (key && value) {
      argMap[key] = value
    }
  }
}

// Get user index from command line or default to 2 (User2)
const USER_INDEX = parseInt(argMap.userIndex || argMap.u || '2')

const users = [
  { address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", amount: BigInt(1) }, //admin  white
  { address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", amount: BigInt(1) }, //user 1 white
  { address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", amount: BigInt(1) }, //user 2 white
  { address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906", amount: BigInt(0) }, //user 3 black
];

// Log which user we're generating proof for
console.error(`🔍 Generating merkle proof for user index ${USER_INDEX}: ${users[USER_INDEX].address}`)

// equal to MerkleDistributor.sol #keccak256(abi.encodePacked(account, amount));
const elements = users.map((x) =>
  keccak256(encodePacked(["address", "uint256"], [x.address as `0x${string}` , x.amount]))
);

// console.log(elements)

const merkleTree = new MerkleTree(elements, keccak256, { sort: true });

const root = merkleTree.getHexRoot();

const leaf = elements[USER_INDEX];
const proof = merkleTree.getHexProof(leaf);

const result = {
  root: root,
  proof: proof
};

console.error('✅ Merkle proof generated successfully')
console.log(JSON.stringify(result, null, 2));

/*
  {
    "root": "0x60085ee8ef3bdf8eeb89dd1f19d483471d03c887f95792ddb5abaf009d08b04f",
    "proof": [
      "0x67c6a2e151d4352a55021b5d0028c18121cfc24c7d73b179d22b17daff069c6e",
      "0x50eaa1c4e040e69eeb6f95b3f8898b4e9c226fa391c3b19060cc2259f7fe7c75"
    ]
  }
*/
