# [quiz](https://decert.me/challenge/072fccb4-a976-4cf9-933c-c4ef14e0f6eb)

先实现一个 Bank 合约， 用户可以通过 deposit() 存款， 然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务， 自动化任务实现：当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。

请贴出你的代码 github 链接以及在第三方的执行工具中的执行链接。

## 分析

1. 实现一个bank合约
合约里有存款，
mapping（）balances[address] -> uint256
uint 256 totalBalance
owner address
threadshold constant

deposit方法-用户给自己的账户里存款，使用value作为金额

withdraw方法-用户可以提取自己的存款

send方法-只有owner可以做，owner提取金额到owner的address里

实现接口
interface AutomationCompatibleInterface {
function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
function performUpkeep(bytes calldata performData) external;
}

2 把合约部署在arbitrum-sepolia上
在chainlink里定义方法
`forge create src/QuizBank.sol:QuizBank --rpc-url arbitrum-sepolia --account myMetaMaskAcc --password '' --broadcast`

orge create src/QuizBank.sol:QuizBank --rpc-url arbitrum-sepolia --account myMetaMaskAcc --password '' --broadcast
[⠊] Compiling...
No files changed, compilation skipped
Deployer: 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
Deployed to: 0xdcf8D8E7d7e5b82291501D8F7a4F5bB1D0923B6B
Transaction hash: 0x4a51f0296ce1cb26a9ebd0d7a7b98a037366690ded5c7afec94de7dd0398b77c

3 在chainlist上注册upkeep
这里我提供了ABI

4 给自己转账

```sh
cast send 0xdcf8D8E7d7e5b82291501D8F7a4F5bB1D0923B6B "deposit()" --value 20000000000000000 --account myMetaMaskAcc --password '' --rpc-url arbitrum-sepolia
```

```log
cast send 0xdcf8D8E7d7e5b82291501D8F7a4F5bB1D0923B6B "deposit()" --value 20000000000000000 --account myMetaMaskAcc --password '' --rpc-url arbitrum-sepolia
Warning: Found unknown config section in foundry.toml: [private_keys]
This notation for profiles has been deprecated and may result in the profile not being registered in future versions.
Please use [profile.private_keys] instead or run `forge config --fix`.

blockHash            0x75042b3e026d73d10e7ac7a69b9c87e0790f459da8f2a2a2fd7743290912543e
blockNumber          181209592
contractAddress
cumulativeGasUsed    843023
effectiveGasPrice    100000000
from                 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
gasUsed              45215
logs                 [{"address":"0xdcf8d8e7d7e5b82291501d8f7a4f5bb1d0923b6b","topics":["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c","0x0000000000000000000000004daa04d0b4316ecc9191ae07102ec08bded637a2"],"data":"0x00000000000000000000000000000000000000000000000000470de4df820000","blockHash":"0x75042b3e026d73d10e7ac7a69b9c87e0790f459da8f2a2a2fd7743290912543e","blockNumber":"0xacd09f8","transactionHash":"0xbab3b38dc76508ed051aa5a841d8143c9752135da671f7d6b3c41e18fe804320","transactionIndex":"0x6","logIndex":"0x12","removed":false}]
logsBloom            0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000200000000000000001000000000000000000000000000000000000000000000000000000000000000000000000001000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000400000000000000000
root
status               1 (success)
transactionHash      0xbab3b38dc76508ed051aa5a841d8143c9752135da671f7d6b3c41e18fe804320
transactionIndex     6
type                 2
blobGasPrice
blobGasUsed
to                   0xdcf8D8E7d7e5b82291501D8F7a4F5bB1D0923B6B
gasUsedForL1         0
l1BlockNumber        8924855
timeboosted          false
```

# 查询余额

```sh
cast call 0xdcf8D8E7d7e5b82291501D8F7a4F5bB1D0923B6B "balances(address)(uint256)" "0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2" --rpc-url arbitrum-sepolia
# 20000000000000000 [2e16]
```

## 发现了错误，重新修改后部署

Deployer: 0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
Deployed to: 0x9D2203eA993C5Ad111699856c4840102Cec924d2
Transaction hash: 0xa68cd59138a3d8ccaecf4eff068ce4261a7595478e520eca61772562e128fa46


```sh
cast send 0x9D2203eA993C5Ad111699856c4840102Cec924d2 "deposit()" --value 11000000000000000 --account myMetaMaskAcc --password '' --rpc-url arbitrum-sepolia
```

https://sepolia.arbiscan.io/tx/0xbee12ad1a7f2049034526120584a3c29af2de3c6298aa4cc61206903fb8c4964

```
cast balance 0x9D2203eA993C5Ad111699856c4840102Cec924d2 --rpc-url arbitrum-sepolia
0
```
