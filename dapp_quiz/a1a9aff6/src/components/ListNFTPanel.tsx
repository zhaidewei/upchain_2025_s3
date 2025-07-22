import { useAccount, useWriteContract, useReadContract, usePublicClient } from 'wagmi'
import { parseEther } from 'viem'
import { useState } from 'react'
import { CONTRACT_ADDRESSES, ERC721_ABI, NFTMARKET_ABI } from '../config/contracts'

export default function ListNFTPanel() {
  const { address } = useAccount()
  const { writeContract } = useWriteContract()
  const publicClient = usePublicClient()
  const [isLoading, setIsLoading] = useState(false)

  // 上架NFT逻辑
  const handleListNFT = async (tokenId: bigint, price: string) => {
    console.log('[ListNFT] 准备上架NFT', { tokenId, price, contract: CONTRACT_ADDRESSES.NFTMarket })
    try {
      if (!publicClient) {
        console.error('[ListNFT] publicClient 未初始化')
        return
      }
      setIsLoading(true)
      // 1. 检查是否已授权
      const approved = await publicClient.readContract({
        address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
        abi: ERC721_ABI as any,
        functionName: 'getApproved',
        args: [tokenId],
      })
      console.log('[ListNFT] 当前授权地址', approved)
      if ((approved as string).toLowerCase() !== CONTRACT_ADDRESSES.NFTMarket.toLowerCase()) {
        // 2. 未授权，先发起授权
        console.log('[ListNFT] 未授权，发起approve...')
        await writeContract({
          address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
          abi: ERC721_ABI,
          functionName: 'approve',
          args: [CONTRACT_ADDRESSES.NFTMarket, tokenId],
        })
        console.log('[ListNFT] 授权成功')
      } else {
        console.log('[ListNFT] 已授权，无需重复approve')
      }
      // 3. 授权后再上架
      const parsedPrice = parseEther(price)
      console.log('[ListNFT] 调用list参数', { tokenId, parsedPrice })
      const result = await writeContract({
        address: CONTRACT_ADDRESSES.NFTMarket as `0x${string}`,
        abi: NFTMARKET_ABI,
        functionName: 'list',
        args: [tokenId, parsedPrice],
      })
      console.log('[ListNFT] 上架成功', result)
    } catch (error) {
      console.error('[ListNFT] 上架NFT失败', error)
      if (error && typeof error === 'object') {
        console.error('error details:', (error as any).details || (error as any).message)
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="bg-white p-4 rounded-lg shadow">
      <h3 className="text-lg font-medium mb-3">🆙 上架NFT</h3>
      <form
        onSubmit={e => {
          e.preventDefault();
          const form = e.target as typeof e.target & {
            tokenId: { value: string }
            price: { value: string }
          }
          handleListNFT(BigInt(form.tokenId.value), form.price.value)
        }}
        className="flex items-center gap-2"
      >
        <input name="tokenId" type="number" placeholder="Token ID" className="px-3 py-2 border rounded-lg" required />
        <input name="price" type="text" placeholder="价格（ETH）" className="px-3 py-2 border rounded-lg" required />
        <button type="submit" className="px-4 py-2 bg-blue-500 text-white rounded-lg" disabled={isLoading}>
          {isLoading ? '处理中...' : '上架'}
        </button>
      </form>
    </div>
  )
}
