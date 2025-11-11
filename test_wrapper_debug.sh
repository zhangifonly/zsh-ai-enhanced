#!/bin/bash
# Claude Code Wrapper 调试测试脚本

echo "=========================================="
echo "Claude Code Wrapper 调试测试"
echo "=========================================="
echo ""

# 1. 检查必要文件
echo "1. 检查文件存在性..."
echo "   - Wrapper: $(ls -la ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py 2>/dev/null | awk '{print $NF}')"
echo "   - Claude: $(which claude)"
echo ""

# 2. 检查进程
echo "2. 清理旧进程..."
pkill -9 -f claude_code_wrapper_pty.py 2>/dev/null
pkill -9 claude 2>/dev/null
echo "   ✓ 已清理旧进程"
echo ""

# 3. 测试 Claude Code 原生命令
echo "3. 测试 Claude Code 原生启动..."
/opt/homebrew/bin/claude --version 2>&1 | head -1
echo "   ✓ Claude Code 可以正常启动"
echo ""

# 4. 测试 wrapper (调试模式)
echo "4. 测试 Wrapper (调试模式 + 禁用指示器)..."
echo "   提示：观察调试输出，按 Ctrl+C 退出"
echo ""
echo "=========================================="
echo "开始调试运行（10秒后自动超时）..."
echo "=========================================="
echo ""

# 使用 timeout 限制运行时间
IZSH_DEBUG_MODE=1 IZSH_SHOW_INDICATOR=0 \
    python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py /opt/homebrew/bin/claude &

WRAPPER_PID=$!

# 等待最多 10 秒
for i in {1..10}; do
    sleep 1
    if ! kill -0 $WRAPPER_PID 2>/dev/null; then
        echo ""
        echo "=========================================="
        echo "Wrapper 已退出"
        echo "=========================================="
        break
    fi

    if [ $i -eq 5 ]; then
        echo ""
        echo "[5秒检查点] Wrapper 仍在运行..."
        echo ""
    fi

    if [ $i -eq 10 ]; then
        echo ""
        echo "=========================================="
        echo "[10秒超时] 强制终止..."
        echo "=========================================="
        kill -9 $WRAPPER_PID 2>/dev/null
        pkill -9 -f claude_code_wrapper_pty.py 2>/dev/null
        pkill -9 claude 2>/dev/null
    fi
done

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "诊断建议："
echo "- 如果看到'[DEBUG] Entering main loop...'，说明 PTY 创建成功"
echo "- 如果看到'[DEBUG] Received X bytes from child'，说明 Claude Code 有输出"
echo "- 如果卡在'Entering main loop'后，检查 Claude Code 是否在等待输入"
echo "- 如果完全没有调试输出，检查 Python 环境和权限"
echo ""
