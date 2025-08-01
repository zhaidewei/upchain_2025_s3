import { toHex, encodePacked, keccak256 } from 'viem';

// 验证Merkle Proof的函数
function verifyMerkleProof(
  leaf: string,
  proof: string[],
  root: string
): boolean {
  let computedHash = leaf;

  for (let i = 0; i < proof.length; i++) {
    const proofElement = proof[i];

    // 按照排序规则组合哈希
    if (computedHash <= proofElement) {
      computedHash = keccak256(encodePacked(["bytes32", "bytes32"], [computedHash as `0x${string}`, proofElement as `0x${string}`]));
    } else {
      computedHash = keccak256(encodePacked(["bytes32", "bytes32"], [proofElement as `0x${string}`, computedHash as `0x${string}`]));
    }
  }

  return computedHash === root;
}

// 你的数据
const users = [
  { address: "0xD08c8e6d78a1f64B1796d6DC3137B19665cb6F1F", amount: BigInt(10) },
  { address: "0xb7D15753D3F76e7C892B63db6b4729f700C01298", amount: BigInt(15) },
  { address: "0xf69Ca530Cd4849e3d1329FBEC06787a96a3f9A68", amount: BigInt(20) },
  { address: "0xa8532aAa27E9f7c3a96d754674c99F1E2f824800", amount: BigInt(30) },
];

// 计算User3的叶子节点
const user3Leaf = keccak256(encodePacked(["address", "uint256"], [
  "0xa8532aAa27E9f7c3a96d754674c99F1E2f824800" as `0x${string}`,
  BigInt(30)
]));

console.log("User3的叶子节点哈希:", user3Leaf);

// 你的proof和root
const proof = [
  "0xd24d002c88a75771fc4516ed00b4f3decb98511eb1f7b968898c2f454e34ba23",
  "0x4e48d103859ea17962bdf670d374debec88b8d5f0c1b6933daa9eee9c7f4365b"
];

const root = "0x4d391566fe6a949654a1da6b9afda4ecda69d6046bce3694e953c5b64c63ea47";

// 验证proof
const isValid = verifyMerkleProof(user3Leaf, proof, root);

console.log("\n=== Merkle Proof 验证结果 ===");
console.log("叶子节点:", user3Leaf);
console.log("Proof:", proof);
console.log("Root:", root);
console.log("验证结果:", isValid ? "✅ 有效" : "❌ 无效");

// 演示验证过程
console.log("\n=== 验证过程演示 ===");
let current = user3Leaf;
console.log("步骤0 - 叶子节点:", current);

// 第一步
const sibling1 = proof[0];
if (current <= sibling1) {
  current = keccak256(encodePacked(["bytes32", "bytes32"], [current as `0x${string}`, sibling1 as `0x${string}`]));
} else {
  current = keccak256(encodePacked(["bytes32", "bytes32"], [sibling1 as `0x${string}`, current as `0x${string}`]));
}
console.log("步骤1 - 与兄弟节点配对后:", current);

// 第二步
const sibling2 = proof[1];
if (current <= sibling2) {
  current = keccak256(encodePacked(["bytes32", "bytes32"], [current as `0x${string}`, sibling2 as `0x${string}`]));
} else {
  current = keccak256(encodePacked(["bytes32", "bytes32"], [sibling2 as `0x${string}`, current as `0x${string}`]));
}
console.log("步骤2 - 与兄弟节点配对后:", current);

console.log("最终结果是否等于根:", current === root ? "✅ 是" : "❌ 否");
