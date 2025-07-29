import { createWalletClient, http } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { mainnet } from 'viem/chains'
import { signTypedData } from 'viem/actions'
import { execSync } from 'child_process'
import { createPublicClient } from 'viem'

// 配置
const PERMIT2_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'
const TOKEN_ADDRESS = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'
const TOKEN_BANK_ADDRESS = '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0'
const USER1_PRIVATE_KEY = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
const USER1_ADDRESS = '0x70997970c51812dc3a010c7d01b50e0d17dc79c8'
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
const PERMIT_TRANSFER_FROM_TYPES = {
  PermitTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' }
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' }
  ]
}

async function generateSignatureAndCallTokenBank() {
  console.log('🎯 TokenBank depositWithPermit2 流程:')
  console.log('  1. User1签名授权TokenBank作为spender (EIP712签名包含spender)')
  console.log('  2. User1调用TokenBank的depositWithPermit2方法')
  console.log('  3. TokenBank调用Permit2.permitTransferFrom()')
  console.log('  4. Permit2验证签名并将token从User1转到TokenBank')
  console.log('  5. TokenBank更新User1的存款余额')

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
  // 获取区块链时间并计算deadline
  console.log('🕒 获取区块链时间进行deadline计算...')

  const blockchainTime = await publicClient.getBlock({ blockTag: 'latest' }).then(block => {
    const timestamp = Number(block.timestamp)
    console.log('✅ 成功获取区块链时间:', timestamp)
    console.log('📋 区块信息:', {
      number: block.number.toString(),
      timestamp: timestamp,
      hash: block.hash
    })
    return timestamp
  })

  const localTime = Math.floor(Date.now() / 1000)
  const timeDiff = Math.abs(blockchainTime - localTime)

  // 明确显示我们使用的是区块链时间
  console.log('🎯 使用区块链时间计算deadline（不是本地时间）！')
  console.log('📊 区块链时间:', blockchainTime, '(用作deadline基准)')
  console.log('📊 本地机器时间:', localTime, '(仅用于对比)')

  const deadline = BigInt(blockchainTime + 24 * 3600) // 24小时buffer
  const amount = 10_000_000_000_000_000_000n // 10 tokens

  console.log('✅ Deadline已使用区块链时间计算（非本地时间）')

  console.log('=== 时间同步调试信息 ===')
  console.log('🔹 时间基准来源: 区块链时间')
  console.log('🔹 区块链时间 (秒):', blockchainTime)
  console.log('🔹 本地时间 (秒):', localTime)
  console.log('🔹 时间差异:', timeDiff, '秒')
  console.log('🔹 Deadline (秒):', deadline.toString())
  console.log('🔹 距离deadline时间:', Number(deadline) - blockchainTime, '秒 (24小时)')
  console.log('🔹 区块链时间字符串:', new Date(blockchainTime * 1000).toString())
  console.log('🔹 本地时间字符串:', new Date(localTime * 1000).toString())
  console.log('🔹 Deadline时间字符串:', new Date(Number(deadline) * 1000).toString())

  if (timeDiff > 60) {
    console.warn('⚠️ 检测到显著时间差异:', timeDiff, '秒')
    console.warn('💡 但不用担心 - 我们使用区块链时间作为deadline基准！')
  } else {
    console.log('✅ 区块链时间与本地时间同步良好（差异 < 1分钟）')
  }
  console.log('==============================')

  // 🎯 EIP712签名：包含spender字段（TokenBank地址）
  const valuesForSigning = {
    permitted: {
      token: TOKEN_ADDRESS as `0x${string}`,
      amount: amount
    },
    spender: TOKEN_BANK_ADDRESS as `0x${string}`,  // EIP712签名中包含TokenBank作为spender
    nonce: nonce,
    deadline: deadline
  }

  console.log('\n🔍 EIP712签名数据 (包含TokenBank作为spender):')
  console.log('  Domain:', DOMAIN)
  console.log('  Types:', PERMIT_TRANSFER_FROM_TYPES)
  console.log('  Message:', valuesForSigning)
  console.log('  🎯 关键：EIP712签名包含TokenBank作为spender字段')

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

  // 🎯 调用TokenBank的depositWithPermit2方法
  const castCommand = `cast send --rpc-url http://127.0.0.1:8545 \
    --private-key ${USER1_PRIVATE_KEY} \
    ${TOKEN_BANK_ADDRESS} \
    "depositWithPermit2(address,uint256,uint256,uint256,bytes)" \
    ${USER1_ADDRESS} \
    ${amount.toString()} \
    ${deadline.toString()} \
    ${nonce.toString()} \
    ${signature}`

  console.log('\n🚀 User1调用TokenBank的depositWithPermit2方法:')
  console.log('  调用者:', 'User1 (msg.sender)')
  console.log('  合约地址:', TOKEN_BANK_ADDRESS)
  console.log('  方法:', 'depositWithPermit2')
  console.log('  参数:')
  console.log(`    owner: ${USER1_ADDRESS}`)
  console.log(`    amount: ${amount.toString()}`)
  console.log(`    deadline: ${deadline.toString()}`)
  console.log(`    nonce: ${nonce.toString()}`)
  console.log(`    signature: ${signature}`)
  console.log('\n📋 完整命令:')
  console.log(castCommand)

  console.log('\n🔄 执行流程:')
  console.log('  1. User1签名授权TokenBank为spender (EIP712包含TokenBank)')
  console.log('  2. User1调用TokenBank.depositWithPermit2()')
  console.log('  3. TokenBank调用Permit2.permitTransferFrom()')
  console.log('  4. Permit2验证签名中spender == TokenBank')
  console.log('  5. Permit2将User1的token转给TokenBank')
  console.log('  6. TokenBank更新User1的存款余额')
  console.log('  7. ✅ 完成！通过TokenBank进行存款')

  try {
    const result = execSync(castCommand, { encoding: 'utf8' })
    console.log('\n🎉 TokenBank depositWithPermit2调用成功:')
    console.log(result)
    return { success: true, signature, result, nonce: nonce.toString() }
  } catch (error) {
    console.log('\n❌ TokenBank depositWithPermit2调用失败:')
    console.log(error)
    return { success: false, signature, error, nonce: nonce.toString() }
  }
}

generateSignatureAndCallTokenBank().catch(console.error)
