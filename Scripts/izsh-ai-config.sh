#!/bin/bash
# iZsh AI 配置工具
# 用于配置 AI 功能的各项参数

# 配置文件路径
CONFIG_FILE="$HOME/.izsh_ai_config"
IZSHRC="$HOME/.izshrc"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 加载现有配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# iZsh AI 配置文件
# 由 izsh-ai-config 自动生成于 $(date)

# AI 功能开关
export IZSH_AI_ENABLED=$IZSH_AI_ENABLED

# AI 提供商
export IZSH_AI_PROVIDER="$IZSH_AI_PROVIDER"

# API 配置
export IZSH_AI_API_KEY="$IZSH_AI_API_KEY"
export IZSH_AI_API_URL="$IZSH_AI_API_URL"
export IZSH_AI_MODEL="$IZSH_AI_MODEL"

# 干预级别
export IZSH_AI_INTERVENTION_LEVEL="$IZSH_AI_INTERVENTION_LEVEL"

# 缓存配置
export IZSH_AI_CACHE_ENABLED=$IZSH_AI_CACHE_ENABLED
export IZSH_AI_CACHE_SIZE=$IZSH_AI_CACHE_SIZE

# 高级选项
export IZSH_AI_TIMEOUT=${IZSH_AI_TIMEOUT:-30}
export IZSH_AI_MAX_TOKENS=${IZSH_AI_MAX_TOKENS:-1000}
export IZSH_AI_TEMPERATURE=${IZSH_AI_TEMPERATURE:-0.7}
EOF
    print_success "配置已保存到 $CONFIG_FILE"
}

# 更新 .izshrc
update_izshrc() {
    # 检查是否已经加载配置
    if ! grep -q "source.*\.izsh_ai_config" "$IZSHRC" 2>/dev/null; then
        echo "" >> "$IZSHRC"
        echo "# 加载 AI 配置" >> "$IZSHRC"
        echo "[ -f ~/.izsh_ai_config ] && source ~/.izsh_ai_config" >> "$IZSHRC"
        print_success "已更新 $IZSHRC 以自动加载 AI 配置"
    fi
}

# 主菜单
main_menu() {
    clear
    print_header "iZsh AI 配置工具"
    echo ""
    echo "当前配置状态："
    echo "  AI 功能: ${IZSH_AI_ENABLED:-0} (0=关闭, 1=启用)"
    echo "  提供商: ${IZSH_AI_PROVIDER:-未设置}"
    echo "  模型: ${IZSH_AI_MODEL:-未设置}"
    echo "  干预级别: ${IZSH_AI_INTERVENTION_LEVEL:-suggest}"
    echo ""
    echo "选项："
    echo "  1) 启用/禁用 AI 功能"
    echo "  2) 选择 AI 提供商和模型"
    echo "  3) 配置 API 密钥"
    echo "  4) 设置干预级别"
    echo "  5) 高级选项"
    echo "  6) 查看完整配置"
    echo "  7) 测试配置"
    echo "  8) 保存并退出"
    echo "  9) 退出不保存"
    echo ""
    read -p "请选择 (1-9): " choice

    case $choice in
        1) toggle_ai ;;
        2) select_provider ;;
        3) config_api_key ;;
        4) set_intervention_level ;;
        5) advanced_options ;;
        6) view_config ;;
        7) test_config ;;
        8) save_and_exit ;;
        9) exit 0 ;;
        *) print_error "无效选项"; sleep 1; main_menu ;;
    esac
}

# 1. 启用/禁用 AI
toggle_ai() {
    clear
    print_header "AI 功能开关"
    echo ""
    echo "当前状态: ${IZSH_AI_ENABLED:-0}"
    echo ""
    echo "1) 启用 AI 功能"
    echo "2) 禁用 AI 功能"
    echo "3) 返回主菜单"
    echo ""
    read -p "请选择: " choice

    case $choice in
        1) IZSH_AI_ENABLED=1; print_success "AI 功能已启用" ;;
        2) IZSH_AI_ENABLED=0; print_success "AI 功能已禁用" ;;
        3) ;;
        *) print_error "无效选项" ;;
    esac

    sleep 1
    main_menu
}

# 2. 选择提供商
select_provider() {
    clear
    print_header "选择 AI 提供商"
    echo ""
    echo "支持的 AI 提供商："
    echo ""
    echo "1) OpenAI (GPT-3.5/GPT-4)"
    echo "   - 模型: gpt-3.5-turbo, gpt-4, gpt-4-turbo"
    echo "   - 需要: OpenAI API Key"
    echo ""
    echo "2) Anthropic Claude"
    echo "   - 模型: claude-3-opus, claude-3-sonnet, claude-3-haiku"
    echo "   - 需要: Anthropic API Key"
    echo ""
    echo "3) 本地模型 (Ollama)"
    echo "   - 模型: llama2, mistral, codellama"
    echo "   - 需要: 本地运行 Ollama"
    echo ""
    echo "4) Azure OpenAI"
    echo "   - 模型: 自定义部署"
    echo "   - 需要: Azure 订阅和 API Key"
    echo ""
    echo "5) 自定义 (兼容 OpenAI API)"
    echo "   - 支持任何兼容 OpenAI API 的服务"
    echo ""
    echo "6) 返回主菜单"
    echo ""
    read -p "请选择 (1-6): " choice

    case $choice in
        1) setup_openai ;;
        2) setup_claude ;;
        3) setup_ollama ;;
        4) setup_azure ;;
        5) setup_custom ;;
        6) main_menu ;;
        *) print_error "无效选项"; sleep 1; select_provider ;;
    esac
}

# 配置 OpenAI
setup_openai() {
    clear
    print_header "配置 OpenAI"
    echo ""
    IZSH_AI_PROVIDER="openai"
    IZSH_AI_API_URL="https://api.openai.com/v1"

    echo "选择模型："
    echo "1) gpt-3.5-turbo (快速, 便宜)"
    echo "2) gpt-4 (强大, 较贵)"
    echo "3) gpt-4-turbo (平衡)"
    echo "4) 自定义模型名称"
    echo ""
    read -p "请选择: " model_choice

    case $model_choice in
        1) IZSH_AI_MODEL="gpt-3.5-turbo" ;;
        2) IZSH_AI_MODEL="gpt-4" ;;
        3) IZSH_AI_MODEL="gpt-4-turbo" ;;
        4) read -p "输入模型名称: " IZSH_AI_MODEL ;;
        *) IZSH_AI_MODEL="gpt-3.5-turbo" ;;
    esac

    print_success "已选择: OpenAI - $IZSH_AI_MODEL"
    sleep 1
    main_menu
}

# 配置 Claude
setup_claude() {
    clear
    print_header "配置 Anthropic Claude"
    echo ""
    IZSH_AI_PROVIDER="claude"
    IZSH_AI_API_URL="https://api.anthropic.com/v1"

    echo "选择模型："
    echo "1) claude-3-haiku (最快)"
    echo "2) claude-3-sonnet (平衡)"
    echo "3) claude-3-opus (最强)"
    echo "4) claude-3-5-sonnet (最新)"
    echo ""
    read -p "请选择: " model_choice

    case $model_choice in
        1) IZSH_AI_MODEL="claude-3-haiku-20240307" ;;
        2) IZSH_AI_MODEL="claude-3-sonnet-20240229" ;;
        3) IZSH_AI_MODEL="claude-3-opus-20240229" ;;
        4) IZSH_AI_MODEL="claude-3-5-sonnet-20241022" ;;
        *) IZSH_AI_MODEL="claude-3-sonnet-20240229" ;;
    esac

    print_success "已选择: Claude - $IZSH_AI_MODEL"
    sleep 1
    main_menu
}

# 配置 Ollama
setup_ollama() {
    clear
    print_header "配置 Ollama (本地模型)"
    echo ""
    IZSH_AI_PROVIDER="ollama"
    IZSH_AI_API_URL="http://localhost:11434/api"

    echo "选择模型："
    echo "1) llama2"
    echo "2) mistral"
    echo "3) codellama"
    echo "4) qwen"
    echo "5) 自定义模型"
    echo ""
    read -p "请选择: " model_choice

    case $model_choice in
        1) IZSH_AI_MODEL="llama2" ;;
        2) IZSH_AI_MODEL="mistral" ;;
        3) IZSH_AI_MODEL="codellama" ;;
        4) IZSH_AI_MODEL="qwen" ;;
        5) read -p "输入模型名称: " IZSH_AI_MODEL ;;
        *) IZSH_AI_MODEL="llama2" ;;
    esac

    IZSH_AI_API_KEY="ollama-local"  # Ollama 不需要 API key

    print_success "已选择: Ollama - $IZSH_AI_MODEL"
    print_info "请确保 Ollama 已运行: ollama serve"
    sleep 2
    main_menu
}

# 配置 Azure
setup_azure() {
    clear
    print_header "配置 Azure OpenAI"
    echo ""
    IZSH_AI_PROVIDER="azure"

    read -p "输入 Azure 端点 URL: " IZSH_AI_API_URL
    read -p "输入部署名称: " IZSH_AI_MODEL

    print_success "已配置 Azure OpenAI"
    sleep 1
    main_menu
}

# 配置自定义
setup_custom() {
    clear
    print_header "配置自定义 API"
    echo ""
    IZSH_AI_PROVIDER="custom"

    read -p "输入 API URL: " IZSH_AI_API_URL
    read -p "输入模型名称: " IZSH_AI_MODEL

    print_success "已配置自定义 API"
    sleep 1
    main_menu
}

# 3. 配置 API Key
config_api_key() {
    clear
    print_header "配置 API 密钥"
    echo ""

    if [ -n "$IZSH_AI_PROVIDER" ]; then
        print_info "当前提供商: $IZSH_AI_PROVIDER"
    else
        print_warning "请先选择 AI 提供商"
        sleep 2
        main_menu
        return
    fi

    echo ""
    echo "当前 API 密钥: ${IZSH_AI_API_KEY:0:10}..."
    echo ""
    echo "1) 输入新的 API 密钥"
    echo "2) 从文件读取 API 密钥"
    echo "3) 返回主菜单"
    echo ""
    read -p "请选择: " choice

    case $choice in
        1)
            read -sp "输入 API 密钥 (输入时不显示): " IZSH_AI_API_KEY
            echo ""
            if [ -n "$IZSH_AI_API_KEY" ]; then
                print_success "API 密钥已设置"
            else
                print_error "API 密钥不能为空"
            fi
            ;;
        2)
            read -p "输入密钥文件路径: " key_file
            if [ -f "$key_file" ]; then
                IZSH_AI_API_KEY=$(cat "$key_file" | tr -d '\n')
                print_success "已从文件加载 API 密钥"
            else
                print_error "文件不存在"
            fi
            ;;
        3) ;;
    esac

    sleep 1
    main_menu
}

# 4. 设置干预级别
set_intervention_level() {
    clear
    print_header "设置干预级别"
    echo ""
    echo "AI 干预级别决定了 iZsh 如何处理错误命令："
    echo ""
    echo "1) off - 完全关闭自动纠错"
    echo "   - AI 不会主动介入"
    echo "   - 需要手动调用 ai 命令"
    echo ""
    echo "2) suggest - 建议模式 (推荐)"
    echo "   - AI 会提供建议"
    echo "   - 需要用户确认后执行"
    echo "   - 安全且可控"
    echo ""
    echo "3) auto - 自动模式"
    echo "   - AI 自动修正简单错误"
    echo "   - 复杂操作仍需确认"
    echo "   - 方便但需谨慎"
    echo ""
    echo "当前级别: ${IZSH_AI_INTERVENTION_LEVEL:-suggest}"
    echo ""
    read -p "请选择 (1-3): " choice

    case $choice in
        1) IZSH_AI_INTERVENTION_LEVEL="off" ;;
        2) IZSH_AI_INTERVENTION_LEVEL="suggest" ;;
        3) IZSH_AI_INTERVENTION_LEVEL="auto" ;;
        *) print_error "无效选项"; sleep 1; set_intervention_level; return ;;
    esac

    print_success "干预级别已设置为: $IZSH_AI_INTERVENTION_LEVEL"
    sleep 1
    main_menu
}

# 5. 高级选项
advanced_options() {
    clear
    print_header "高级选项"
    echo ""
    echo "1) 缓存设置"
    echo "   当前: $([ "$IZSH_AI_CACHE_ENABLED" = "1" ] && echo "已启用" || echo "已禁用")"
    echo "   缓存大小: ${IZSH_AI_CACHE_SIZE:-100}"
    echo ""
    echo "2) 超时设置 (当前: ${IZSH_AI_TIMEOUT:-30}秒)"
    echo "3) Token 限制 (当前: ${IZSH_AI_MAX_TOKENS:-1000})"
    echo "4) 温度参数 (当前: ${IZSH_AI_TEMPERATURE:-0.7})"
    echo "5) 返回主菜单"
    echo ""
    read -p "请选择: " choice

    case $choice in
        1) config_cache ;;
        2) read -p "输入超时时间(秒): " IZSH_AI_TIMEOUT ;;
        3) read -p "输入最大 tokens: " IZSH_AI_MAX_TOKENS ;;
        4) read -p "输入温度参数(0-1): " IZSH_AI_TEMPERATURE ;;
        5) main_menu; return ;;
    esac

    sleep 1
    advanced_options
}

# 配置缓存
config_cache() {
    clear
    print_header "缓存配置"
    echo ""
    echo "1) 启用缓存"
    echo "2) 禁用缓存"
    echo "3) 设置缓存大小 (当前: ${IZSH_AI_CACHE_SIZE:-100})"
    echo "4) 返回"
    echo ""
    read -p "请选择: " choice

    case $choice in
        1) IZSH_AI_CACHE_ENABLED=1; print_success "缓存已启用" ;;
        2) IZSH_AI_CACHE_ENABLED=0; print_success "缓存已禁用" ;;
        3) read -p "输入缓存大小: " IZSH_AI_CACHE_SIZE ;;
        4) ;;
    esac

    sleep 1
}

# 6. 查看配置
view_config() {
    clear
    print_header "当前完整配置"
    echo ""
    echo "基本设置:"
    echo "  AI 功能: ${IZSH_AI_ENABLED:-0}"
    echo "  提供商: ${IZSH_AI_PROVIDER:-未设置}"
    echo ""
    echo "API 配置:"
    echo "  API URL: ${IZSH_AI_API_URL:-未设置}"
    echo "  模型: ${IZSH_AI_MODEL:-未设置}"
    echo "  API 密钥: ${IZSH_AI_API_KEY:+已设置 (${#IZSH_AI_API_KEY} 字符)}"
    echo ""
    echo "行为设置:"
    echo "  干预级别: ${IZSH_AI_INTERVENTION_LEVEL:-suggest}"
    echo "  缓存: $([ "$IZSH_AI_CACHE_ENABLED" = "1" ] && echo "已启用" || echo "已禁用")"
    echo "  缓存大小: ${IZSH_AI_CACHE_SIZE:-100}"
    echo ""
    echo "高级选项:"
    echo "  超时: ${IZSH_AI_TIMEOUT:-30}秒"
    echo "  Max Tokens: ${IZSH_AI_MAX_TOKENS:-1000}"
    echo "  Temperature: ${IZSH_AI_TEMPERATURE:-0.7}"
    echo ""
    read -p "按回车返回主菜单..."
    main_menu
}

# 7. 测试配置
test_config() {
    clear
    print_header "测试配置"
    echo ""

    # 检查必需配置
    if [ "$IZSH_AI_ENABLED" != "1" ]; then
        print_error "AI 功能未启用"
    else
        print_success "AI 功能已启用"
    fi

    if [ -z "$IZSH_AI_PROVIDER" ]; then
        print_error "未选择 AI 提供商"
    else
        print_success "AI 提供商: $IZSH_AI_PROVIDER"
    fi

    if [ -z "$IZSH_AI_MODEL" ]; then
        print_error "未选择模型"
    else
        print_success "模型: $IZSH_AI_MODEL"
    fi

    if [ -z "$IZSH_AI_API_KEY" ] && [ "$IZSH_AI_PROVIDER" != "ollama" ]; then
        print_error "未配置 API 密钥"
    else
        print_success "API 密钥已配置"
    fi

    echo ""
    print_info "测试命令建议:"
    echo "  export 以上配置变量后运行:"
    echo "  izsh -c 'zmodload zsh/ai && ai \"测试问题\"'"
    echo ""

    read -p "按回车返回主菜单..."
    main_menu
}

# 8. 保存并退出
save_and_exit() {
    clear
    print_header "保存配置"
    echo ""

    save_config
    update_izshrc

    echo ""
    print_success "配置已保存！"
    echo ""
    print_info "下次启动 iZsh 时配置将自动生效"
    print_info "或者现在运行: source ~/.izsh_ai_config"
    echo ""
    exit 0
}

# 主程序入口
main() {
    # 加载现有配置
    load_config

    # 设置默认值
    IZSH_AI_ENABLED=${IZSH_AI_ENABLED:-0}
    IZSH_AI_INTERVENTION_LEVEL=${IZSH_AI_INTERVENTION_LEVEL:-suggest}
    IZSH_AI_CACHE_ENABLED=${IZSH_AI_CACHE_ENABLED:-1}
    IZSH_AI_CACHE_SIZE=${IZSH_AI_CACHE_SIZE:-100}

    # 显示主菜单
    main_menu
}

# 运行主程序
main
