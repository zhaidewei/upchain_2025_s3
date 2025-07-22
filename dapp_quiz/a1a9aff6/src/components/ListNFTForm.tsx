import { useState } from 'react'
import { useAccount, useWriteContract, useReadContract } from 'wagmi'
import { parseEther } from 'viem'
import { CONTRACT_ADDRESSES, ERC721_ABI, NFTMARKET_ABI } from '../config/contracts'
import { Plus, Upload } from 'lucide-react'

export default function ListNFTForm() {
  const { address } = useAccount()
  const [tokenId, setTokenId] = useState('')
  const [price, setPrice] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const { writeContract: approveNFT } = useWriteContract()
  const { writeContract: listNFT } = useWriteContract()

  // 检查NFT是否属于当前用户
  const { data: nftOwner } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
    abi: ERC721_ABI,
    functionName: 'ownerOf',
    args: [BigInt(tokenId || '0')],
    query: {
      enabled: !!tokenId && tokenId !== '0',
    },
  })

  // 检查是否已授权
  const { data: isApprovedForAll } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
    abi: ERC721_ABI,
    functionName: 'isApprovedForAll',
    args: [address!, CONTRACT_ADDRESSES.NFTMarket as `0x${string}`],
    query: {
      enabled: !!address,
    },
  })

  const handleMintNFT = async () => {
    if (!address || !tokenId) return

    setIsLoading(true)
    try {
      await approveNFT({
        address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
        abi: ERC721_ABI,
        functionName: 'mint',
        args: [address, BigInt(tokenId)],
      })
    } catch (error) {
      console.error('铸造NFT失败:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleApprove = async () => {
    if (!address) return

    setIsLoading(true)
    try {
      await approveNFT({
        address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
        abi: ERC721_ABI,
        functionName: 'setApprovalForAll',
        args: [CONTRACT_ADDRESSES.NFTMarket as `0x${string}`, true],
      })
    } catch (error) {
      console.error('授权失败:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleListNFT = async () => {
    if (!tokenId || !price) return

    setIsLoading(true)
    try {
      await listNFT({
        address: CONTRACT_ADDRESSES.NFTMarket as `0x${string}`,
        abi: NFTMARKET_ABI,
        functionName: 'listNFT',
        args: [
          CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
          BigInt(tokenId),
          parseEther(price)
        ],
      })
      // 清空表单
      setTokenId('')
      setPrice('')
    } catch (error) {
      console.error('上架NFT失败:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const isOwner = nftOwner?.toLowerCase() === address?.toLowerCase()

  return (
    <div className="max-w-md mx-auto">
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">上架 NFT</h2>

        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Token ID
            </label>
            <input
              type="number"
              value={tokenId}
              onChange={(e) => setTokenId(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="输入 NFT Token ID"
            />
            {tokenId && nftOwner && !isOwner && (
              <p className="text-red-500 text-sm mt-1">你不是这个 NFT 的拥有者</p>
            )}
          </div>

          {tokenId && !nftOwner && (
            <button
              onClick={handleMintNFT}
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-green-500 hover:bg-green-600 disabled:bg-gray-400 text-white rounded-lg transition-colors"
            >
              <Plus size={16} />
              铸造 NFT
            </button>
          )}

          {isOwner && !isApprovedForAll && (
            <button
              onClick={handleApprove}
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-yellow-500 hover:bg-yellow-600 disabled:bg-gray-400 text-white rounded-lg transition-colors"
            >
              <Upload size={16} />
              授权市场合约
            </button>
          )}

          {isOwner && isApprovedForAll && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  价格 (ETH)
                </label>
                <input
                  type="number"
                  step="0.001"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="输入价格 (ETH)"
                />
              </div>

              <button
                onClick={handleListNFT}
                disabled={isLoading || !tokenId || !price}
                className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white rounded-lg transition-colors"
              >
                <Upload size={16} />
                {isLoading ? '处理中...' : '上架 NFT'}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
