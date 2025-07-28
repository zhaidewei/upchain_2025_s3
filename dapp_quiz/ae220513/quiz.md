# 问题
后端索引出之前自己发行的 ERC20 Token 转账, 并记录到数据库中，并提供一个 Restful 接口来获取某一个地址的转账记录。
前端在用户登录后， 从后端查询出该用户地址的转账记录， 并展示。
要求：模拟两笔以上的转账记录，请贴出 github 和 前端截图。

# 拆分

1. 链上合约

1.1 合约src文件

1.2 使用脚本实现：

初始化Anvil链
在Anvil链上部署ERC20 Token 合约，保证每个转账方法都会emit transfer event
合约admin给USER1 USER2使用transfer方法转账，确保它们获取初始资金
USER1 和 USER2 相互转账。

2. 后端

创建一个Typescrit 项目，使用viem 库public wallte + getLogs 方法
获取当前区块高度
然后从起始区块（可以配置）开始，以3个区块为单位，
持续 轮询区块的transfer 事件。
先输出json 文件观察结构

3. 数据库

采用duckDB，根据2进行表的建模，然后给2里添加入库的方法

4. 前端

react + wagmi
支持钱包登陆
链接duckDB，查询记录，显示
