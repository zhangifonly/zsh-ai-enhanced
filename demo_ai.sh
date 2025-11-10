#!/bin/bash
# iZsh AI 功能演示脚本

echo "════════════════════════════════════════"
echo "  🚀 iZsh AI 功能演示"
echo "════════════════════════════════════════"
echo ""

# 设置环境变量
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
export IZSH_AI_ENABLED=1
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="sk-RQxMGajqZMP6cqxZ4fI7D7fjWvMAm0ZfNUbJg4rzIeXa39SP"
export IZSH_AI_MODEL="claude-3-5-haiku-20241022"
export IZSH_AI_API_TYPE="anthropic"
export IZSH_AI_INTERVENTION_LEVEL="suggest"

echo "📋 配置信息:"
echo "   API: $IZSH_AI_API_URL"
echo "   模型: $IZSH_AI_MODEL"
echo "   API 类型: $IZSH_AI_API_TYPE"
echo ""

echo "════════════════════════════════════════"
echo "  测试 1: 简单问候"
echo "════════════════════════════════════════"
~/.local/bin/izsh -c 'zmodload zsh/ai && ai "Hi, introduce yourself briefly"' 2>&1 | grep -v "^\[AI Debug\]"
echo ""

echo "════════════════════════════════════════"
echo "  测试 2: 技术问题"
echo "════════════════════════════════════════"
~/.local/bin/izsh -c 'zmodload zsh/ai && ai "What is Git?"' 2>&1 | grep -v "^\[AI Debug\]"
echo ""

echo "════════════════════════════════════════"
echo "  测试 3: 命令帮助"
echo "════════════════════════════════════════"
~/.local/bin/izsh -c 'zmodload zsh/ai && ai "How do I list files in Linux?"' 2>&1 | grep -v "^\[AI Debug\]"
echo ""

echo "════════════════════════════════════════"
echo "  ✅ 演示完成！"
echo "════════════════════════════════════════"
echo ""
echo "💡 如何交互式使用："
echo "   1. 运行: ~/.local/bin/izsh"
echo "   2. 执行: zmodload zsh/ai"
echo "   3. 使用: ai \"你的问题\""
echo ""
echo "🔧 配置文件: ~/.izshrc"
echo "📖 帮助文档: ANTHROPIC_API_INTEGRATION.md"
echo ""
