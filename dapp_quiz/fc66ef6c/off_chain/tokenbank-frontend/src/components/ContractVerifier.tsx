import { useReadContract } from 'wagmi'
import { CONTRACTS, ABIS } from '../config/contracts'
import { useState, useEffect } from 'react'

function ContractVerifier() {
  const [verificationResults, setVerificationResults] = useState<{
    token: { deployed: boolean; error?: string };
    bank: { deployed: boolean; error?: string };
  }>({
    token: { deployed: false },
    bank: { deployed: false }
  })

  // Try to read basic contract info
  const { data: tokenName, error: tokenError } = useReadContract({
    address: CONTRACTS.TOKEN,
    abi: ABIS.TOKEN,
    functionName: 'name',
    query: {
      enabled: true,
    },
  })

  const { data: bankBalance, error: bankError } = useReadContract({
    address: CONTRACTS.BANK,
    abi: ABIS.BANK,
    functionName: 'getUserBalance',
    args: ['0x0000000000000000000000000000000000000000'], // Zero address
    query: {
      enabled: true,
    },
  })

  useEffect(() => {
    setVerificationResults({
      token: {
        deployed: !tokenError && tokenName !== undefined,
        error: tokenError?.message
      },
      bank: {
        deployed: !bankError,
        error: bankError?.message
      }
    })
  }, [tokenError, bankError, tokenName, bankBalance])

  const allContractsDeployed = verificationResults.token.deployed && verificationResults.bank.deployed

  if (allContractsDeployed) {
    return null // Don't show if all contracts are deployed
  }

  return (
    <div style={{
      backgroundColor: '#f8d7da',
      border: '1px solid #f5c6cb',
      padding: '15px',
      margin: '10px 0',
      borderRadius: '5px'
    }}>
      <h4>⚠️ Contract Deployment Issues</h4>
      <p>Some contracts may not be properly deployed or accessible.</p>

      <div style={{ marginTop: '10px' }}>
        <div style={{ marginBottom: '10px' }}>
          <strong>Token Contract ({CONTRACTS.TOKEN}):</strong>
          {verificationResults.token.deployed ? (
            <span style={{ color: 'green', marginLeft: '10px' }}>✅ Deployed</span>
          ) : (
            <span style={{ color: 'red', marginLeft: '10px' }}>
              ❌ Not deployed or inaccessible
              {verificationResults.token.error && (
                <div style={{ fontSize: '12px', marginTop: '5px' }}>
                  Error: {verificationResults.token.error}
                </div>
              )}
            </span>
          )}
        </div>

        <div style={{ marginBottom: '10px' }}>
          <strong>Bank Contract ({CONTRACTS.BANK}):</strong>
          {verificationResults.bank.deployed ? (
            <span style={{ color: 'green', marginLeft: '10px' }}>✅ Deployed</span>
          ) : (
            <span style={{ color: 'red', marginLeft: '10px' }}>
              ❌ Not deployed or inaccessible
              {verificationResults.bank.error && (
                <div style={{ fontSize: '12px', marginTop: '5px' }}>
                  Error: {verificationResults.bank.error}
                </div>
              )}
            </span>
          )}
        </div>
      </div>

      <div style={{
        marginTop: '15px',
        backgroundColor: '#f8f9fa',
        padding: '10px',
        borderRadius: '4px',
        fontSize: '12px'
      }}>
        <h5>Troubleshooting Steps:</h5>
        <ol style={{ margin: '5px 0', paddingLeft: '20px' }}>
          <li>Make sure your Anvil node is running: <code>anvil</code></li>
          <li>Deploy contracts using Foundry: <code>forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast</code></li>
          <li>Update contract addresses in <code>src/config/contracts.ts</code> if needed</li>
          <li>Check that the contract ABIs match the deployed contracts</li>
          <li>Verify the deployment was successful by checking the deployment logs</li>
        </ol>
      </div>
    </div>
  )
}

export default ContractVerifier
