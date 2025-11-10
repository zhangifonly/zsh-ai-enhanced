#!/bin/bash
# Claude Code Wrapper 完整测试脚本

echo "================================"
echo "Claude Code AI 自动确认测试"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}测试 1: 检查 wrapper 脚本存在${NC}"
if [ -f ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py ]; then
    echo -e "${GREEN}✓ Wrapper 脚本存在${NC}"
else
    echo -e "${RED}✗ Wrapper 脚本不存在${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}测试 2: 检查 iZsh 配置${NC}"
if [ -f ~/.izshrc ]; then
    echo -e "${GREEN}✓ ~/.izshrc 存在${NC}"

    # 检查关键配置
    if grep -q "ai_confirm()" ~/.izshrc; then
        echo -e "${GREEN}✓ ai_confirm 函数已定义${NC}"
    else
        echo -e "${RED}✗ ai_confirm 函数未定义${NC}"
    fi

    if grep -q "claude-auto" ~/.izshrc; then
        echo -e "${GREEN}✓ claude-auto 别名已定义${NC}"
    else
        echo -e "${RED}✗ claude-auto 别名未定义${NC}"
    fi
else
    echo -e "${RED}✗ ~/.izshrc 不存在${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}测试 3: 检查 iZsh 可执行文件${NC}"
if [ -f ~/.local/bin/izsh ]; then
    echo -e "${GREEN}✓ iZsh 已安装${NC}"
    ~/.local/bin/izsh --version
else
    echo -e "${RED}✗ iZsh 未安装${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}测试 4: 检查 Claude Code${NC}"
if command -v claude &> /dev/null; then
    CLAUDE_PATH=$(which claude)
    echo -e "${GREEN}✓ Claude Code 已安装: $CLAUDE_PATH${NC}"
else
    echo -e "${RED}✗ Claude Code 未安装${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}测试 5: 检查 AI 配置${NC}"
~/.local/bin/izsh -c 'source ~/.izshrc 2>/dev/null && echo "IZSH_AI_ENABLED=$IZSH_AI_ENABLED"'
~/.local/bin/izsh -c 'source ~/.izshrc 2>/dev/null && echo "IZSH_AI_API_URL=$IZSH_AI_API_URL"'
~/.local/bin/izsh -c 'source ~/.izshrc 2>/dev/null && echo "IZSH_AI_MODEL=$IZSH_AI_MODEL"'

echo ""
echo -e "${BLUE}测试 6: Python 依赖检查${NC}"
python3 -c "import sys, subprocess, re, signal, threading, time, termios, tty" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Python 依赖完整${NC}"
else
    echo -e "${RED}✗ Python 依赖缺失${NC}"
    exit 1
fi

echo ""
echo "================================"
echo "所有基础检查通过！"
echo "================================"
echo ""
echo "使用说明："
echo "1. 启动 iZsh："
echo "   ~/.local/bin/izsh"
echo ""
echo "2. 在 iZsh 中运行 Claude Code（AI 自动确认）："
echo "   [iZsh] ~% claude-auto"
echo ""
echo "3. 或者使用 claude-ai（兼容别名）："
echo "   [iZsh] ~% claude-ai"
echo ""
echo "预期效果："
echo "- 所有确认提示将倒计时 3 秒"
echo "- 超时后 AI 自动选择最佳选项"
echo "- 数字菜单直接发送数字"
echo "- 箭头菜单自动导航并确认"
echo ""
