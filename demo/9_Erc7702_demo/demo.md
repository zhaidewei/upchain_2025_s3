https://viem.sh/docs/eip7702/contract-writes


# 总结：

1. 有两种用法，第一种，EOA自己直接授权，EOA的钱包签署signAuthorization. 这里有很多参数，必须要填的是CA合约的地址。以及初始发起人的信息

2. 第二种，relay签名，这里有点奇怪。

3. 可以prepare签名，然后writeContract（依赖abi编码），也可以用sendTransaction方法（自己构造calldata）
