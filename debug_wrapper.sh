#!/bin/bash

echo "=== 检查 iZsh 配置 ==="
echo "1. 检查别名配置："
~/.local/bin/izsh -c 'alias | grep claude-ai'

echo ""
echo "2. 检查环境变量："
~/.local/bin/izsh -c 'echo "IZSH_AI_CONFIRM_TIMEOUT=$IZSH_AI_CONFIRM_TIMEOUT"'

echo ""
echo "3. 测试 Python 包装器："
python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py --help 2>&1 | head -5

echo ""
echo "=== 使用说明 ==="
echo "请确保在 iZsh 中使用以下命令启动 Claude Code："
echo ""
echo "方法 1（推荐）："
echo "  claude-ai"
echo ""
echo "方法 2："
echo "  python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py claude-code"
echo ""
echo "如果您直接运行了 'claude-code'，包装器不会生效。"
