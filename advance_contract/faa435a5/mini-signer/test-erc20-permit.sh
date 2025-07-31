#!/bin/bash

# ERC20 Permit 测试脚本
# 这个脚本专门测试 ERC20 合约的 permit 功能
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
set -e

echo "=== ERC20 Permit 功能测试 ==="
echo ""

# 设置环境变量
export OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # anvil-tester # pragma: allowlist secret
export SPENDER_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"  # anvil-tester2 # pragma: allowlist secret
export ERC20_CONTRACT="0x5FbDB2315678afecb367f032d93F642f64180aa3"
export CHAIN_ID="31337"  # Anvil local network
export VALUE="10000000000000000000"
export DEADLINE=1753977600  # 1 hour from now

# 获取地址
OWNER_ADDRESS=$(cast wallet address --private-key $OWNER_PRIVATE_KEY)
SPENDER_ADDRESS=$(cast wallet address --private-key $SPENDER_PRIVATE_KEY)

echo "配置信息："
echo "  Owner Address: $OWNER_ADDRESS"
echo "  Spender Address: $SPENDER_ADDRESS"
echo "  ERC20 Contract: $ERC20_CONTRACT"
echo "  Chain ID: $CHAIN_ID"
echo "  Value: $VALUE"
echo "  Deadline: $DEADLINE"
echo ""

# 步骤 1: 检查初始状态
echo "=== 步骤 1: 检查初始状态 ==="
echo "Owner ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $OWNER_ADDRESS --rpc-url http://localhost:8545

echo "Spender ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $SPENDER_ADDRESS --rpc-url http://localhost:8545

echo "Owner 的 nonce:"
cast call $ERC20_CONTRACT "nonces(address)(uint256)" $OWNER_ADDRESS --rpc-url http://localhost:8545
echo ""

# 步骤 2: 生成 permit 签名
echo "=== 步骤 2: 生成 permit 签名 ==="

# Get the current nonce from the contract
CURRENT_NONCE=$(cast call $ERC20_CONTRACT "nonces(address)(uint256)" $OWNER_ADDRESS --rpc-url http://localhost:8545)
echo "Current nonce: $CURRENT_NONCE"

# Pass environment variables to the TypeScript script
SIGNATURE_OUTPUT=$(NONCE=$CURRENT_NONCE SPENDER_ADDRESS=$SPENDER_ADDRESS tsx gen_signature.ts)
echo "$SIGNATURE_OUTPUT"
echo ""

# 提取签名参数（JSON 方式）
V=$(echo "$SIGNATURE_OUTPUT" | jq -r .v)
R=$(echo "$SIGNATURE_OUTPUT" | jq -r .r)
S=$(echo "$SIGNATURE_OUTPUT" | jq -r .s)

echo "提取的签名参数："
echo "  v: $V"
echo "  r: $R"
echo "  s: $S"
echo ""

# 步骤 3: 执行 permit
# permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
echo "=== 步骤 3: 执行 permit ==="
cast send $ERC20_CONTRACT "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)" \
  $OWNER_ADDRESS $SPENDER_ADDRESS $VALUE $DEADLINE $V $R $S \
  --private-key $SPENDER_PRIVATE_KEY \
  --rpc-url http://localhost:8545

echo ""

# 步骤 4: 检查 permit 后的状态
echo "=== 步骤 4: 检查 permit 后的状态 ==="
echo "Owner 对 Spender 的授权:"
cast call $ERC20_CONTRACT "allowance(address,address)(uint256)" $OWNER_ADDRESS $SPENDER_ADDRESS --rpc-url http://localhost:8545

echo "Owner 的 nonce:"
cast call $ERC20_CONTRACT "nonces(address)(uint256)" $OWNER_ADDRESS --rpc-url http://localhost:8545
echo ""

# 步骤 5: 使用授权转移代币
echo "=== 步骤 5: 使用授权转移代币 ==="
cast send $ERC20_CONTRACT "transferFrom(address,address,uint256)" \
  $OWNER_ADDRESS $SPENDER_ADDRESS $VALUE \
  --private-key $SPENDER_PRIVATE_KEY \
  --rpc-url http://localhost:8545

echo ""

# 步骤 6: 检查最终状态
echo "=== 步骤 6: 检查最终状态 ==="
echo "Owner ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $OWNER_ADDRESS --rpc-url http://localhost:8545

echo "Spender ERC20 余额:"
cast call $ERC20_CONTRACT "balanceOf(address)(uint256)" $SPENDER_ADDRESS --rpc-url http://localhost:8545

echo "Owner 对 Spender 的剩余授权:"
cast call $ERC20_CONTRACT "allowance(address,address)(uint256)" $OWNER_ADDRESS $SPENDER_ADDRESS --rpc-url http://localhost:8545
echo ""

echo "=== ERC20 Permit 测试完成 ==="
