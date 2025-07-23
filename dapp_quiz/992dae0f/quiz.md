# [Link](https://decert.me/challenge/992dae0f-3bdf-4f03-9798-3427234fad95)

Quiz#1
编写一个脚本（可以基于 Viem.js 、Ethers.js 或其他的库来实现）来模拟一个命令行钱包，钱包包含的功能有：

生成私钥、查询余额（可人工转入金额）
构建一个 ERC20 转账的 EIP 1559 交易
用 1 生成的账号，对 ERC20 转账进行签名
发送交易到 Sepolia 网络。
提交代码仓库以及自己构造交易的浏览器交易链接。

## 分析

1. 生成一个node 后端项目。

```sh
npm init -y # 创建项目。
# 安装 TypeScript 和 ts-node：
npm install typescript ts-node @types/node --save-dev
# 新建tsconfig.json：
npx tsc --init
# 在 package.json 里加 "type": "module"（如用 ES 模块）。
# 编写入口文件（如 index.ts），用 #!/usr/bin/env ts-node 作为第一行可做 CLI。
# 用 chmod +x index.ts 赋予执行权限。
chmod +x index.ts
# 通过 ./index.ts 或 npx ts-node index.ts 运行。
npx ts-node --loader ts-node/esm index.ts
# 理由：这样可以用 TypeScript 编写和运行 Node.js CLI 工具，开发体验好，类型安全。
```

1.5 添加CLI输入参数解析。


2. 了解生成私钥的步骤，以及所需函数。
2.1 文档描述
[以太坊官方网页](https://ethereum.org/en/developers/docs/accounts/)
[viem ](https://learnblockchain.cn/docs/viem/docs/accounts/local/privateKeyToAccount)

1. 调用viem的库函数，生成私钥

```ts
import { generatePrivateKey } from 'viem/accounts'
import { privateKeyToAccount } from 'viem/accounts'

const privateKey = generatePrivateKey()
console.log(privateKey)

const account = privateKeyToAccount(privateKey)
console.log(account)
```

2. 实现查询余额的功能。

需要建立app和网络的关联，然后寻找viem里查询余额的方法。

添加三个链： 1 anvil 2 sepolia 3 ether main net

读取余额不需要签名，所以使用public client即可

```ts
import { anvil, baseSepolia, mainnet } from 'viem/chains'
import { Chain, createPublicClient, http } from 'viem'


function getClient(chain: Chain) {
    const client = createPublicClient({
        chain,
        transport: http()
    })
    return client
}

const anvilClient = getClient(anvil)
const baseSepoliaClient = getClient(baseSepolia)
const mainnetClient = getClient(mainnet)
```

3. 构建一个 ERC20 转账的 EIP 1559 交易。

首先，理解什么是EIP 1559交易。这个就是目前以太坊上（2021年开始）的交易结构

[官方文档](https://eips.ethereum.org/EIPS/eip-1559)

```ts
interface Transaction1559 {
  type: "0x2"                 // 表示这是 EIP-1559 类型的交易
  nonce: Hex
  to: Address
  value: Hex
  data: Hex
  gas: Hex                    // Gas limit
  maxPriorityFeePerGas: Hex   // 小费（tip），付给打包者
  maxFeePerGas: Hex           // 用户愿意支付的 gas 最高单价
  accessList?: AccessList     // EIP-2930 引入的可选字段
  chainId: number
}
```

其次，需要解决构建交易数据，签名，发送这三步。
在viem里找相关的函数

[viem](https://learnblockchain.cn/docs/viem/docs/clients/wallet#%E6%9C%AC%E5%9C%B0%E8%B4%A6%E6%88%B7%E7%A7%81%E9%92%A5%E5%8A%A9%E8%AE%B0%E8%AF%8D%E7%AD%89)

创建一个wallet account，sendTransaction 的时候把account给他

```ts
import { createWalletClient, http } from 'viem'
import { mainnet } from 'viem/chains'

const client = createWalletClient({
  chain: mainnet,
  transport: http()
})


import { createWalletClient, http } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { mainnet } from 'viem/chains'

const client = createWalletClient({
  chain: mainnet,
  transport: http()
})

const account = privateKeyToAccount('0x...')

import { createWalletClient, http, parseEther } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { mainnet } from 'viem/chains'

const client = createWalletClient({
  account: account,
  chain: mainnet,
  transport: http()，
})


const hash = await client.sendTransaction({
  to: '0xa5cc3c03994DB5b0d9A5eEdD10CabaB0813678AC',
  value: parseEther('0.001')
})
```

3. 准备ERC20合约

```sh
export ROOT_PATH=/Users/zhaidewei/upchain_2025_s3/foundry_quiz/08973815/src
forge create --rpc-url http://127.0.0.1:8545 --account anvil-tester --password '' $ROOT_PATH/ExtendedERC20WithData.sol:ExtendedERC20WithData --broadcast

#Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
#Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
#Transaction hash: 0x6327abde4d3bb050ffba597a1d398c756f6b16e24a8a5ec94b1a9fa2566a288a
```

测试目标是，
对ERC20合约转账

4. 需要发送交易到sepolia网络。

1 这意味着，erc20 合约需要先部署在sepolia上，使用forge create命令 + 本地keystore
2 继续使用本地keystroe，呼叫这个合约的转账方法，给另一个地址在这个erc20合约里转账
3 查询对方地址的余额

4.1

```sh
export ROOT_PATH=/Users/zhaidewei/upchain_2025_s3/foundry_quiz/08973815/src
forge create --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" --account myMetaMaskAcc --password '' $ROOT_PATH/ExtendedERC20WithData.sol:ExtendedERC20WithData --broadcast

#Deployer: 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
#Deployed to: 0x264C4E0c7AD58d979e8648428791FbE06edAA23F
#Transaction hash: 0xf5244fca7c9901237f166ed83f9864887144d0205e81ecd4ef3623783b48d40b

```sh
# cast balance 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2 --rpc-url https://sepolia.base.org
cast balance 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2 --rpc-url https://ethereum-sepolia-rpc.publicnode.com

cast wallet decrypt-keystore --keystore-dir ~/.foundry/keystores/ myMetaMaskAcc
```


4.2 使用脚本在sepolia的合约里查询余额
balanceOf(address _owner) public view returns (uint256 balance)
```sh
export ERC20=0x264C4E0c7AD58d979e8648428791FbE06edAA23F
export OWNER=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2

cast call $ERC20 "balanceOf(address)(uint256)" $OWNER --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

```

npx ts-node index.ts -c sepolia
