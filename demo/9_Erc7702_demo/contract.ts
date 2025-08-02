export const abi = [
    {
        "type": "function",
        "name": "initialize",
        "inputs": [],
        "outputs": [],
        "stateMutability": "payable"
      },
      {
        "type": "function",
        "name": "ping",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
      }
  ] as const
// forge create $PWD/Delegation.sol:Delegation --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
export const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
