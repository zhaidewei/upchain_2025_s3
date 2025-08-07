# [quiz](https://decert.me/challenge/df4886bc-65c6-45fb-ad0c-3389a9f99bf2)

修改之前最小代理工厂 1% 费用修改为 5%， 然后 5% 的 ETH 与相应的 Token 调用 Uniswap V2Router AddLiquidity 添加MyToken与 ETH 的流动性（如果是第一次添加流动性按mint 价格作为流动性价格）。

除了之前的 mintMeme() 可以购买 meme 外，添加一个方法: buyMeme()， 以便在 Unswap 的价格优于设定的起始价格时，用户可调用该函数来购买 Meme.

需要包含你的测试用例， 运行 Case 的日志，请贴出你的 github 代码。

# 分析

1 先找出来之前做的[最小代理工厂作业](https://github.com/zhaidewei/upchain_2025_s3/tree/main/advance_contract/75782f22)

>假设你（项目方）正在EVM 链上创建一个Meme 发射平台，每一个 MEME 都是一个 ERC20 token ，你需要编写一个通过最⼩代理方式来创建 Meme的⼯⼚合约，以减少 Meme 发行者的 Gas 成本，编写的⼯⼚合约包含两个方法：

>• deployMeme(string symbol, uint totalSupply, uint perMint, uint price), Meme发行者调⽤该⽅法创建ERC20 合约（实例）, 参数描述如下： symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），totalSupply 表示总发行量， perMint 表示一次铸造 Meme 的数量（为了公平的铸造，而不是一次性所有的 Meme 都铸造完）， price 表示每个 Meme 铸造时需要的支付的费用（wei 计价）。每次铸造费用分为两部分，一部分（1%）给到项目方（你），一部分给到 Meme 的发行者（即调用该方法的用户）。

>• mintMeme(address tokenAddr) payable: 购买 Meme 的用户每次调用该函数时，会发行 deployInscription 确定的 perMint 数量的 token，并收取相应的费用。

修改点：
2. 部署Uniswap v2的合约，允许添加一个pool

3. 修改之前的mintMeme 方法，用户费用的5% 和 对应的5% 的value 需要拿到Uniswap v2里做一个liquidity 的pool

4. 在每一个erc20 token合约里，添加从uniswap里buy meme token的方法，buy Token

# 操作

1. Admin 部署一个ERC20合约（基于OZ），保存地址。 ERC20合约里的特殊点： 数据对齐

1.5 Admin 部署一个Uniswapv2合约

2. Admin 部署一个工厂合约，工厂合约需要知道erc20合约的地址。

- 3. User1 呼叫工厂合约的
`deployMeme(string symbol, uint totalSupply, uint perMint, uint price)`，部署一个proxy合约 数据 string symbol uint totalSupply uint perMint uint price address factory address owner address implementation 合约里用callback方法去对应erc20实现合约。

- 4. 检查下工厂合约和erc20数据合约的参数是否对齐 在erc20部署之后，使用cast inspect contract storageLayout 可以看到

- 5. User2，调用工厂合约的mintMeme 方法（参数address proxy），同时给出value值，value值=price 在MintMeme里，工厂先是检查value是否匹配proxy的price 然后合约调用proxy的mint方法产生代币 然后分配value
