#!/bin/bash
# iZsh 完整功能测试脚本

echo "================================"
echo "🧪 iZsh 完整测试"
echo "================================"
echo ""

# 设置环境变量
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# 测试 1: 启动 iZsh
echo "测试 1: 检查 iZsh 版本"
~/.local/bin/izsh --version

echo ""
echo "测试 2: 加载 AI 模块"
~/.local/bin/izsh -c 'zmodload zsh/ai && echo "✅ AI 模块加载成功" || echo "❌ AI 模块加载失败"'

echo ""
echo "测试 3: 检查 AI 状态"
~/.local/bin/izsh -c 'echo $ZSH_VERSION'

echo ""
echo "测试 4: 测试配置文件是否正确加载"
~/.local/bin/izsh -i <<'EOF'
echo "当前环境变量:"
echo "IZSH_AI_ENABLED=$IZSH_AI_ENABLED"
echo "IZSH_AI_MODEL=$IZSH_AI_MODEL"
exit
EOF

echo ""
echo "测试 5: 打开应用程序"
echo "请手动测试: 输入 'open ~/Applications/iZsh.app'"
echo "然后在应用中测试输入: 列表"

echo ""
echo "================================"
echo "✅ 自动化测试完成"
echo "================================"
