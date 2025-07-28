# 问题
后端索引出之前自己发行的 ERC20 Token 转账, 并记录到数据库中，并提供一个 Restful 接口来获取某一个地址的转账记录。
前端在用户登录后， 从后端查询出该用户地址的转账记录， 并展示。
要求：模拟两笔以上的转账记录，请贴出 github 和 前端截图。

# 拆分

## 1. 链上合约

### 1.1 ✅ 合约src文件

### 1.2 ✅ 使用脚本实现

初始化Anvil链
在Anvil链上部署ERC20 Token 合约，保证每个转账方法都会emit transfer event
合约admin给USER1 USER2使用transfer方法转账，确保它们获取初始资金
USER1 和 USER2 相互转账。
[deploy_and_test.sh](on_chain/deploy_and_test.sh)
`deploy_and_test.sh`

## 2. 后端 + 数据库

创建一个Typescrit 项目，使用viem 库public wallte
获取当前区块高度
然后从起始区块（可以配置）开始，以3个区块为单位，
持续 轮询区块的transfer 事件。
先输出json 文件观察结构
采用duckDB，根据2进行表的建模，然后给2里添加入库的方法
然后给后端提供一个REST 接口供根据地址查询所有的转账记录

### 2.1 ✅ 初始化 TypeScript 项目（如 npm init, tsconfig.json）
### 2.2 ✅ 集成 viem，实现区块链连接和事件查询
### 2.3 ✅ 实现区块轮询和 Transfer 事件解析，输出 json 文件
### 2.4 ✅ 集成 DuckDB，设计表结构，写入事件数据
`npm run test-db`
### 2.5 ✅ 实现 Restful API 查询接口
`npm run api`
### 2.6 ✅ 测试：用 curl 查询接口，确保能查到转账记录
`test-api.sh`


## 3. 前端

React + Wagmi + Vite
支持钱包登录
连接后端API，查询记录，显示

### 3.1 ✅ 项目初始化
- 创建 React + TypeScript 项目
`npm create vite@latest . -- --template react-ts`
- 配置 Vite 开发环境 `npm install`
- 安装 Wagmi + Viem 依赖
`npm install wagmi viem @wagmi/core @wagmi/connectors`

- 配置 Tailwind CSS 样式
`npm install -D tailwindcss postcss autoprefixer`
`npx tailwindcss init -p`



### 3.2 ✅ 钱包连接功能
- 实现钱包连接组件
- 支持 MetaMask 等主流钱包
- 显示当前连接地址
- 钱包断开连接功能

`test-frontend.sh`


### 3.3 转账记录查询
- 连接后端 API (http://localhost:3000)
- 根据当前连接地址查询转账记录
- 显示转账历史列表
- 支持分页加载


### 3.6 ✅ 用户体验优化
- 加载状态显示
- 错误处理和提示
- 响应式设计
- 美观的 UI 界面
