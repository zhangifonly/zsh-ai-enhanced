#!/bin/bash
# NewAPI 接口测试脚本

set -e

echo "=========================================="
echo "iZsh NewAPI 接口测试"
echo "=========================================="
echo ""

# 加载配置
if [ -f ~/.izshrc ]; then
    source ~/.izshrc
    echo "✅ 已加载 ~/.izshrc 配置"
else
    echo "❌ 找不到 ~/.izshrc 配置文件"
    exit 1
fi

echo ""
echo "📋 当前配置："
echo "   API URL: $IZSH_AI_API_URL"
echo "   API Key: ${IZSH_AI_API_KEY:0:20}..."
echo "   模型: $IZSH_AI_MODEL"
echo ""

# 测试 1: 查询模型列表
echo "=========================================="
echo "测试 1: 查询可用模型列表"
echo "=========================================="
curl -s "$IZSH_AI_API_URL/../models" \
  -H "Authorization: Bearer $IZSH_AI_API_KEY" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    models = data.get('data', [])
    print(f'✅ 找到 {len(models)} 个模型')
    for i, m in enumerate(models[:5], 1):
        print(f'   {i}. {m[\"id\"]}')
    if len(models) > 5:
        print(f'   ... 还有 {len(models)-5} 个模型')
except Exception as e:
    print(f'❌ 解析失败: {e}')
"
echo ""

# 测试 2: 检查 curl 命令
echo "=========================================="
echo "测试 2: 使用 curl 直接测试 API"
echo "=========================================="
echo "发送测试请求到模型: $IZSH_AI_MODEL"
echo ""

RESPONSE=$(curl -s -X POST "$IZSH_AI_API_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $IZSH_AI_API_KEY" \
  -d "{\"model\":\"$IZSH_AI_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":20}" \
  --max-time 15 2>&1)

echo "$RESPONSE" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    if 'error' in data:
        error = data['error']
        if isinstance(error, dict):
            print(f'❌ API 错误: {error.get(\"message\", error)}')
        else:
            print(f'❌ API 错误: {error}')
        print('')
        print('💡 可能的原因：')
        if '无权访问' in str(error) or '不支持' in str(error):
            print('   1. 令牌没有分配该模型的权限')
            print('   2. 请登录 https://q.quuvv.cn 后台配置令牌权限')
            print('   3. 或者更换其他有权限的模型')
    elif 'choices' in data:
        content = data['choices'][0]['message']['content']
        print(f'✅ API 调用成功!')
        print(f'   响应: {content}')
    else:
        print(f'⚠️  未知响应格式: {data}')
except json.JSONDecodeError:
    print(f'❌ JSON 解析失败')
    print(f'   原始响应: {sys.stdin.read()[:200]}')
except Exception as e:
    print(f'❌ 错误: {e}')
"
echo ""

# 测试 3: 测试 iZsh ai 命令
echo "=========================================="
echo "测试 3: 测试 iZsh AI 命令"
echo "=========================================="
echo "运行: izsh -c 'ai \"你好\"'"
echo ""

if [ -x ~/.local/bin/izsh ]; then
    ~/.local/bin/izsh -c 'ai "你好"' 2>&1 | head -30
else
    echo "❌ 找不到 izsh 可执行文件"
    echo "   请先运行: make install"
fi

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "📝 下一步操作："
echo ""
echo "如果看到'无权访问模型'错误，请："
echo "1. 访问 https://q.quuvv.cn"
echo "2. 登录管理后台"
echo "3. 找到令牌管理页面"
echo "4. 为令牌 sk-RQxM... 分配至少一个模型的权限"
echo "5. 推荐模型: claude-sonnet-4-5 或 gemini-2.5-pro"
echo ""
echo "配置完成后，可以直接使用："
echo "   izsh"
echo "   ai \"你的问题\""
echo ""
