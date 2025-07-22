# Quiz

编写 NFTMarket 合约：

支持设定任意ERC20价格来上架NFT
支持支付ERC20购买指定的NFT
要求测试内容：

上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
提交内容要求

使用 foundry 测试和管理合约；
提交 Github 仓库链接到挑战中；
提交 foge test 测试执行结果txt到挑战中；
