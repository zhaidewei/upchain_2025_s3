# [quiz](https://decert.me/challenge/2d4df0b6-17dc-4e5b-8f3a-728ed855e292)


实现一个通缩的 Token （ERC20）， 用来理解 rebase 型 Token 的实现原理：

起始发行量为 1 亿，税后每过一年在上一年的发行量基础上下降 1%
rebase 方法进行通缩
balanceOf()可反应通缩后的用户的正确余额。
需要测试 rebase 后，正确显示用户的余额， 贴出你的 github 代码

# 分析

这道题的重点是理解[AMPL](https://github.com/ampleforth/ampleforth-contracts)基于算法的稳定币。

让我们来拆解下代码：

```txt
Orchestrator (协调器)
    ↓
UFragmentsPolicy (货币政策)
    ↓
UFragments (AMPL代币) ← WAMPL (包装代币)
    ↓
MedianOracle (价格预言机)
```

## 1. UFragments.sol - 核心代币合约

作用: 实现AMPL代币的核心逻辑，这是一个可以自动调整供应量的ERC20代币
核心机制:
使用"gons"作为内部记账单位，用户看到的是"fragments"
当需要调整供应量时，通过改变_gonsPerFragment的比例来实现
所有用户的余额比例保持不变，但绝对数量会变化
关键功能: rebase()函数，只能由货币政策合约调用


2. UFragmentsPolicy.sol - 货币政策合约
作用: 决定何时以及如何调整AMPL的供应量
核心逻辑:
从预言机获取市场价格和目标价格
计算价格偏差，决定是否需要调整供应
调用UFragments合约的rebase函数
关键参数:
deviationThreshold: 价格偏差阈值
rebaseWindowOffsetSec: 调整时间窗口
各种增长函数参数


3. MedianOracle.sol - 中位数预言机
作用: 聚合多个数据提供者的价格信息，提供可靠的市场数据
核心功能:
管理授权的数据提供者
收集价格报告并计算中位数
处理数据过期和延迟逻辑
使用场景: 为UFragmentsPolicy提供市场价格和目标价格数据

4. WAMPL.sol - 包装代币合约
作用: 将AMPL包装成固定余额的代币，解决AMPL余额变化的问题
核心机制:
用户存入AMPL，获得wAMPL
wAMPL代表AMPL总供应量的固定百分比
无论AMPL供应量如何变化，wAMPL持有者的市场份额保持不变
使用场景: 为DeFi协议提供稳定的AMPL接口

5. Orchestrator.sol - 协调器合约
作用: 协调整个rebase流程，确保所有下游合约同步更新
核心功能:
调用UFragmentsPolicy的rebase函数
执行预定义的下游交易列表
防止合约调用，避免闪电贷攻击

## 工作流程

定时触发: 系统在预定义的时间窗口内触发rebase
数据获取: UFragmentsPolicy从MedianOracle获取市场价格和目标价格
计算调整: 根据价格偏差计算需要调整的供应量
执行调整: 调用UFragments.rebase()调整代币供应
通知下游: Orchestrator通知所有相关合约更新状态


# 简化版

1 做一个erc20合约，仿照UFragments.sol 但是：
不需要做代理合约
不需要有外部policy合约去计算，固定按照每年增发一次，但是增发数量按照年递减。
按照一年是365天，每天24小时，用区块上的timestamp去计算什么时候应该mint新的币
mint完后，调用rebase方法去调整gon和fragment之间的关系

写个forge 的测试用例即可，可以调用vm方法去调整区块时间。
