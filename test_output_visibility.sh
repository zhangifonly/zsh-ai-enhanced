#!/bin/bash
# 测试 Claude Code Wrapper 的输出可见性

echo "=========================================="
echo "测试 Claude Code 输出可见性"
echo "=========================================="
echo ""

# 清理测试环境（不影响其他会话）
pkill -9 -f "claude_code_wrapper_pty.py" 2>/dev/null
sleep 1

echo "1. 测试原生 Claude Code（对照组）"
echo "   提示：按 Ctrl+C 退出"
echo "=========================================="
echo ""

# 启动原生 Claude Code 5秒
/opt/homebrew/bin/claude &
CLAUDE_PID=$!

sleep 5
# 只杀掉测试启动的这个进程
kill -9 $CLAUDE_PID 2>/dev/null

echo ""
echo "=========================================="
echo ""

echo "2. 测试 Wrapper（禁用状态指示器）"
echo "   提示：按 Ctrl+C 退出"
echo "=========================================="
echo ""

IZSH_SHOW_INDICATOR=0 \
    python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py /opt/homebrew/bin/claude &

WRAPPER_PID=$!

sleep 5
# 只杀掉测试启动的进程及其子进程
kill -9 $WRAPPER_PID 2>/dev/null
pkill -9 -P $WRAPPER_PID 2>/dev/null

echo ""
echo "=========================================="
echo ""

echo "3. 测试 Wrapper（启用状态指示器）"
echo "   提示：按 Ctrl+C 退出"
echo "=========================================="
echo ""

python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py /opt/homebrew/bin/claude &

WRAPPER_PID=$!

sleep 5
# 只杀掉测试启动的进程及其子进程
kill -9 $WRAPPER_PID 2>/dev/null
pkill -9 -P $WRAPPER_PID 2>/dev/null

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""

echo "✅ 检查项："
echo "   1. 原生 Claude Code 是否显示欢迎界面？"
echo "   2. Wrapper（禁用指示器）是否显示欢迎界面？"
echo "   3. Wrapper（启用指示器）是否显示欢迎界面？"
echo ""
echo "❌ 如果看不到输出："
echo "   - 检查终端是否支持 ANSI 转义序列"
echo "   - 尝试在真正的 TTY 中运行（不是在 IDE 终端）"
echo "   - 运行：script -q /dev/null claude"
echo ""
