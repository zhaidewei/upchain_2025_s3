import { useAccount, useReadContract } from 'wagmi'
import { CONTRACTS, TOKEN_BANK_ABI, ERC20_ABI } from '../config/contracts'
import { formatEther } from 'viem'
import './BalanceDisplay.css'

function BalanceDisplay() {
  const { address } = useAccount()

  // Read token balance
  const { data: tokenBalance, isLoading: tokenLoading } = useReadContract({
    address: CONTRACTS.TOKEN as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read bank balance
  const { data: bankBalance, isLoading: bankLoading } = useReadContract({
    address: CONTRACTS.BANK as `0x${string}`,
    abi: TOKEN_BANK_ABI,
    functionName: 'getUserBalance',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read contract balance
  const { data: contractBalance, isLoading: contractLoading } = useReadContract({
    address: CONTRACTS.BANK as `0x${string}`,
    abi: TOKEN_BANK_ABI,
    functionName: 'getContractBalance',
    query: {
      enabled: !!address,
    },
  })

  if (!address) {
    return <div>Please connect your wallet</div>
  }

  if (tokenLoading || bankLoading || contractLoading) {
    return <div>Loading balances...</div>
  }

  return (
    <div className="balance-display">
      <h2>Account Balances</h2>
      <div className="balance-grid">
        <div className="balance-item">
          <h3>Token Balance</h3>
          <p className="balance-value">
            {tokenBalance ? formatEther(tokenBalance) : '0'} TT
          </p>
        </div>
        <div className="balance-item">
          <h3>Bank Balance</h3>
          <p className="balance-value">
            {bankBalance ? formatEther(bankBalance) : '0'} TT
          </p>
        </div>
        <div className="balance-item">
          <h3>Contract Balance</h3>
          <p className="balance-value">
            {contractBalance ? formatEther(contractBalance) : '0'} TT
          </p>
        </div>
      </div>
      <div className="address-info">
        <p><strong>Your Address:</strong> {address}</p>
        <p><strong>Token Contract:</strong> {CONTRACTS.TOKEN}</p>
        <p><strong>Bank Contract:</strong> {CONTRACTS.BANK}</p>
        <p><strong>Permit2 Contract:</strong> {CONTRACTS.PERMIT2}</p>
      </div>
    </div>
  )
}

export default BalanceDisplay
