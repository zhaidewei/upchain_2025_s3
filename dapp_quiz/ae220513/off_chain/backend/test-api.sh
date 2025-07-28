#!/bin/bash

# ERC20 Transfer API 测试脚本
API_BASE="http://localhost:3000"

echo "🚀 开始测试 ERC20 Transfer API..."
echo "=================================="

# 1. 健康检查
echo "1. 测试健康检查接口..."
curl -s "${API_BASE}/health" | jq .
echo ""

# 2. 获取数据库统计信息
echo "2. 测试数据库统计接口..."
curl -s "${API_BASE}/api/stats" | jq .
echo ""

# 3. 获取最近的转账记录
echo "3. 测试最近转账记录接口..."
curl -s "${API_BASE}/api/transfers/recent?limit=5" | jq .
echo ""

# 4. 获取所有转账记录
echo "4. 测试所有转账记录接口..."
curl -s "${API_BASE}/api/transfers?limit=10" | jq .
echo ""

# 5. 根据地址查询转账记录
echo "5. 测试地址查询接口 (USER1)..."
curl -s "${API_BASE}/api/transfers/address?address=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" | jq .
echo ""

echo "6. 测试地址查询接口 (USER2)..."
curl -s "${API_BASE}/api/transfers/address?address=0x70997970C51812dc3A010C7d01b50e0d17dc79C8" | jq .
echo ""

echo "7. 测试地址查询接口 (USER3)..."
curl -s "${API_BASE}/api/transfers/address?address=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" | jq .
echo ""

# 6. 测试错误情况
echo "8. 测试无效地址格式..."
curl -s "${API_BASE}/api/transfers/address?address=invalid" | jq .
echo ""

echo "9. 测试缺少地址参数..."
curl -s "${API_BASE}/api/transfers/address" | jq .
echo ""

echo "10. 测试不存在的端点..."
curl -s "${API_BASE}/api/nonexistent" | jq .
echo ""

echo "✅ API 测试完成！"
echo "=================================="
echo "📋 测试总结："
echo "- 健康检查: 应该返回 success: true"
echo "- 统计信息: 应该显示总转账数和唯一地址数"
echo "- 转账记录: 应该返回转账数据数组"
echo "- 地址查询: 应该返回特定地址的转账记录"
echo "- 错误处理: 应该返回适当的错误信息"
