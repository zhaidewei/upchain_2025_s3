# Motivation

Sometimes we want to know a transaction before it gets in block.

this can be done by using subscriptions against the rpc server.

# Case

1. Start Anvil
2. run the subscription script (ts with viem)
3. Run a serious of transactions.
4. expect to see the messages.


```sh
tsx watch_node.ts                                                                           ✔  11831  21:27:43
🔍 Starting to watch pending transactions on Anvil network...
📡 Connected to: http://localhost:8545
⏳ Waiting for pending transactions...

💡 Press Ctrl+C to stop watching
🚀 Ready to monitor pending transactions!


📦 Received 1 pending transaction hash(es):

--- Transaction 1 ---
Hash: 0x0bcc695433b7ecbfb66ad79d9bdc6c170bba91ed6136efd1a068fc772fe76d9b
Status: Pending
From: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
To: Contract Creation
Value: 0 wei
Gas Price: 1000000001 wei
Max Fee Per Gas: 2000000001 wei
Max Priority Fee Per Gas: 1 wei
Gas Limit: 947912
Nonce: 0
Input Length: 12026 bytes
Input Preview: 0x608060405234801561000f575f5ffd5b506040516116bc3803806116bc8339818101604052810190610031919061046356...
Chain ID: 31337
Type: eip1559

📦 Received 1 pending transaction hash(es):

--- Transaction 1 ---
Hash: 0xdc7aee71040890bb9e725a1dcd2bb4de5328bc0cefc74aebc1dfa7a106750e12
Status: Pending
From: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
To: 0x5fbdb2315678afecb367f032d93f642f64180aa3
Value: 0 wei
Gas Price: 882899268 wei
Max Fee Per Gas: 2000000001 wei
Max Priority Fee Per Gas: 1 wei
Gas Limit: 52189
Nonce: 1
Input Length: 138 bytes
Input Preview: 0xa9059cbb00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000000...
Chain ID: 31337
Type: eip1559

📦 Received 1 pending transaction hash(es):

--- Transaction 1 ---
Hash: 0x96c5d2ab63e324411c079421b609dc0e1708483969962ffc2a8de85bff291a3d
Status: Pending
From: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
To: 0x5fbdb2315678afecb367f032d93f642f64180aa3
Value: 0 wei
Gas Price: 772920840 wei
Max Fee Per Gas: 1765798535 wei
Max Priority Fee Per Gas: 1 wei
Gas Limit: 52177
Nonce: 2
Input Length: 138 bytes
Input Preview: 0xa9059cbb0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc00000000000000000000000000...
Chain ID: 31337
Type: eip1559

📦 Received 1 pending transaction hash(es):

--- Transaction 1 ---
Hash: 0xfe70955382b2802118525c2c06a8b6fab297547e0f376ff15be616d81a1b8915
Status: Pending
From: 0x70997970c51812dc3a010c7d01b50e0d17dc79c8
To: 0x5fbdb2315678afecb367f032d93f642f64180aa3
Value: 0 wei
Gas Price: 676641808 wei
Max Fee Per Gas: 1545841679 wei
Max Priority Fee Per Gas: 1 wei
Gas Limit: 35077
Nonce: 0
Input Length: 138 bytes
Input Preview: 0xa9059cbb0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc00000000000000000000000000...
Chain ID: 31337
Type: eip1559

📦 Received 1 pending transaction hash(es):

--- Transaction 1 ---
Hash: 0x59ff0d33333200adc2308ce2a482e0e17ca0d07701f79cf31bcc1804db41daee
Status: Pending
From: 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
To: 0x5fbdb2315678afecb367f032d93f642f64180aa3
Value: 0 wei
Gas Price: 592259371 wei
Max Fee Per Gas: 1353283615 wei
Max Priority Fee Per Gas: 1 wei
Gas Limit: 35089
Nonce: 0
Input Length: 138 bytes
Input Preview: 0xa9059cbb00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000000...
Chain ID: 31337
Type: eip1559
^C
🛑 Stopping pending transaction watcher...
```
