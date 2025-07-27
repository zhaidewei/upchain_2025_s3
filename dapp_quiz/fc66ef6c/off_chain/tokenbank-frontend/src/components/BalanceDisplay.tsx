import { useAccount, useReadContract } from 'wagmi'
import { CONTRACTS, ABIS } from '../config/contracts'
import { formatEther, parseEther } from 'viem'
import './BalanceDisplay.css'

function BalanceDisplay() {
  const { address } = useAccount()

  // Read token balance
  const { data: tokenBalance, isLoading: tokenLoading } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'balanceOf',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read bank balance
  const { data: bankBalance, isLoading: bankLoading } = useReadContract({
    address: CONTRACTS.BANK,
    abi: ABIS.BANK,
    functionName: 'getUserBalance',
    args: [address!],
    query: {
      enabled: !!address,
    },
  })

  // Read token allowance for bank
  const { data: allowance, isLoading: allowanceLoading } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'allowance',
    args: [address!, CONTRACTS.BANK],
    query: {
      enabled: !!address,
    },
  })

  if (!address) {
    return <div>Please connect your wallet</div>
  }



  return (
    <div className="balance-display">
      <h3>Account Balances</h3>
      <div className="balance-grid">
        <div className="balance-card">
          <h4>Token Balance</h4>
          {tokenLoading ? (
            <p>Loading...</p>
          ) : (
            <p className="balance-amount">
              {tokenBalance ? formatEther(tokenBalance as bigint) : '0'} DToken
            </p>
          )}
        </div>

        <div className="balance-card">
          <h4>Bank Balance</h4>
          {bankLoading ? (
            <p>Loading...</p>
          ) : (
            <p className="balance-amount">
              {bankBalance ? formatEther(bankBalance as bigint) : '0'} DToken
            </p>
          )}
        </div>

        <div className="balance-card">
          <h4>Bank Allowance</h4>
          {allowanceLoading ? (
            <p>Loading...</p>
          ) : (
            <p className="balance-amount">
              {allowance ? formatEther(allowance as bigint) : '0'} DToken
            </p>
          )}
        </div>
      </div>

      <div className="address-info">
        <p><strong>Your Address:</strong> {address}</p>
        <p><strong>Token Contract:</strong> {CONTRACTS.TOKEN}</p>
        <p><strong>Bank Contract:</strong> {CONTRACTS.BANK}</p>
      </div>


    </div>
  )
}

export default BalanceDisplay
