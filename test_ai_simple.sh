#!/bin/bash
# 简单的 AI 功能测试

echo "🚀 测试 iZsh AI 功能..."
echo ""

# 设置环境变量
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib

# 测试 AI 命令
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "提问: What is Git?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

~/.local/bin/izsh -c 'zmodload zsh/ai && ai "What is Git?"' 2>&1 | grep -A 20 "🤖"

echo ""
echo "✅ 测试完成！"
echo ""
echo "💡 如需交互式使用，请运行："
echo "   ./start_izsh.sh"
