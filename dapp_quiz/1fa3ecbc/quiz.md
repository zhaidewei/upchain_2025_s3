# [问题描述](https://decert.me/challenge/1fa3ecbc-a3cd-43ae-908e-661aac97bdc0)

在原来的 TokenBank 添加一个方法 depositWithPermit2()， 这个方式使用 permit2 进行签名授权转账来进行存款。
在本地环境需要大家先部署 Permit2 合约

修改 Token 存款前端 让用户可以在前端通过 permit2 的签名存款。

# 分析

* 主体来自于[第一题](https://github.com/zhaidewei/upchain_2025_s3/tree/main/dapp_quiz/fc66ef6c)
* 只需要保留ErC20 和tokenbank 这两块就够了
* 需要部署Permit2合约到本地
* Permit2合约原理是你在erc20里approve all 到 p2，这样需要转账的时候，p2就可以转走你的钱。
那安全性怎么保证？P2 收到转账请求的时候，会检查签名是不是来自于你。
相当于把permit方法从erc2612（rec20）合约里拿到外面了。
* 这个题和[第一题](https://github.com/zhaidewei/upchain_2025_s3/tree/main/dapp_quiz/fc66ef6c)的区别就在于，第一题tokenbank用erc20的permi方法，这里用permit2的方法。
eip712 的定义从erc20转移到了permit2了。
* 也需要修改前端。

# 分解

Onchain和后端部分
## 1 ✅ onchain部分从第一题里copy需要的代码。erc20，token bank

## 2 ✅ 本地clone permit2合约。~~使用fork anvil~~

### 2.1 使用一个主网的fork测试。

可以，但是涉及很多调试问题。不推荐
`anvil --fork-url https://mainnet.infura.io/v3/$infura_key --state ./state-db`

注意，fork是按需下载的，所以需要对permit2进行一次调用

`cast call 0x000000000022D473030F116dDEE9F6B43aC78BA3 "DOMAIN_SEPARATOR()" --rpc-url http://127.0.0.1:8545`

```sh
Wallet
==================
Mnemonic:          test test test test test test test test test test test junk
Derivation path:   m/44'/60'/0'/0/


Fork
==================
Endpoint:       https://mainnet.infura.io/v3/<my api key>
Block number:   23021117
Block hash:     0xdd1160ad8a775e81151dd1e25b0ccab1b80c2fab0c66bc5dc222c8fe6ad1e29a
Chain ID:       1
...

0
```

### 2.2 clone到本地然后执行

```sh
# 在lib路径下
git clone https://github.com/Uniswap/permit2.git
cd permit2
forge install
```
注意，forge.toml 里需要配置正确的remapping，不然就会有build问题

```toml
remappings = [
    "@openzeppelin/contracts/=../../lib/openzeppelin-contracts/contracts/",
    "solmate/=permit2/lib/solmate/"
]
```

## 3 更新tokenbank方法，指向permit2


#### ✅ 初始化

脚本initialize_3_3.sh完成以下步骤

```md
部署anvil 保持对mainnet的fork，可以访问permit2
用admin 部署tokenbank 合约和erc20合约
mint 给admin 1000个token
admin 使用erc20 transfer 方法给用户 user1 充值 原始 100 个token
此时user1在token bank里的余额是0.
user1 呼叫erc20合约，approve给permit2合约max值。
测试：
user1 在token bank里余额是0，在erc20里余额是100
tokenbank的总余额是0
```
执行记录在`initialize_3_3.log`


#### ✅ user1使用cast 方法构造EIP712 授权签名，转账10 个token (绕开TokenBank)

测试通过的方法顺序执行：

* restart anvil
* `initialize_3_3.sh`
* `test_sig.sh` -> `gen_and_send_signature_direct.ts`

一些坑和识别的办法:
**坑-1** 关于DOMAIN_SEPARATOR，在签名的时候要构造这个DOMAIN对象，标准EIP712里定义了很多个字端，Permit2没有用到Version字段

避免办法，比较你的Domain的哈希和Permit2里的（提供了方法可以查），要保证一致。
`cast call 0x000000000022D473030F116dDEE9F6B43aC78BA3 "DOMAIN_SEPARATOR()"  --rpc-url  https://eth.llamarpc.com`

**坑-2** 关于签名的方法本身
permitTransferFrom 签名的时候需要`spender`，调用的时候不用，而是根据message sender

[调用方法](https://github.com/Uniswap/permit2/blob/main/src/interfaces/ISignatureTransfer.sol#L73C14-L73C32)

[签约方法的Hash](https://github.com/Uniswap/permit2/blob/main/src/libraries/PermitHash.sol#L21)



#### user1使用cast 方法构造EIP712 授权签名，转账10 个token 给Token Bank


* restart anvil
* `initialize_3_3.sh`
* `test_sig_2.sh` -> `gen_and_send_signature_via_tokenBank.ts`

5 前端部分
