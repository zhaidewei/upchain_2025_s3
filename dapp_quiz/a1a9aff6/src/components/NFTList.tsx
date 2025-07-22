import { useAccount, useWriteContract, useReadContract } from 'wagmi'
import { formatEther, parseEther } from 'viem'
import { CONTRACT_ADDRESSES, ERC20_ABI, NFTMARKET_ABI } from '../config/contracts'
import { ShoppingCart, Tag, Search } from 'lucide-react'
import { useState } from 'react'
import { ERC721_ABI } from '../config/contracts'
import { usePublicClient } from 'wagmi'

export default function NFTList() {
  const { address } = useAccount()
  const { writeContract: buyNFT } = useWriteContract()
  const { writeContract: approveToken } = useWriteContract()
  const { writeContract } = useWriteContract()
  // 移除无用的 readContract

  const publicClient = usePublicClient()

  // 由于合约没有getListings函数，我们暂时使用模拟数据来测试UI
  // 在实际项目中，通常会通过事件监听或后端API来获取上架列表
  const isLoadingListings = false
  const nftListings: any[] = [] // 暂时为空，等待真正上架NFT后再显示

  // 检查Token授权
  const { data: allowance } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: [address!, CONTRACT_ADDRESSES.NFTMarket as `0x${string}`],
    query: {
      enabled: !!address,
    },
  })

  // 检查Token余额
  const { data: balance } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  const handleApproveToken = async (amount: string) => {
    try {
      await approveToken({
        address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [CONTRACT_ADDRESSES.NFTMarket as `0x${string}`, parseEther(amount)],
      })
    } catch (error) {
      console.error('授权Token失败:', error)
    }
  }

  const handleBuyNFT = async (tokenId: bigint) => {
    try {
      await buyNFT({
        address: CONTRACT_ADDRESSES.NFTMarket as `0x${string}`,
        abi: NFTMARKET_ABI,
        functionName: 'buyNft',
        args: [tokenId],
      })
    } catch (error) {
      console.error('购买NFT失败:', error)
    }
  }

  // 新增：上架NFT的debug打印
  const handleListNFT = async (tokenId: bigint, price: string) => {
    console.log('[ListNFT] 准备上架NFT', { tokenId, price, contract: CONTRACT_ADDRESSES.NFTMarket })
    try {
      if (!publicClient) {
        console.error('[ListNFT] publicClient 未初始化')
        return
      }
      // 1. 检查是否已授权
      const approved = await publicClient.readContract({
        address: CONTRACT_ADDRESSES.ExtendedERC721 as `0x${string}`,
        abi: ERC721_ABI as any, // 确保 getApproved 可用
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
    }
  }

  const hasEnoughBalance = (price: string) => {
    if (!balance) return false
    return (balance as bigint) >= parseEther(price)
  }

  const hasEnoughAllowance = (price: string) => {
    if (!allowance) return false
    return (allowance as bigint) >= parseEther(price)
  }

  // 我们可以通过查询特定tokenId来测试listing功能
  const [testTokenId, setTestTokenId] = useState('1')

  const { data: testListing } = useReadContract({
    address: CONTRACT_ADDRESSES.NFTMarket as `0x${string}`,
    abi: NFTMARKET_ABI,
    functionName: 'listings',
    args: [BigInt(testTokenId || '0')],
    query: {
      enabled: !!testTokenId && testTokenId !== '0',
      refetchInterval: 5000,
    },
  })

    if (isLoadingListings) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">加载NFT列表中...</p>
      </div>
    )
  }

  return (
    <div>
      <h2 className="text-2xl font-semibold text-gray-900 mb-6">NFT 市场</h2>

      <div className="mb-6">
        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-lg font-medium mb-3">🔍 查询上架的NFT</h3>
          <div className="flex items-center gap-2 mb-3">
            <input
              type="number"
              value={testTokenId}
              onChange={(e) => setTestTokenId(e.target.value)}
              className="px-3 py-2 border rounded-lg"
              placeholder="输入Token ID"
            />
            <Search className="text-blue-500" size={20} />
          </div>

          {testListing && (testListing as any)[2] && (
            <div className="bg-green-50 p-3 rounded border">
              <p className="text-sm font-medium text-green-800">✅ NFT #{testTokenId} 已上架！</p>
              <p className="text-sm text-green-600">
                卖家: {((testListing as any)[0] as string).slice(0, 10)}...
              </p>
              <p className="text-sm text-green-600">
                价格: {formatEther((testListing as any)[1] as bigint)} ETH
              </p>
            </div>
          )}

          {testListing && !(testListing as any)[2] && (
            <div className="bg-gray-50 p-3 rounded border">
              <p className="text-sm text-gray-600">NFT #{testTokenId} 未上架</p>
            </div>
          )}
        </div>
      </div>

      {/* 新增：上架NFT表单 */}
      <div className="mb-6">
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
            <button type="submit" className="px-4 py-2 bg-blue-500 text-white rounded-lg">上架</button>
          </form>
        </div>
      </div>

      {testListing && (testListing as any)[2] ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-white rounded-lg shadow overflow-hidden">
            {/* NFT 图片占位符 */}
            <div className="h-48 bg-gray-200 flex items-center justify-center">
              <div className="text-gray-500 text-center">
                <Tag size={32} />
                <p className="mt-2">NFT #{testTokenId}</p>
              </div>
            </div>

            {/* NFT 信息 */}
            <div className="p-4">
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                NFT #{testTokenId}
              </h3>
              <p className="text-sm text-gray-600 mb-2">
                卖家: {((testListing as any)[0] as string).slice(0, 6)}...{((testListing as any)[0] as string).slice(-4)}
              </p>
              <p className="text-lg font-bold text-green-600 mb-4">
                {formatEther((testListing as any)[1] as bigint)} ETH
              </p>

              {/* 购买按钮 */}
              {address?.toLowerCase() === ((testListing as any)[0] as string).toLowerCase() ? (
                <button
                  disabled
                  className="w-full px-4 py-2 bg-gray-300 text-gray-500 rounded-lg cursor-not-allowed"
                >
                  这是你的NFT
                </button>
              ) : !hasEnoughBalance(formatEther((testListing as any)[1] as bigint)) ? (
                <button
                  disabled
                  className="w-full px-4 py-2 bg-gray-300 text-gray-500 rounded-lg cursor-not-allowed"
                >
                  余额不足
                </button>
              ) : !hasEnoughAllowance(formatEther((testListing as any)[1] as bigint)) ? (
                <button
                  onClick={() => handleApproveToken(formatEther((testListing as any)[1] as bigint))}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-yellow-500 hover:bg-yellow-600 text-white rounded-lg transition-colors"
                >
                  授权Token
                </button>
              ) : (
                <button
                  onClick={() => handleBuyNFT(BigInt(testTokenId))}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors"
                >
                  <ShoppingCart size={16} />
                  购买
                </button>
              )}
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center py-12">
          <div className="text-gray-400 mb-4">
            <Tag size={48} className="mx-auto" />
          </div>
          <p className="text-gray-500">暂无上架的NFT</p>
          <p className="text-sm text-gray-400 mt-2">请先上架一些NFT到市场，然后在上方搜索框中输入Token ID查看</p>
        </div>
            )}
    </div>
  )
}
