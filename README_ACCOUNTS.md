# 测试账户生成脚本

这个脚本通过anvil的默认助记词生成10个测试账户的地址和私钥，并设置环境变量。

## 功能

- ✅ 生成10个测试账户（Account 0-9）
- ✅ 设置环境变量，方便在脚本中使用
- ✅ 提供常用账户的别名（ADMIN, USER1-5）
- ✅ 静默模式，减少警告信息

## 使用方法

### 1. 生成账户并设置环境变量
```bash
source generate_accounts.sh
```

### 2. 验证环境变量
```bash
echo "ADMIN_ADDRESS: $ADMIN_ADDRESS"
echo "USER1_ADDRESS: $USER1_ADDRESS"
echo "USER2_ADDRESS: $USER2_ADDRESS"
```

## 生成的账户

| 账户 | 地址 | 私钥 |
|------|------|------|
| Account 0 (ADMIN) | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 |
| Account 1 (USER1) | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d |
| Account 2 (USER2) | 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC | 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a |
| Account 3 (USER3) | 0x90F79bf6EB2c4f870365E785982E1f101E93b906 | 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 |
| Account 4 (USER4) | 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 | 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a |
| Account 5 (USER5) | 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc | 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba |
| Account 6 | 0x976EA74026E726554dB657fA54763abd0C3a0aa9 | 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e |
| Account 7 | 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 | 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356 |
| Account 8 | 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f | 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97 |
| Account 9 | 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 | 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 |

## 环境变量

### 别名变量
- `ADMIN_ADDRESS`, `ADMIN_PRIVATE_KEY` - Account 0
- `USER1_ADDRESS`, `USER1_PRIVATE_KEY` - Account 1
- `USER2_ADDRESS`, `USER2_PRIVATE_KEY` - Account 2
- `USER3_ADDRESS`, `USER3_PRIVATE_KEY` - Account 3
- `USER4_ADDRESS`, `USER4_PRIVATE_KEY` - Account 4
- `USER5_ADDRESS`, `USER5_PRIVATE_KEY` - Account 5

### 数字变量
- `ACCOUNT_0_ADDRESS`, `ACCOUNT_0_PRIVATE_KEY`
- `ACCOUNT_1_ADDRESS`, `ACCOUNT_1_PRIVATE_KEY`
- ...
- `ACCOUNT_9_ADDRESS`, `ACCOUNT_9_PRIVATE_KEY`

## 在脚本中使用

```bash
#!/bin/bash

# 加载账户
source generate_accounts.sh

# 使用账户
echo "Using admin account: $ADMIN_ADDRESS"

# 使用cast命令
cast send --rpc-url $anvil --private-key $ADMIN_PRIVATE_KEY $CONTRACT "function()" $USER1_ADDRESS
```

## 注意事项

1. **安全性**: 这些是测试账户，私钥已经公开，不要用于生产环境
2. **助记词**: 使用anvil的默认助记词 `test test test test test test test test test test test junk`
3. **环境变量**: 使用 `source` 命令加载，这样环境变量会在当前shell中生效
4. **清理**: 脚本会自动清理之前设置的账户变量

## 故障排除

### 如果cast命令失败
```bash
# 检查Foundry是否安装
forge --version

# 检查cast命令
cast --help
```

### 如果环境变量没有设置
```bash
# 确保使用source命令
source generate_accounts.sh

# 检查变量
echo $ADMIN_ADDRESS
```
