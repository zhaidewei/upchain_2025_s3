# ERC20 Transfer Event Indexer

这是一个用于索引 ERC20 Token 转账事件的后端服务。

## 功能特性

- 🔗 连接到 Anvil 本地区块链
- 📊 轮询 ERC20 Transfer 事件
- 💾 将事件数据保存为 JSON 文件
- ⚙️ 可配置的轮询参数

## 安装和运行

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
创建 `.env` 文件：
```env
# 区块链配置
TOKEN_ADDRESS=0x你的合约地址
START_BLOCK=0

# API配置
PORT=3000
```

### 3. 编译 TypeScript
```bash
npm run build
```

### 4. 测试索引器
```bash
npm run test-indexer
```

### 5. 运行主程序
```bash
npm run dev
```

## 配置说明

### 环境变量

- `TOKEN_ADDRESS`: ERC20 合约地址
- `START_BLOCK`: 开始轮询的区块高度（0表示从当前区块开始）
- `PORT`: API 服务端口

### 轮询配置

- `BATCH_SIZE`: 每次轮询的区块数量（默认：3）
- `POLL_INTERVAL`: 轮询间隔（毫秒，默认：5000）

## 输出文件

- `test_events.json`: 测试事件数据
- `historical_events.json`: 历史事件数据
- `transfer_events_*.json`: 轮询过程中发现的事件

## 下一步

1. 集成 DuckDB 数据库
2. 实现 RESTful API
3. 添加前端界面

## 注意事项

- 确保 Anvil 区块链正在运行
- 确保已部署 ERC20 合约并进行了转账操作
- 合约地址需要正确配置在环境变量中
