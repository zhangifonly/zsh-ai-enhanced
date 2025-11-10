#!/bin/bash
# iZsh 快速启动脚本

echo "════════════════════════════════════════"
echo "  🌟 启动 iZsh - 智能终端"
echo "════════════════════════════════════════"
echo ""
echo "📌 使用方法："
echo "   1. 加载 AI 模块: zmodload zsh/ai"
echo "   2. 使用 AI 助手: ai \"你的问题\""
echo ""
echo "💡 示例命令："
echo "   ai \"如何查找大文件？\""
echo "   ai \"What is Docker?\""
echo "   ai \"帮我写一个排序算法\""
echo ""
echo "════════════════════════════════════════"
echo ""

# 设置必需的环境变量
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib

# 修复 macOS fork 安全问题
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# 启动 iZsh
exec ~/.local/bin/izsh
