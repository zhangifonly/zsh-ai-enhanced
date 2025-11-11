#!/bin/bash
# 最终集成测试 - 模拟真实用户使用场景

echo "=========================================="
echo "Claude Code AI Wrapper - 最终集成测试"
echo "=========================================="
echo ""

# 清理测试环境（不影响用户其他会话）
echo "1. 清理测试环境..."
pkill -9 -f "claude_code_wrapper_pty.py" 2>/dev/null
sleep 1
echo "   ✓ 测试环境已清理"
echo ""

# 检查配置
echo "2. 检查配置..."
if grep -q "alias claude='python3.*claude_code_wrapper_pty.py" ~/.izshrc; then
    echo "   ✓ ~/.izshrc 配置正确"
else
    echo "   ⚠️  ~/.izshrc 可能未配置 claude 别名"
fi
echo ""

# 测试启动流程
echo "3. 测试启动流程（5秒观察期）..."
echo "   - 观察右上角状态指示器"
echo "   - 应该看到: 🚀 启动中 → 🔄 初始化 → 🟢 监控中 → 🔵 等待任务"
echo "   - 等待输入提示符出现"
echo ""
echo "=========================================="
echo "开始运行 (5秒后自动终止)..."
echo "=========================================="
echo ""

# 实际用户场景：启用状态指示器
python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py /opt/homebrew/bin/claude &

WRAPPER_PID=$!

# 观察 5 秒
sleep 5

# 只清理测试启动的进程
kill -9 $WRAPPER_PID 2>/dev/null
# 杀掉测试 wrapper 的子进程
pkill -9 -P $WRAPPER_PID 2>/dev/null

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "✅ 期望结果："
echo "   1. 看到欢迎信息和状态指示器"
echo "   2. 右上角显示 🔵 等待任务"
echo "   3. 看到 '>' 提示符和 Claude Code 界面"
echo "   4. 能够输入任务（如果继续运行）"
echo ""
echo "❌ 如果失败："
echo "   - 检查 wrapper 文件路径"
echo "   - 检查 Python 3 是否安装"
echo "   - 检查 Claude Code 是否安装在 /opt/homebrew/bin/claude"
echo "   - 运行调试测试: ./test_wrapper_debug.sh"
echo ""
echo "📖 查看详细文档:"
echo "   - Wrapper工作流程说明.md"
echo "   - 完整版状态指示器说明.md"
echo ""
