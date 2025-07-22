import { useState } from 'react'
import { useAccount } from 'wagmi'
import NFTList from './NFTList'
import TokenBalance from './TokenBalance'
import ListNFTPanel from './ListNFTPanel'

export default function NFTMarket() {
  const { isConnected } = useAccount()
  const [activeTab, setActiveTab] = useState<'marketplace' | 'list'>('marketplace')

  if (!isConnected) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-semibold text-gray-700 mb-4">
          请先连接钱包
        </h2>
        <p className="text-gray-500">
          连接您的钱包以开始使用NFT市场
        </p>
      </div>
    )
  }

  return (
    <div className="w-full px-4 md:px-8 lg:px-16 xl:px-32 2xl:px-64">
      {/* Token余额显示 */}
      <div className="mb-8">
        <TokenBalance />
      </div>

      {/* 标签导航 */}
      <div className="flex mb-8 border-b">
        <button
          onClick={() => setActiveTab('marketplace')}
          className={`px-6 py-3 font-medium border-b-2 transition-colors ${
            activeTab === 'marketplace'
              ? 'border-blue-500 text-blue-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          市场
        </button>
        <button
          onClick={() => setActiveTab('list')}
          className={`px-6 py-3 font-medium border-b-2 transition-colors ${
            activeTab === 'list'
              ? 'border-blue-500 text-blue-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          上架NFT
        </button>
      </div>

      {/* 内容区域 */}
      {activeTab === 'marketplace' ? (
        <NFTList />
      ) : (
        <div className="container mx-auto py-8">
          <ListNFTPanel />
        </div>
      )}
    </div>
  )
}
