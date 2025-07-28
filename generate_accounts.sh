#!/bin/bash

# Anvil默认助记词
MNEMONIC="test test test test test test test test test test test junk"

# 设置静默模式（减少警告）
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1

# 生成10个账户的地址和私钥
echo "Generating 10 test accounts from anvil mnemonic..."
echo ""

# 清空之前的账户变量
unset ACCOUNT_0_ADDRESS ACCOUNT_0_PRIVATE_KEY
unset ACCOUNT_1_ADDRESS ACCOUNT_1_PRIVATE_KEY
unset ACCOUNT_2_ADDRESS ACCOUNT_2_PRIVATE_KEY
unset ACCOUNT_3_ADDRESS ACCOUNT_3_PRIVATE_KEY
unset ACCOUNT_4_ADDRESS ACCOUNT_4_PRIVATE_KEY
unset ACCOUNT_5_ADDRESS ACCOUNT_5_PRIVATE_KEY
unset ACCOUNT_6_ADDRESS ACCOUNT_6_PRIVATE_KEY
unset ACCOUNT_7_ADDRESS ACCOUNT_7_PRIVATE_KEY
unset ACCOUNT_8_ADDRESS ACCOUNT_8_PRIVATE_KEY
unset ACCOUNT_9_ADDRESS ACCOUNT_9_PRIVATE_KEY

# 生成账户0-9
for i in {0..9}; do
    # 使用cast wallet derive-private-key生成私钥
    PRIVATE_KEY=$(cast wallet derive-private-key --mnemonic "$MNEMONIC" --mnemonic-index $i 2>/dev/null)
    ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY 2>/dev/null)

    # 设置环境变量
    export ACCOUNT_${i}_ADDRESS=$ADDRESS
    export ACCOUNT_${i}_PRIVATE_KEY=$PRIVATE_KEY

    # 显示账户信息
    echo "Account $i:"
    echo "  Address: $ADDRESS"
    echo "  Private Key: $PRIVATE_KEY"
    echo ""
done

# 设置常用的账户别名
export ADMIN_ADDRESS=$ACCOUNT_0_ADDRESS
export ADMIN_PRIVATE_KEY=$ACCOUNT_0_PRIVATE_KEY
export USER1_ADDRESS=$ACCOUNT_1_ADDRESS
export USER1_PRIVATE_KEY=$ACCOUNT_1_PRIVATE_KEY
export USER2_ADDRESS=$ACCOUNT_2_ADDRESS
export USER2_PRIVATE_KEY=$ACCOUNT_2_PRIVATE_KEY
export USER3_ADDRESS=$ACCOUNT_3_ADDRESS
export USER3_PRIVATE_KEY=$ACCOUNT_3_PRIVATE_KEY
export USER4_ADDRESS=$ACCOUNT_4_ADDRESS
export USER4_PRIVATE_KEY=$ACCOUNT_4_PRIVATE_KEY
export USER5_ADDRESS=$ACCOUNT_5_ADDRESS
export USER5_PRIVATE_KEY=$ACCOUNT_5_PRIVATE_KEY

echo "✅ Environment variables set successfully!"
echo ""
echo "📋 Available variables:"
echo "  ADMIN_ADDRESS, ADMIN_PRIVATE_KEY"
echo "  USER1_ADDRESS, USER1_PRIVATE_KEY"
echo "  USER2_ADDRESS, USER2_PRIVATE_KEY"
echo "  USER3_ADDRESS, USER3_PRIVATE_KEY"
echo "  USER4_ADDRESS, USER4_PRIVATE_KEY"
echo "  USER5_ADDRESS, USER5_PRIVATE_KEY"
echo "  ACCOUNT_0_ADDRESS, ACCOUNT_0_PRIVATE_KEY"
echo "  ACCOUNT_1_ADDRESS, ACCOUNT_1_PRIVATE_KEY"
echo "  ... (up to ACCOUNT_9)"
echo ""
echo "💡 Usage: source generate_accounts.sh"
