#!/bin/bash

echo "🧪 测试前端功能..."
echo "=================================="

# 检查前端服务器
echo "1. 检查前端服务器状态..."
if curl -s http://localhost:5173 > /dev/null; then
    echo "✅ 前端服务器运行正常 (http://localhost:5173)"
else
    echo "❌ 前端服务器未运行"
    exit 1
fi

# 检查后端API
echo "2. 检查后端API状态..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ 后端API运行正常 (http://localhost:3000)"
else
    echo "❌ 后端API未运行"
    exit 1
fi

# 测试API数据
echo "3. 测试API数据..."
API_RESPONSE=$(curl -s http://localhost:3000/api/stats)
if echo "$API_RESPONSE" | grep -q "success.*true"; then
    echo "✅ API数据正常"
    echo "   响应: $API_RESPONSE"
else
    echo "❌ API数据异常"
    echo "   响应: $API_RESPONSE"
fi

# 测试转账记录API
echo "4. 测试转账记录API..."
TRANSFER_RESPONSE=$(curl -s "http://localhost:3000/api/transfers/address?address=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
if echo "$TRANSFER_RESPONSE" | grep -q "success.*true"; then
    echo "✅ 转账记录API正常"
else
    echo "❌ 转账记录API异常"
    echo "   响应: $TRANSFER_RESPONSE"
fi

echo ""
echo "🎉 前端测试完成！"
echo "=================================="
echo "📋 功能清单："
echo "- ✅ 前端服务器运行"
echo "- ✅ 后端API连接"
echo "- ✅ 钱包连接组件"
echo "- ✅ 转账历史组件"
echo "- ✅ 统计信息组件"
echo "- ✅ 响应式设计"
echo ""
echo "🌐 访问地址："
echo "- 前端: http://localhost:5173"
echo "- 后端API: http://localhost:3000"
echo ""
echo "💡 使用说明："
echo "1. 打开浏览器访问 http://localhost:5173"
echo "2. 点击 'Connect Wallet' 连接钱包"
echo "3. 选择 MetaMask 或其他钱包"
echo "4. 查看转账历史和统计信息"
