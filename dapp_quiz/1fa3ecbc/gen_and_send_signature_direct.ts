import { createWalletClient, http } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { mainnet } from 'viem/chains'
import { signTypedData } from 'viem/actions'
import { execSync } from 'child_process'
import { createPublicClient } from 'viem'

// 配置
const PERMIT2_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'
const TOKEN_ADDRESS = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'
const TOKEN_BANK_ADDRESS = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0'
const USER1_PRIVATE_KEY = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
const USER1_ADDRESS = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
const USER2_PRIVATE_KEY = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
const USER2_ADDRESS = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'

// 创建公共客户端用于查询
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('http://127.0.0.1:8545')
})

// 函数：检查nonce是否已被使用
async function checkNonceUsed(owner: string, nonce: bigint): Promise<boolean> {
  const wordPos = nonce / 256n
  const bitPos = nonce % 256n

  try {
    const bitmap = await publicClient.readContract({
      address: PERMIT2_ADDRESS as `0x${string}`,
      abi: [{
        name: 'nonceBitmap',
        type: 'function',
        inputs: [
          { name: 'owner', type: 'address' },
          { name: 'wordPos', type: 'uint256' }
        ],
        outputs: [{ name: '', type: 'uint256' }],
        stateMutability: 'view'
      }],
      functionName: 'nonceBitmap',
      args: [owner as `0x${string}`, wordPos]
    })

    const bit = (bitmap >> bitPos) & 1n
    return bit === 1n
  } catch (error) {
    console.error('❌ 查询nonce状态失败:', error)
    return false
  }
}

// 函数：寻找未使用的nonce
async function findUnusedNonce(owner: string, startNonce: bigint = 0n): Promise<bigint> {
  console.log(`🔍 为 ${owner} 寻找未使用的nonce，从 ${startNonce.toString()} 开始...`)

  let currentNonce = startNonce
  const maxAttempts = 1000

  for (let i = 0; i < maxAttempts; i++) {
    const used = await checkNonceUsed(owner, currentNonce)

    if (!used) {
      console.log(`✅ 找到未使用的nonce: ${currentNonce.toString()}`)
      return currentNonce
    }

    currentNonce += 1n
  }

  console.log(`❌ 在 ${maxAttempts} 次尝试内未找到未使用的nonce`)
  return startNonce // 返回起始值作为后备
}

// 使用正确的domain定义（无version字段）
const DOMAIN = {
  name: 'Permit2',
  chainId: 31337,
  verifyingContract: PERMIT2_ADDRESS as `0x${string}`
}

// EIP712 Types for PermitTransferFrom (根据Permit2官方源码)
// 🎯 关键：EIP712签名中必须包含spender字段，但函数调用时不包含，从msg.sender提取
//  bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
//  "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
//);
const PERMIT_TRANSFER_FROM_TYPES = {
  PermitTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions' },
    { name: 'spender', type: 'address' },        // EIP712签名中必须包含， what about its position?
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' }
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' }
  ]
}

async function generateSignatureAndCallPermit2Direct() {
  console.log('🎯 修正后的Permit2直接调用流程:')
  console.log('  1. User1签名授权User2作为spender (EIP712签名包含spender)')
  console.log('  2. User2直接调用Permit2的permitTransferFrom方法 (函数参数不包含spender)')
  console.log('  3. Permit2从msg.sender获取spender，验证签名中spender字段')
  console.log('  4. 成功转移token从User1到User2')

  const client = createWalletClient({
    chain: mainnet,
    transport: http('http://127.0.0.1:8545')
  })

  const user1Account = privateKeyToAccount(USER1_PRIVATE_KEY as `0x${string}`)

  // 检查并获取可用的nonce
  console.log('\n🔍 检查nonce状态...')

  // 检查环境变量中是否有推荐的nonce
  const recommendedNonce = process.env.RECOMMENDED_NONCE
  let nonce: bigint

  if (recommendedNonce) {
    nonce = BigInt(recommendedNonce)
    console.log(`📋 使用推荐的nonce: ${nonce.toString()}`)
  } else {
    // 自动寻找未使用的nonce
    nonce = await findUnusedNonce(USER1_ADDRESS, 0n)
    console.log(`🎯 自动选择的nonce: ${nonce.toString()}`)
  }

  // 验证nonce是否可用
  const isUsed = await checkNonceUsed(USER1_ADDRESS, nonce)
  if (isUsed) {
    console.log(`⚠️  nonce ${nonce.toString()} 已被使用，重新寻找...`)
    nonce = await findUnusedNonce(USER1_ADDRESS, nonce + 1n)
  }

  console.log(`✅ 最终使用的nonce: ${nonce.toString()}`)

  // 准备签名数据
  const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600) // 1小时后过期
  const amount = 10_000_000_000_000_000_000n // 10 tokens

  // 🎯 EIP712签名：包含spender字段
  const valuesForSigning = {
    permitted: {
      token: TOKEN_ADDRESS as `0x${string}`,
      amount: amount
    },
    spender: USER2_ADDRESS as `0x${string}`,  // EIP712签名中包含spender
    nonce: nonce,
    deadline: deadline
  }

  console.log('\n🔍 EIP712签名数据 (包含spender):')
  console.log('  Domain:', DOMAIN)
  console.log('  Types:', PERMIT_TRANSFER_FROM_TYPES)
  console.log('  Message:', valuesForSigning)
  console.log('  🎯 关键：EIP712签名包含spender字段')

  // User1生成签名
  const signature = await signTypedData(client, {
    account: user1Account,
    domain: DOMAIN,
    types: PERMIT_TRANSFER_FROM_TYPES,
    primaryType: 'PermitTransferFrom',
    message: valuesForSigning
  })

  console.log('\n✅ User1生成的签名:')
  console.log(signature)

  // 🎯 修正：函数调用时PermitTransferFrom结构不包含spender字段
  // 根据ISignatureTransfer接口，PermitTransferFrom只包含：permitted, nonce, deadline
  const castCommand = `cast send --rpc-url http://127.0.0.1:8545 \
    --private-key ${USER2_PRIVATE_KEY} \
    ${PERMIT2_ADDRESS} \
    "permitTransferFrom(((address,uint256),uint256,uint256),(address,uint256),address,bytes)" \
    "((${TOKEN_ADDRESS},${amount.toString()}),${nonce.toString()},${deadline.toString()})" \
    "(${USER2_ADDRESS},${amount.toString()})" \
    ${USER1_ADDRESS} \
    ${signature}`

  console.log('\n🚀 User2调用Permit2的permitTransferFrom方法:')
  console.log('  调用者:', 'User2 (msg.sender作为spender)')
  console.log('  合约地址:', PERMIT2_ADDRESS)
  console.log('  方法:', 'permitTransferFrom')
  console.log('  参数结构:')
  console.log('    permit (PermitTransferFrom):')
  console.log(`      permitted.token: ${TOKEN_ADDRESS}`)
  console.log(`      permitted.amount: ${amount.toString()}`)
  console.log(`      nonce: ${nonce.toString()}`)
  console.log(`      deadline: ${deadline.toString()}`)
  console.log(`      (不包含spender - 从msg.sender获取)`)
  console.log('    transferDetails (SignatureTransferDetails):')
  console.log(`      to: ${USER2_ADDRESS}`)
  console.log(`      requestedAmount: ${amount.toString()}`)
  console.log(`    owner: ${USER1_ADDRESS}`)
  console.log(`    signature: ${signature}`)
  console.log('\n📋 完整命令:')
  console.log(castCommand)

  console.log('\n🔄 执行流程:')
  console.log('  1. User1签名授权User2为spender (EIP712包含spender)')
  console.log('  2. User2调用Permit2.permitTransferFrom() (函数参数不包含spender)')
  console.log('  3. Permit2验证签名中spender == msg.sender (User2)')
  console.log('  4. Permit2将User1的token转给User2')
  console.log('  5. ✅ 完成！结构正确')

  try {
    const result = execSync(castCommand, { encoding: 'utf8' })
    console.log('\n🎉 Permit2 permitTransferFrom调用成功:')
    console.log(result)
    return { success: true, signature, result, nonce: nonce.toString() }
  } catch (error) {
    console.log('\n❌ Permit2 permitTransferFrom调用失败:')
    console.log(error)
    return { success: false, signature, error, nonce: nonce.toString() }
  }
}

generateSignatureAndCallPermit2Direct().catch(console.error)
