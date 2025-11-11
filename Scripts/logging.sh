#!/bin/zsh
# iZsh 日志系统
# 提供全面的日志记录功能，方便问题诊断

# ==========================================
# 日志配置
# ==========================================

# 日志目录
export IZSH_LOG_DIR="${HOME}/.izsh/logs"

# 日志文件
export IZSH_LOG_STARTUP="${IZSH_LOG_DIR}/startup.log"
export IZSH_LOG_AI="${IZSH_LOG_DIR}/ai.log"
export IZSH_LOG_COMMAND="${IZSH_LOG_DIR}/command.log"
export IZSH_LOG_ERROR="${IZSH_LOG_DIR}/error.log"
export IZSH_LOG_DEBUG="${IZSH_LOG_DIR}/debug.log"
export IZSH_LOG_PERF="${IZSH_LOG_DIR}/performance.log"

# 日志级别
export IZSH_LOG_LEVEL="${IZSH_LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR

# 是否启用日志（默认启用）
export IZSH_LOGGING_ENABLED="${IZSH_LOGGING_ENABLED:-1}"

# 单个日志文件最大大小（字节，默认10MB）
export IZSH_LOG_MAX_SIZE="${IZSH_LOG_MAX_SIZE:-10485760}"

# ==========================================
# 日志初始化
# ==========================================

# 创建日志目录
izsh_log_init() {
    if [[ ! -d "$IZSH_LOG_DIR" ]]; then
        mkdir -p "$IZSH_LOG_DIR" 2>/dev/null || {
            echo "警告: 无法创建日志目录 $IZSH_LOG_DIR" >&2
            export IZSH_LOGGING_ENABLED=0
            return 1
        }
    fi

    # 确保日志文件存在
    touch "$IZSH_LOG_STARTUP" "$IZSH_LOG_AI" "$IZSH_LOG_COMMAND" \
          "$IZSH_LOG_ERROR" "$IZSH_LOG_DEBUG" "$IZSH_LOG_PERF" 2>/dev/null

    return 0
}

# ==========================================
# 日志轮转
# ==========================================

# 检查日志文件大小并轮转
izsh_log_rotate() {
    local log_file="$1"

    if [[ ! -f "$log_file" ]]; then
        return 0
    fi

    # 获取文件大小
    local file_size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)

    # 如果超过最大大小，进行轮转
    if [[ $file_size -gt $IZSH_LOG_MAX_SIZE ]]; then
        # 保留最近的一半内容
        local half_size=$((IZSH_LOG_MAX_SIZE / 2))
        tail -c $half_size "$log_file" > "${log_file}.tmp" 2>/dev/null
        mv "${log_file}.tmp" "$log_file" 2>/dev/null
    fi
}

# ==========================================
# 核心日志函数
# ==========================================

# 通用日志函数
# 用法：izsh_log LEVEL LOG_FILE MESSAGE
izsh_log() {
    # 检查是否启用日志
    if [[ "$IZSH_LOGGING_ENABLED" != "1" ]]; then
        return 0
    fi

    local level="$1"
    local log_file="$2"
    shift 2
    local message="$@"

    # 检查日志级别
    local level_num=0
    case "$level" in
        DEBUG) level_num=0 ;;
        INFO)  level_num=1 ;;
        WARN)  level_num=2 ;;
        ERROR) level_num=3 ;;
        *) level_num=1 ;;
    esac

    local config_level_num=1
    case "$IZSH_LOG_LEVEL" in
        DEBUG) config_level_num=0 ;;
        INFO)  config_level_num=1 ;;
        WARN)  config_level_num=2 ;;
        ERROR) config_level_num=3 ;;
    esac

    # 如果日志级别不够，跳过
    if [[ $level_num -lt $config_level_num ]]; then
        return 0
    fi

    # 轮转日志
    izsh_log_rotate "$log_file"

    # 写入日志
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null
}

# ==========================================
# 专用日志函数
# ==========================================

# 启动日志
izsh_log_startup() {
    izsh_log "INFO" "$IZSH_LOG_STARTUP" "$@"
}

# AI 调用日志
izsh_log_ai() {
    izsh_log "INFO" "$IZSH_LOG_AI" "$@"
}

# 命令执行日志
izsh_log_cmd() {
    izsh_log "INFO" "$IZSH_LOG_COMMAND" "$@"
}

# 错误日志
izsh_log_error() {
    izsh_log "ERROR" "$IZSH_LOG_ERROR" "$@"
}

# 调试日志
izsh_log_debug() {
    izsh_log "DEBUG" "$IZSH_LOG_DEBUG" "$@"
}

# 性能日志
izsh_log_perf() {
    local operation="$1"
    local duration="$2"
    izsh_log "INFO" "$IZSH_LOG_PERF" "$operation: ${duration}ms"
}

# ==========================================
# 日志查看命令
# ==========================================

# 查看日志
# 用法：izsh-logs [类型] [行数]
# 类型：startup, ai, command, error, debug, perf, all
izsh-logs() {
    local log_type="${1:-all}"
    local lines="${2:-50}"

    case "$log_type" in
        startup)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 启动日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_STARTUP" 2>/dev/null || echo "无日志"
            ;;
        ai)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🤖 AI 调用日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_AI" 2>/dev/null || echo "无日志"
            ;;
        command|cmd)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⚙️  命令执行日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_COMMAND" 2>/dev/null || echo "无日志"
            ;;
        error|err)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "❌ 错误日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_ERROR" 2>/dev/null || echo "无日志"
            ;;
        debug)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🐛 调试日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_DEBUG" 2>/dev/null || echo "无日志"
            ;;
        perf|performance)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⚡ 性能日志 (最近 $lines 行)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n "$lines" "$IZSH_LOG_PERF" 2>/dev/null || echo "无日志"
            ;;
        all)
            izsh-logs startup "$lines"
            echo ""
            izsh-logs ai "$lines"
            echo ""
            izsh-logs command "$lines"
            echo ""
            izsh-logs error "$lines"
            echo ""
            izsh-logs perf "$lines"
            ;;
        *)
            echo "用法: izsh-logs [类型] [行数]"
            echo ""
            echo "可用类型："
            echo "  startup  - 启动日志"
            echo "  ai       - AI 调用日志"
            echo "  command  - 命令执行日志"
            echo "  error    - 错误日志"
            echo "  debug    - 调试日志"
            echo "  perf     - 性能日志"
            echo "  all      - 所有日志 (默认)"
            echo ""
            echo "示例："
            echo "  izsh-logs              # 查看所有类型日志（最近50行）"
            echo "  izsh-logs error        # 查看错误日志"
            echo "  izsh-logs ai 100       # 查看AI日志（最近100行）"
            ;;
    esac
}

# 清理日志
izsh-logs-clean() {
    local confirm="${1}"

    if [[ "$confirm" != "-f" && "$confirm" != "--force" ]]; then
        echo "⚠️  即将清理所有 iZsh 日志文件"
        echo -n "确认继续? [y/N] "
        read -r response
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            echo "❌ 已取消"
            return 1
        fi
    fi

    echo "🧹 清理日志文件..."

    > "$IZSH_LOG_STARTUP"
    > "$IZSH_LOG_AI"
    > "$IZSH_LOG_COMMAND"
    > "$IZSH_LOG_ERROR"
    > "$IZSH_LOG_DEBUG"
    > "$IZSH_LOG_PERF"

    echo "✅ 日志已清理"
}

# 查看日志统计
izsh-logs-stat() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 iZsh 日志统计"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local total_size=0

    for log_file in "$IZSH_LOG_STARTUP" "$IZSH_LOG_AI" "$IZSH_LOG_COMMAND" \
                     "$IZSH_LOG_ERROR" "$IZSH_LOG_DEBUG" "$IZSH_LOG_PERF"; do
        if [[ -f "$log_file" ]]; then
            local size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)
            local size_kb=$((size / 1024))
            local lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)
            local name=$(basename "$log_file" .log)

            printf "%-15s: %6d 行, %6d KB\n" "$name" "$lines" "$size_kb"
            total_size=$((total_size + size))
        fi
    done

    echo ""
    local total_kb=$((total_size / 1024))
    echo "总大小: ${total_kb} KB"
    echo ""
    echo "日志目录: $IZSH_LOG_DIR"
    echo "日志状态: $([ "$IZSH_LOGGING_ENABLED" = "1" ] && echo "✅ 已启用" || echo "❌ 已禁用")"
    echo "日志级别: $IZSH_LOG_LEVEL"
}

# 实时监控日志
izsh-logs-tail() {
    local log_type="${1:-all}"

    case "$log_type" in
        startup) tail -f "$IZSH_LOG_STARTUP" ;;
        ai) tail -f "$IZSH_LOG_AI" ;;
        command|cmd) tail -f "$IZSH_LOG_COMMAND" ;;
        error|err) tail -f "$IZSH_LOG_ERROR" ;;
        debug) tail -f "$IZSH_LOG_DEBUG" ;;
        perf|performance) tail -f "$IZSH_LOG_PERF" ;;
        all)
            echo "实时监控所有日志 (Ctrl+C 退出)..."
            tail -f "$IZSH_LOG_STARTUP" "$IZSH_LOG_AI" "$IZSH_LOG_COMMAND" \
                     "$IZSH_LOG_ERROR" "$IZSH_LOG_DEBUG" "$IZSH_LOG_PERF"
            ;;
        *)
            echo "用法: izsh-logs-tail [类型]"
            echo "类型: startup, ai, command, error, debug, perf, all"
            ;;
    esac
}

# ==========================================
# 初始化日志系统
# ==========================================

# 启动时初始化
izsh_log_init

# 记录启动事件
izsh_log_startup "========== iZsh 启动 =========="
izsh_log_startup "版本: ${ZSH_VERSION:-未知}"
izsh_log_startup "用户: ${USER}@${HOST}"
izsh_log_startup "工作目录: ${PWD}"
izsh_log_startup "日志级别: ${IZSH_LOG_LEVEL}"
