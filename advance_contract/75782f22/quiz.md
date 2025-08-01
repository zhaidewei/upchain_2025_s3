# [Quiz](https://decert.me/challenge/75782f22-edb8-4e82-9b68-0a4f46fcaadd)

Quiz#1
假设你（项目方）正在EVM 链上创建一个Meme 发射平台，每一个 MEME 都是一个 ERC20 token ，你需要编写一个通过最⼩代理方式来创建 Meme的⼯⼚合约，以减少 Meme 发行者的 Gas 成本，编写的⼯⼚合约包含两个方法：

• deployMeme(string symbol, uint totalSupply, uint perMint, uint price), Meme发行者调⽤该⽅法创建ERC20 合约（实例）, 参数描述如下： symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），totalSupply 表示总发行量， perMint 表示一次铸造 Meme 的数量（为了公平的铸造，而不是一次性所有的 Meme 都铸造完）， price 表示每个 Meme 铸造时需要的支付的费用（wei 计价）。每次铸造费用分为两部分，一部分（1%）给到项目方（你），一部分给到 Meme 的发行者（即调用该方法的用户）。

• mintMeme(address tokenAddr) payable: 购买 Meme 的用户每次调用该函数时，会发行 deployInscription 确定的 perMint 数量的 token，并收取相应的费用。

要求：

包含测试用例（需要有完整的 forge 工程）：
费用按比例正确分配到 Meme 发行者账号及项目方账号。
每次发行的数量正确，且不会超过 totalSupply.
请包含运行测试的截图或日志
请贴出你的代码工程链接。

## 分析

[EIP1167](https://eips.ethereum.org/EIPS/eip-1167)
The description of above is very difficult to understand. They also showed one example code:
https://github.com/optionality/clone-factory

我觉得需要实现如下几个部分：

1. 一个erc20的实现合约，基本上import openzepplin就行了，然后一次性部署。但是需要把存储配置好
2. 一个最小代理合约，使用网上已经有的最小代理合约示例，https://github.com/optionality/clone-factory， 不用自己写
但是需要有参数，工厂合约地址，调用者发行者的地址，symbol， totalSupply， perMint， price
注意存储结构要对齐。
3. 一个工厂合约，实现题里要求的两个方法，第一个方法部署一个代理合约，并且设置它里面的数据。配置它使用step1里的erc20 实现合约
mintMeme， 任何人可以调用，需要支付eth作为费用，费用分配到

## 操作

1. Admin 部署一个ERC20合约（基于OZ），保存地址。
ERC20合约里的特殊点：
数据对齐


2. Admin 部署一个工厂合约，工厂合约需要知道erc20合约的地址。

3. User1 呼叫工厂合约的deployMeme(string symbol, uint totalSupply, uint perMint, uint price)，部署一个proxy合约
数据
string symbol
uint totalSupply
uint perMint
uint price
address factory
address owner
address implementation
合约里用callback方法去对应erc20实现合约。

4. 检查下工厂合约和erc20数据合约的参数是否对齐
在erc20部署之后，使用cast inspect contract storageLayout 可以看到

5 User2，调用工厂合约的mintMeme 方法（参数address proxy），同时给出value值，value值=price
在MintMeme里，工厂先是检查value是否匹配proxy的price
然后合约调用proxy的mint方法产生代币
然后分配value

## 测试

deploy_and_test.sh
deploy_and_test.log
