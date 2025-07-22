import { useAccount, useReadContract } from 'wagmi'
import { CONTRACT_ADDRESSES, ERC20_ABI } from '../config/contracts'
import { formatEther } from 'viem'
import { Copy, ExternalLink, Search } from 'lucide-react'
import { useState } from 'react'

export default function TokenBalance() {
  const { address, chain } = useAccount()
  const [testAddress, setTestAddress] = useState('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266')

  const { data: balance, isLoading, error: balanceError } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  const { data: tokenName, error: nameError } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'name',
  })

  const { data: tokenSymbol } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'symbol',
  })

  const { data: totalSupply } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'totalSupply',
  })

  const { data: decimals } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'decimals',
  })

  // 测试查询特定地址的余额
  const { data: testBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.ExtendedERC20WithData as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [testAddress as `0x${string}`],
    query: {
      enabled: !!testAddress && testAddress.length === 42,
    },
  })

  // Debug信息
  console.log('当前连接的地址:', address)
  console.log('当前网络:', chain?.id)
  console.log('ERC20合约地址:', CONTRACT_ADDRESSES.ExtendedERC20WithData)
  console.log('余额查询结果:', balance)
  console.log('余额查询错误:', balanceError)
  console.log('Token名称:', tokenName)
  console.log('Token名称错误:', nameError)

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    // 这里可以添加一个toast通知
  }

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Token余额信息 */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Token 余额</h3>
        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-gray-600">Token 名称:</span>
            <span className="font-medium">{tokenName as string || 'Loading...'}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Token 符号:</span>
            <span className="font-medium">{tokenSymbol as string || 'Loading...'}</span>
          </div>
                    <div className="flex justify-between">
            <span className="text-gray-600">余额:</span>
            <span className="font-medium text-green-600">
              {isLoading
                ? 'Loading...'
                : balance
                  ? `${formatEther(balance as bigint)} ${tokenSymbol as string || 'TOKEN'}`
                  : '0 TOKEN'
              }
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">总供应量:</span>
            <span className="font-medium">
              {totalSupply
                ? `${formatEther(totalSupply as bigint)} ${tokenSymbol as string || 'TOKEN'}`
                : 'Loading...'
              }
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">精度:</span>
            <span className="font-medium">{decimals?.toString() || 'Loading...'}</span>
          </div>
        </div>
      </div>

      {/* 合约地址信息 */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">合约地址</h3>
        <div className="space-y-3">
          <div>
            <label className="text-sm text-gray-600 block mb-1">ERC20 Token 合约:</label>
            <div className="flex items-center gap-2">
              <span className="font-mono text-sm bg-gray-100 text-gray-800 px-2 py-1 rounded border">
                {formatAddress(CONTRACT_ADDRESSES.ExtendedERC20WithData)}
              </span>
              <button
                onClick={() => copyToClipboard(CONTRACT_ADDRESSES.ExtendedERC20WithData)}
                className="p-1 hover:bg-gray-100 rounded text-gray-600 hover:text-gray-800"
                title="复制地址"
              >
                <Copy size={14} />
              </button>
            </div>
          </div>

          <div>
            <label className="text-sm text-gray-600 block mb-1">ERC721 NFT 合约:</label>
            <div className="flex items-center gap-2">
              <span className="font-mono text-sm bg-gray-100 text-gray-800 px-2 py-1 rounded border">
                {formatAddress(CONTRACT_ADDRESSES.ExtendedERC721)}
              </span>
              <button
                onClick={() => copyToClipboard(CONTRACT_ADDRESSES.ExtendedERC721)}
                className="p-1 hover:bg-gray-100 rounded text-gray-600 hover:text-gray-800"
                title="复制地址"
              >
                <Copy size={14} />
              </button>
            </div>
          </div>

          <div>
            <label className="text-sm text-gray-600 block mb-1">NFT Market 合约:</label>
            <div className="flex items-center gap-2">
              <span className="font-mono text-sm bg-gray-100 text-gray-800 px-2 py-1 rounded border">
                {formatAddress(CONTRACT_ADDRESSES.NFTMarket)}
              </span>
              <button
                onClick={() => copyToClipboard(CONTRACT_ADDRESSES.NFTMarket)}
                className="p-1 hover:bg-gray-100 rounded text-gray-600 hover:text-gray-800"
                title="复制地址"
              >
                <Copy size={14} />
              </button>
            </div>
          </div>

          <div className="pt-2 border-t">
            <div className="text-xs text-gray-500">
              <div className="flex items-center gap-1">
                <ExternalLink size={12} />
                <span>Chain ID: 31337 (Anvil Local)</span>
              </div>
              <div className="mt-1">RPC: http://127.0.0.1:8545</div>
              <div className="mt-2 p-2 bg-blue-50 rounded text-blue-700">
                <p className="font-medium text-xs">💡 切换账号提示：</p>
                <p className="text-xs">1. 在MetaMask中选择不同账号</p>
                <p className="text-xs">2. 点击"断开连接"重新连接</p>
              </div>

              {/* Debug信息 */}
              <div className="mt-2 p-2 bg-yellow-50 rounded text-yellow-700">
                <p className="font-medium text-xs">🔍 Debug信息：</p>
                <p className="text-xs">当前地址: {address?.slice(0, 10)}...{address?.slice(-6)}</p>
                <p className="text-xs">当前网络: Chain ID {chain?.id} {chain?.id !== 31337 && '⚠️ 请切换到Anvil(31337)'}</p>
                <p className="text-xs">ERC20地址: {CONTRACT_ADDRESSES.ExtendedERC20WithData.slice(0, 10)}...</p>
                                 {balanceError && <p className="text-xs text-red-600">余额查询错误: {balanceError.message}</p>}
                 {nameError && <p className="text-xs text-red-600">名称查询错误: {nameError.message}</p>}
               </div>

               {/* 手动测试余额查询 */}
               <div className="mt-2 p-2 bg-green-50 rounded">
                 <p className="font-medium text-xs text-green-700 mb-2">🔧 余额测试工具：</p>
                 <div className="flex items-center gap-1 mb-1">
                   <input
                     type="text"
                     value={testAddress}
                     onChange={(e) => setTestAddress(e.target.value)}
                     className="text-xs px-1 py-1 border rounded flex-1 font-mono"
                     placeholder="输入要查询的地址..."
                   />
                   <Search size={12} className="text-green-600" />
                 </div>
                 {testBalance ? (
                   <p className="text-xs text-green-600">
                     余额: {formatEther(testBalance as bigint)} {tokenSymbol as string || 'TOKEN'}
                   </p>
                 ) : null}
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
