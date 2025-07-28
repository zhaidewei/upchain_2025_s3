import { createPublicClient, http } from 'viem'
import { getLogs } from 'viem/actions'
import { anvil } from 'viem/chains'

// Create a public client for anvil network
const client = createPublicClient({
  chain: anvil,
  transport: http('http://localhost:8545')
})

// Contract address (replace with your deployed ERC20 address)
const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'

async function getContractLogs() {
  try {
    console.log('🔍 Getting logs for contract:', CONTRACT_ADDRESS)
    console.log('📡 Connected to: http://localhost:8545')
    console.log('⏳ Fetching logs...\n')

    // Get logs for the specific contract
    //https://viem.sh/docs/actions/public/getLogs#getlogs
    const logs = await getLogs(client, {
      address: CONTRACT_ADDRESS as `0x${string}`,
      fromBlock: 0n,
      toBlock: 'latest',
      event: {
        type: 'event',
        name: 'Transfer',
        inputs: [
          { type: 'address', name: 'from', indexed: true },
          { type: 'address', name: 'to', indexed: true },
          { type: 'uint256', name: 'value', indexed: false }
        ]
      }
    })

    console.log(`📊 Found ${logs.length} Transfer events\n`)

    // Process each log
    logs.forEach((log, index) => {
      console.log(`--- Transfer Event ${index + 1} ---`)
      console.log('Block Number:', log.blockNumber)
      console.log('Transaction Hash:', log.transactionHash)
      console.log('Log Index:', log.logIndex)
      console.log('Contract Address:', log.address)

      // Parse the event data
      if (log.args) {
        console.log('From:', log.args.from)
        console.log('To:', log.args.to)
        console.log('Value:', log.args.value ? `${log.args.value} tokens` : 'N/A')
      }

      // Show topics
      console.log('Topics:')
      log.topics.forEach((topic, i) => {
        console.log(`  Topic ${i}:`, topic)
      })

      console.log('Data:', log.data)
      console.log('Removed:', log.removed)
      console.log('')
    })

    // Summary
    console.log('📈 Summary:')
    console.log(`Total Transfer events: ${logs.length}`)

    if (logs.length > 0) {
      const firstBlock = logs[0].blockNumber
      const lastBlock = logs[logs.length - 1].blockNumber
      console.log(`Block range: ${firstBlock} to ${lastBlock}`)
    }

  } catch (error) {
    console.error('❌ Error getting logs:', error)
  }
}

// Alternative method using raw topic filtering
async function getLogsByTopic() {
  try {
    console.log('\n🔍 Getting logs using topic filtering...\n')

    const logs = await getLogs(client, {
      address: CONTRACT_ADDRESS as `0x${string}`,
      fromBlock: 0n,
      toBlock: 'latest',
      event: {
        type: 'event',
        name: 'Transfer',
        inputs: [
          { type: 'address', name: 'from', indexed: true },
          { type: 'address', name: 'to', indexed: true },
          { type: 'uint256', name: 'value', indexed: false }
        ]
      }
    })

    console.log(`📊 Found ${logs.length} Transfer events using topic filtering\n`)

    logs.forEach((log, index) => {
      console.log(`--- Transfer Event ${index + 1} (Topic Method) ---`)
      console.log('Block Number:', log.blockNumber)
      console.log('Transaction Hash:', log.transactionHash)
      console.log('Contract Address:', log.address)
      console.log('Topics:', log.topics)
      console.log('Data:', log.data)
      console.log('')
    })

  } catch (error) {
    console.error('❌ Error getting logs by topic:', error)
  }
}

// Run both methods
async function main() {
  console.log('🚀 Starting ERC20 Transfer event log retrieval...\n')

  await getContractLogs()
  await getLogsByTopic()

  console.log('✅ Log retrieval complete!')
}

main().catch(console.error)
