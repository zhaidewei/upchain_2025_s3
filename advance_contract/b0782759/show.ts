import { toHex, keccak256, pad } from 'viem'
import { createPublicClient, http } from 'viem'
import { anvil } from 'viem/chains'

const publicClient = createPublicClient(
    {
        chain: anvil,
        transport: http()
    }
)

const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'

async function getLockInf(baseSlot: bigint, i: number) {
    const userSlot = baseSlot + BigInt(i*2)
    const amountSlot = baseSlot + BigInt(i*2 + 1)
    console.log(`userSlot: ${userSlot}`)
    console.log(`amountSlot: ${amountSlot}`)

    const userData = await publicClient.getStorageAt(
        { address: CONTRACT_ADDRESS, slot: toHex(userSlot) }
    )
    const amountData = await publicClient.getStorageAt(
        { address: CONTRACT_ADDRESS, slot: toHex(amountSlot) }
    )

    console.log(`userData: ${userData}`)
    console.log(`amountData: ${amountData}`)
    // Parse the packed data: startTime (8 bytes) + address (20 bytes)
    const startTime = BigInt('0x' + (userData?.slice(2,26) || '0')) // First 24 bytes (startTime + padding)
    const user = '0x' + (userData?.slice(26, 66) || '') // Last 40 bytes (address)
    const amount = BigInt(amountData?.toString() || '0')

    console.log(`user: ${user}, startTime: ${startTime}, amount: ${amount}`)

}

async function main(){
    const lengthHex = await publicClient.getStorageAt(
        { address: CONTRACT_ADDRESS, slot: toHex(0) }
    )
    const length = BigInt(lengthHex?.toString() || '0')
    console.log(`The total length of the array is ${length}`)

    const p = 0n

    const baseSlot = keccak256(
        pad(`0x${p.toString(16)}`, { size: 32 })) // 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
    console.log(`baseSlot: ${baseSlot}`)

    // use baseSlot
    for (let i = 0; i < 11; i++) {
        await getLockInf(BigInt(baseSlot), i)}

    }

main()
