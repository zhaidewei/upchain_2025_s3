# MetaMask网络和账号设置指南

## 🌐 添加Anvil本地网络到MetaMask

### 1. 打开MetaMask，点击网络下拉菜单
### 2. 选择"添加网络"或"手动添加网络"
### 3. 输入以下信息：

```
网络名称: Anvil Local
新RPC URL: http://127.0.0.1:8545
链ID: 31337
货币符号: ETH
区块浏览器URL: (留空)
```

## 🔑 导入Anvil测试账号

### 使用私钥导入第一个Anvil账号：

```
地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
私钥: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 导入步骤：
1. 打开MetaMask
2. 点击右上角账号头像
3. 选择"导入账号"
4. 粘贴上面的私钥
5. 点击导入

## 🔄 账号切换流程

1. **在MetaMask中切换到想要的账号**
2. **确保连接到Anvil网络 (31337)**
3. **在dApp中点击"断开连接"**
4. **重新点击"连接钱包"**
5. **MetaMask会弹窗确认连接当前选中的账号**

## ⚠️ 注意事项

- 确保Anvil本地网络正在运行 (`anvil`)
- 只有导入到MetaMask的账号才能被dApp访问
- dApp只能看到MetaMask当前激活的账号
- 切换账号后需要重新授权连接
