#!/bin/bash
# iZsh 日志系统安装脚本

echo "🚀 安装 iZsh 日志系统"
echo ""

# 创建目录
echo "📁 创建目录..."
mkdir -p ~/.izsh
mkdir -p ~/.izsh/logs

# 复制日志脚本
echo "📋 复制日志脚本..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/logging.sh" ~/.izsh/

# 检查 .izshrc 是否存在
if [ ! -f ~/.izshrc ]; then
    echo "⚠️  警告: ~/.izshrc 不存在"
    echo "   请确保已安装 iZsh"
    exit 1
fi

# 检查是否已经加载日志系统
if grep -q "source ~/.izsh/logging.sh" ~/.izshrc 2>/dev/null; then
    echo "✅ 日志系统已经集成到 ~/.izshrc"
else
    echo "📝 在 ~/.izshrc 中添加日志系统加载代码..."

    # 在文件开头添加日志系统加载（在第一个 setopt 之后）
    sed -i.bak '/^setopt no_global_rcs/a\
\
# ==========================================\
# 日志系统（优先加载）\
# ==========================================\
\
# 加载日志系统\
if [[ -f ~/.izsh/logging.sh ]]; then\
    source ~/.izsh/logging.sh\
else\
    # 如果日志系统不存在，提供占位函数\
    izsh_log_startup() { : }\
    izsh_log_ai() { : }\
    izsh_log_cmd() { : }\
    izsh_log_error() { : }\
    izsh_log_debug() { : }\
    izsh_log_perf() { : }\
fi\
' ~/.izshrc

    echo "✅ 已添加日志系统到 ~/.izshrc"
    echo "   备份文件：~/.izshrc.bak"
fi

# 显示安装信息
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ iZsh 日志系统安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 安装位置："
echo "   日志脚本: ~/.izsh/logging.sh"
echo "   日志目录: ~/.izsh/logs/"
echo ""
echo "🎯 快速使用："
echo "   izsh-logs           - 查看所有日志"
echo "   izsh-logs error     - 查看错误日志"
echo "   izsh-logs ai        - 查看AI日志"
echo "   izsh-logs-stat      - 查看日志统计"
echo "   izsh-logs-clean     - 清理日志"
echo ""
echo "📖 详细文档："
echo "   cat $SCRIPT_DIR/LOG_USAGE.md"
echo ""
echo "🔄 重新加载 iZsh 以应用更改："
echo "   exec ~/.local/bin/izsh"
echo ""
