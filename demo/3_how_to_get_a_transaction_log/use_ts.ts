import { createPublicClient, http } from 'viem'
import { getTransactionReceipt } from 'viem/actions'
// https://viem.sh/docs/actions/public/getTransactionReceipt
import { anvil } from 'viem/chains'

// Create a public client
const client = createPublicClient({
  chain: anvil,
  transport: http('http://localhost:8545')
})

async function getTransactionLogs(txHash: string) {
  try {
    const receipt = await getTransactionReceipt(client, {
      hash: txHash as `0x${string}`
    })

    console.log('Transaction Receipt:')
    console.log('Status:', receipt.status)
    console.log('Block Number:', receipt.blockNumber)
    console.log('Gas Used:', receipt.gasUsed.toString())
    console.log('Logs Count:', receipt.logs.length)
    console.log('\nLogs:')

    // Print each log
    receipt.logs.forEach((log, index) => {
      console.log(`\nLog ${index + 1}:`)
      console.log('  Address:', log.address)
      console.log('  Topics:', log.topics)
      console.log('  Data:', log.data)
      console.log('  Log Index:', log.logIndex)
      console.log('  Transaction Index:', log.transactionIndex)
      console.log('  Block Number:', log.blockNumber)
      console.log('  Removed:', log.removed)
    })

    return receipt.logs
  } catch (error) {
    console.error('Error getting transaction logs:', error)
    throw error
  }
}

// Example usage
const txHash = "0x59ff0d33333200adc2308ce2a482e0e17ca0d07701f79cf31bcc1804db41daee"

getTransactionLogs(txHash)
  .then(logs => {
    console.log('\n✅ Successfully retrieved transaction logs')
    console.log(`Total logs: ${logs.length}`)
  })
  .catch(error => {
    console.error('❌ Failed to get transaction logs:', error)
  })
