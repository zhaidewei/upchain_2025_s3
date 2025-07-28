import { createPublicClient, webSocket } from 'viem'
import { watchPendingTransactions, getTransaction } from 'viem/actions'
import { anvil } from 'viem/chains'

// Create a public client for anvil network
const client = createPublicClient({
  chain: anvil,
  transport: webSocket('ws://localhost:8545')
})

console.log('🔍 Starting to watch pending transactions on Anvil network...')
console.log('📡 Connected to: http://localhost:8545')
console.log('⏳ Waiting for pending transactions...\n')

// Watch pending transactions
const unwatch = watchPendingTransactions(client, {
  onTransactions: async (transactionHashes) => {
    console.log(`\n📦 Received ${transactionHashes.length} pending transaction hash(es):`)

    for (let i = 0; i < transactionHashes.length; i++) {
      const hash = transactionHashes[i]
      console.log(`\n--- Transaction ${i + 1} ---`)
      console.log('Hash:', hash)
      console.log('Status: Pending')

      try {
        // Get full transaction details
        const tx = await getTransaction(client, { hash })

        console.log('From:', tx.from)
        console.log('To:', tx.to || 'Contract Creation')
        console.log('Value:', tx.value ? `${tx.value} wei` : '0 wei')
        console.log('Gas Price:', tx.gasPrice ? `${tx.gasPrice} wei` : 'N/A')
        console.log('Max Fee Per Gas:', tx.maxFeePerGas ? `${tx.maxFeePerGas} wei` : 'N/A')
        console.log('Max Priority Fee Per Gas:', tx.maxPriorityFeePerGas ? `${tx.maxPriorityFeePerGas} wei` : 'N/A')
                console.log('Gas Limit:', tx.gas ? tx.gas.toString() : 'N/A')
        console.log('Nonce:', tx.nonce)
        console.log('Input Length:', tx.input ? `${tx.input.length} bytes` : '0 bytes')

        // Show first 100 characters of input if it exists
        if (tx.input && tx.input !== '0x') {
          console.log('Input Preview:', tx.input.slice(0, 100) + (tx.input.length > 100 ? '...' : ''))
        }

        // Show chain ID
        console.log('Chain ID:', tx.chainId)

        // Show transaction type
        console.log('Type:', tx.type || 'Legacy')

      } catch (error) {
        console.error('❌ Error getting transaction details:', error)
      }
    }
  },
  onError: (error) => {
    console.error('❌ Error watching pending transactions:', error)
  }
})

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Stopping pending transaction watcher...')
  unwatch()
  process.exit(0)
})

console.log('💡 Press Ctrl+C to stop watching')
console.log('🚀 Ready to monitor pending transactions!\n')
