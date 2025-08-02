import { useState } from 'react'
import { MulticallButton } from './MulticallButton'

export function DepositForm() {
  const [amount, setAmount] = useState('10')

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    // Only allow numbers and decimals
    if (/^\d*\.?\d*$/.test(value) || value === '') {
      setAmount(value)
    }
  }

  return (
    <div style={{ marginTop: '20px', padding: '20px', border: '1px solid #ccc', borderRadius: '8px' }}>
      <h3>Deposit Tokens</h3>
      <div style={{ marginBottom: '15px' }}>
        <label htmlFor="amount" style={{ display: 'block', marginBottom: '5px' }}>
          Amount to deposit:
        </label>
        <input
          id="amount"
          type="text"
          value={amount}
          onChange={handleAmountChange}
          placeholder="Enter amount"
          style={{
            padding: '8px',
            borderRadius: '4px',
            border: '1px solid #ccc',
            width: '200px'
          }}
        />
        <span style={{ marginLeft: '10px', fontSize: '14px', color: '#666' }}>
          tokens
        </span>
      </div>

      <MulticallButton amount={amount} />
    </div>
  )
}
