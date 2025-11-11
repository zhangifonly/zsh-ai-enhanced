#!/bin/bash
# iZsh 日志系统功能测试

echo "🧪 测试 iZsh 日志系统"
echo ""

# 检查日志文件是否存在
echo "1️⃣ 检查日志文件..."
if [ -f ~/.izsh/logging.sh ]; then
    echo "   ✅ ~/.izsh/logging.sh 存在"
else
    echo "   ❌ ~/.izsh/logging.sh 不存在"
    echo "   请先运行: Scripts/install-logging.sh"
    exit 1
fi

# 加载日志系统
source ~/.izsh/logging.sh

# 检查日志目录
echo ""
echo "2️⃣ 检查日志目录..."
if [ -d "$IZSH_LOG_DIR" ]; then
    echo "   ✅ 日志目录: $IZSH_LOG_DIR"
    ls -lh "$IZSH_LOG_DIR" 2>/dev/null || echo "   📁 目录为空（首次使用）"
else
    echo "   ❌ 日志目录不存在"
    exit 1
fi

# 测试日志函数
echo ""
echo "3️⃣ 测试日志函数..."

izsh_log_startup "测试：启动日志"
echo "   ✅ izsh_log_startup"

izsh_log_ai "测试：AI调用日志"
echo "   ✅ izsh_log_ai"

izsh_log_cmd "测试：命令执行日志"
echo "   ✅ izsh_log_cmd"

izsh_log_error "测试：错误日志"
echo "   ✅ izsh_log_error"

izsh_log_debug "测试：调试日志"
echo "   ✅ izsh_log_debug"

izsh_log_perf "测试操作" "123"
echo "   ✅ izsh_log_perf"

# 检查日志内容
echo ""
echo "4️⃣ 验证日志内容..."

if grep -q "测试：启动日志" "$IZSH_LOG_STARTUP" 2>/dev/null; then
    echo "   ✅ startup.log 写入成功"
else
    echo "   ❌ startup.log 写入失败"
fi

if grep -q "测试：AI调用日志" "$IZSH_LOG_AI" 2>/dev/null; then
    echo "   ✅ ai.log 写入成功"
else
    echo "   ❌ ai.log 写入失败"
fi

if grep -q "测试：命令执行日志" "$IZSH_LOG_COMMAND" 2>/dev/null; then
    echo "   ✅ command.log 写入成功"
else
    echo "   ❌ command.log 写入失败"
fi

if grep -q "测试：错误日志" "$IZSH_LOG_ERROR" 2>/dev/null; then
    echo "   ✅ error.log 写入成功"
else
    echo "   ❌ error.log 写入失败"
fi

# 测试日志查看命令
echo ""
echo "5️⃣ 测试日志查看命令..."

echo "   查看启动日志（最近3行）："
izsh-logs startup 3 2>/dev/null | tail -3
echo ""

echo "   查看AI日志（最近3行）："
izsh-logs ai 3 2>/dev/null | tail -3
echo ""

# 测试日志统计
echo "6️⃣ 测试日志统计..."
izsh-logs-stat

# 完成
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 日志系统测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 后续操作："
echo "   - 查看日志: izsh-logs"
echo "   - 实时监控: izsh-logs-tail"
echo "   - 清理日志: izsh-logs-clean"
echo ""
