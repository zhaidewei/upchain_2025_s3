
safe wallet
0xe6f353CC86f88BA64Be678C2c1A618d62b96732E

signer
0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2 dewei 1
0xf81C65392B177232f17e4C6954B4321a3046e0D6 dewei 2

0xE991bC71A371055B3f02aa79b79E4b714A3D04c0 car


1 在我的ERC20上给多签钱包转erc20

```sh
SAFE_WALLET=0xe6f353CC86f88BA64Be678C2c1A618d62b96732E
ERC20=0x264C4E0c7AD58d979e8648428791FbE06edAA23F
OWNER=0x4DaA04d0B4316eCC9191aE07102eC08Bded637a2
RPC=https://1rpc.io/sepolia # "https://ethereum-sepolia-rpc.publicnode.com"

cast call $ERC20 "balanceOf(address)(uint256)" $OWNER --rpc-url $RPC

# 9999999999999999000000000 [9.999e24]
# 9999999999999999000000000

cast call $ERC20 "balanceOf(address)(uint256)" $SAFE_WALLET --rpc-url $RPC

cast call $ERC20 "transfer(address,uint256)(bool)" $SAFE_WALLET 1000000 --account myMetaMaskAcc --rpc-url $RPC --verbose --json | jq
# 或者加上 --verbose 参数查看更多细节
# cast send $ERC20 "transfer(address,uint256)(bool)" $SAFE_WALLET 1000000 --account myMetaMaskAcc --rpc-url $RPC --verbose

cast call $ERC20 "balanceOf(address)(uint256)" $SAFE_WALLET --rpc-url  $RPC

```


Safe钱包 0xe6f353CC86f88BA64Be678C2c1A618d62b96732E
ERC20地址 https://sepolia.etherscan.io/address/0xAd36abB13d0C25E809FAe580662544d87b826D98

往多签中存入自己创建的任意 ERC20 Token。
https://sepolia.etherscan.io/tx/0x99150bf9bf60ab24fffe537556e0d4ac19aa709546a9c53a0c2bd8765317c55c
钱包获得12CTK

从多签中转出一定数量的 ERC20 Token。


把 Bank 合约的管理员设置为多签。
3个账户 2/3 多签

请贴 Safe 的钱包链接。
https://sepolia.etherscan.io/address/0xe6f353CC86f88BA64Be678C2c1A618d62b96732E

5. 从多签中发起， 对 Bank 的 withdraw 的调用
经过2个账户的签名，执行
https://sepolia.etherscan.io/tx/0xe18232c7140885d0fb9870c034400967e0ccb56e4c45dc3ca84e8f15f1cd1ab1
