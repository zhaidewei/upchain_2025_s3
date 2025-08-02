# ERC-7702 授权机制详解

## 传统方式 vs ERC-7702

### 传统方式（需要用户签名）
```
用户 EOA ──签名──→ 交易 ──→ 合约
```

### ERC-7702 方式（预授权）
```
用户 EOA ──签名授权──→ Relay ──使用授权──→ 交易 ──→ 合约
```

## 授权流程详解

### 步骤 1: 用户签名授权
```typescript
const authorization = await walletClient.signAuthorization({
    account: eoa,           // 用户的 EOA
    contractAddress,        // 要调用的合约地址
})
```

这里用户用自己的私钥签名，授权 relay 代表自己调用特定合约。

### 步骤 2: Relay 使用授权执行
```typescript
const hash = await walletClient.writeContract({
    abi,
    address: eoa.address,           // 目标：用户的 EOA
    authorizationList: [authorization], // 使用预授权
    functionName: 'initialize',
    args: []
})
```

## 为什么这样设计？

### 1. 用户体验
- 用户只需要签名一次授权
- 后续操作由 relay 完成，用户无需每次签名

### 2. Gas 优化
- Relay 可以批量处理多个用户的交易
- 减少用户需要支付的 gas 费用

### 3. 执行上下文
- 代码在**用户的 EOA 上下文**下执行
- 不是 relay 的上下文
- 这意味着 `msg.sender` 是用户的 EOA，不是 relay

## 安全机制

1. **授权范围限制**：只能调用指定的合约
2. **时间限制**：授权可以设置过期时间
3. **可撤销**：用户可以随时撤销授权

## 实际执行流程

```
1. 用户签名授权 → 2. Relay 获得授权 → 3. Relay 调用合约
                                      ↓
4. 合约在用户 EOA 上下文中执行 → 5. msg.sender = 用户 EOA
```
