#!/bin/bash
# anvil test users
USER1_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
USER1_ADDRESS=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
USER2_PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
USER2_ADDRESS=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
ERC20_ADDRESS=0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
TOKEN_BANK_ADDRESS=0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0
PERMIT2_ADDRESS=0x5fbdb2315678afecb367f032d93f642f64180aa3

# 函数：提取纯数字，去除科学计数法格式
extract_number() {
    echo "$1" | sed 's/\[.*\]//' | tr -d ' '
}

# 函数：使用bc进行大整数比较
bigint_eq() {
    local a="$1"
    local b="$2"
    local result=$(echo "$a == $b" | bc -l)
    [ "$result" -eq 1 ]
}

# 函数：使用bc进行大整数减法
bigint_sub() {
    local a="$1"
    local b="$2"
    echo "$a - $b" | bc -l
}

# 函数：使用bc进行大整数加法
bigint_add() {
    local a="$1"
    local b="$2"
    echo "$a + $b" | bc -l
}

# 函数：检查特定nonce是否已被使用
check_nonce_used() {
    local owner="$1"
    local nonce="$2"

    # 计算 wordPos 和 bitPos
    local wordPos=$(echo "$nonce / 256" | bc)
    local bitPos=$(echo "$nonce % 256" | bc)

    # 查询 nonceBitmap
    local bitmap=$(cast call --rpc-url http://127.0.0.1:8545 \
        $PERMIT2_ADDRESS \
        "nonceBitmap(address,uint256)(uint256)" \
        $owner \
        $wordPos)

    # 检查对应位是否被设置
    local bit=$(echo "$bitmap / (2^$bitPos) % 2" | bc)

    if [ "$bit" -eq 1 ]; then
        echo "1"  # 已使用
    else
        echo "0"  # 未使用
    fi
}

# 函数：从指定nonce开始寻找第一个未使用的nonce
find_unused_nonce() {
    local owner="$1"
    local start_nonce="${2:-0}"  # 默认从0开始

    local current_nonce=$start_nonce
    local max_attempts=1000  # 防止无限循环

    echo "🔍 为 $owner 寻找未使用的nonce，从 $start_nonce 开始..." >&2

    for i in $(seq 0 $max_attempts); do
        local used=$(check_nonce_used "$owner" "$current_nonce")

        if [ "$used" -eq 0 ]; then
            echo "$current_nonce"  # 返回未使用的nonce
            echo "✅ 找到未使用的nonce: $current_nonce" >&2
            return 0
        fi

        current_nonce=$(echo "$current_nonce + 1" | bc)
    done

    echo "❌ 在 $max_attempts 次尝试内未找到未使用的nonce" >&2
    return 1
}

# 函数：显示nonce状态信息
show_nonce_status() {
    local owner="$1"
    local nonce="$2"

    echo "📊 Nonce状态信息:"
    echo "  地址: $owner"
    echo "  Nonce: $nonce"

    local used=$(check_nonce_used "$owner" "$nonce")
    if [ "$used" -eq 1 ]; then
        echo "  状态: ❌ 已使用"
    else
        echo "  状态: ✅ 未使用"
    fi

    # 显示wordPos和bitPos信息
    local wordPos=$(echo "$nonce / 256" | bc)
    local bitPos=$(echo "$nonce % 256" | bc)
    echo "  WordPos: $wordPos"
    echo "  BitPos: $bitPos"
}

echo "🚀 开始测试 TokenBank depositWithPermit2 转账..."

echo "📋 配置信息:"
echo "  ERC20合约: $ERC20_ADDRESS"
echo "  TokenBank合约: $TOKEN_BANK_ADDRESS"
echo "  User1 (签名者): $USER1_ADDRESS"

# 0. 检查并寻找可用的nonce
echo "🔍 检查nonce状态..."

# 检查nonce 0的状态
show_nonce_status "$USER1_ADDRESS" "0"

# 寻找未使用的nonce
UNUSED_NONCE=$(find_unused_nonce "$USER1_ADDRESS" "0")
if [ $? -eq 0 ]; then
    echo "🎯 推荐使用的nonce: $UNUSED_NONCE"
    export RECOMMENDED_NONCE=$UNUSED_NONCE
else
    echo "⚠️  无法找到未使用的nonce，使用默认值0"
    export RECOMMENDED_NONCE=0
fi

echo ""

# 1. 检查初始状态
echo "🔍 检查初始状态..."

USER1_TOKEN_BALANCE_BEFORE_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER1_ADDRESS)

TOKENBANK_TOKEN_BALANCE_BEFORE_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $TOKEN_BANK_ADDRESS)

USER1_BANK_BALANCE_BEFORE_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $TOKEN_BANK_ADDRESS \
    "balances(address)(uint256)" \
    $USER1_ADDRESS)

# 提取纯数字
USER1_TOKEN_BALANCE_BEFORE=$(extract_number "$USER1_TOKEN_BALANCE_BEFORE_RAW")
TOKENBANK_TOKEN_BALANCE_BEFORE=$(extract_number "$TOKENBANK_TOKEN_BALANCE_BEFORE_RAW")
USER1_BANK_BALANCE_BEFORE=$(extract_number "$USER1_BANK_BALANCE_BEFORE_RAW")

echo "📊 初始状态:"
echo "  User1 ERC20余额: $USER1_TOKEN_BALANCE_BEFORE"
echo "  TokenBank ERC20余额: $TOKENBANK_TOKEN_BALANCE_BEFORE"
echo "  User1在TokenBank存款余额: $USER1_BANK_BALANCE_BEFORE"

# 2. 调用TypeScript脚本进行签名和交易
echo "💸 生成签名并执行TokenBank depositWithPermit2..."

# 将推荐的nonce传递给TypeScript脚本
RECOMMENDED_NONCE=$UNUSED_NONCE tsx gen_and_send_signature_via_tokenBank.ts

if [ $? -eq 0 ]; then
    echo "✅ gen_and_send_signature_via_tokenBank.ts执行完成"
else
    echo "❌ gen_and_send_signature_via_tokenBank.ts执行失败"
    exit 1
fi

# 3. 检查最终状态
echo "🔍 检查最终状态..."

USER1_TOKEN_BALANCE_AFTER_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $USER1_ADDRESS)

TOKENBANK_TOKEN_BALANCE_AFTER_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $ERC20_ADDRESS \
    "balanceOf(address)(uint256)" \
    $TOKEN_BANK_ADDRESS)

USER1_BANK_BALANCE_AFTER_RAW=$(cast call --rpc-url http://127.0.0.1:8545 \
    $TOKEN_BANK_ADDRESS \
    "balances(address)(uint256)" \
    $USER1_ADDRESS)

# 提取纯数字
USER1_TOKEN_BALANCE_AFTER=$(extract_number "$USER1_TOKEN_BALANCE_AFTER_RAW")
TOKENBANK_TOKEN_BALANCE_AFTER=$(extract_number "$TOKENBANK_TOKEN_BALANCE_AFTER_RAW")
USER1_BANK_BALANCE_AFTER=$(extract_number "$USER1_BANK_BALANCE_AFTER_RAW")

echo "📊 最终状态:"
echo "  User1 ERC20余额: $USER1_TOKEN_BALANCE_AFTER"
echo "  TokenBank ERC20余额: $TOKENBANK_TOKEN_BALANCE_AFTER"
echo "  User1在TokenBank存款余额: $USER1_BANK_BALANCE_AFTER"

# 4. 验证结果
echo "✅ 验证结果..."

AMOUNT="10000000000000000000"  # 10 tokens

# 检查User1的ERC20余额是否减少了10个token
EXPECTED_USER1_TOKEN_BALANCE=$(bigint_sub "$USER1_TOKEN_BALANCE_BEFORE" "$AMOUNT")
if bigint_eq "$USER1_TOKEN_BALANCE_AFTER" "$EXPECTED_USER1_TOKEN_BALANCE"; then
    echo "✅ User1 ERC20余额正确: 减少了10个token"
else
    echo "❌ User1 ERC20余额错误: 期望 $EXPECTED_USER1_TOKEN_BALANCE, 实际 $USER1_TOKEN_BALANCE_AFTER"
fi

# 检查TokenBank的ERC20余额是否增加了10个token
EXPECTED_TOKENBANK_TOKEN_BALANCE=$(bigint_add "$TOKENBANK_TOKEN_BALANCE_BEFORE" "$AMOUNT")
if bigint_eq "$TOKENBANK_TOKEN_BALANCE_AFTER" "$EXPECTED_TOKENBANK_TOKEN_BALANCE"; then
    echo "✅ TokenBank ERC20余额正确: 增加了10个token"
else
    echo "❌ TokenBank ERC20余额错误: 期望 $EXPECTED_TOKENBANK_TOKEN_BALANCE, 实际 $TOKENBANK_TOKEN_BALANCE_AFTER"
fi

# 检查User1在TokenBank的存款余额是否增加了10个token
EXPECTED_USER1_BANK_BALANCE=$(bigint_add "$USER1_BANK_BALANCE_BEFORE" "$AMOUNT")
if bigint_eq "$USER1_BANK_BALANCE_AFTER" "$EXPECTED_USER1_BANK_BALANCE"; then
    echo "✅ User1在TokenBank存款余额正确: 增加了10个token"
else
    echo "❌ User1在TokenBank存款余额错误: 期望 $EXPECTED_USER1_BANK_BALANCE, 实际 $USER1_BANK_BALANCE_AFTER"
fi

# 验证总供应量守恒
USER1_CHANGE=$(bigint_sub "$USER1_TOKEN_BALANCE_AFTER" "$USER1_TOKEN_BALANCE_BEFORE")
TOKENBANK_CHANGE=$(bigint_sub "$TOKENBANK_TOKEN_BALANCE_AFTER" "$TOKENBANK_TOKEN_BALANCE_BEFORE")
TOTAL_CHANGE=$(bigint_add "$USER1_CHANGE" "$TOKENBANK_CHANGE")

if bigint_eq "$TOTAL_CHANGE" "0"; then
    echo "✅ 总供应量守恒: User1减少的 = TokenBank增加的"
else
    echo "❌ 总供应量不守恒: 总变化 = $TOTAL_CHANGE"
fi

echo "🎉 TokenBank depositWithPermit2测试完成!"
echo "📝 流程总结:"
echo "  1. User1签名授权TokenBank为spender"
echo "  2. User1调用TokenBank.depositWithPermit2()"
echo "  3. TokenBank调用Permit2.permitTransferFrom()"
echo "  4. Permit2验证签名并转移token到TokenBank"
echo "  5. TokenBank更新User1的存款余额"
echo "  6. ✅ 通过TokenBank进行存款，无需预先approve"
