#!/bin/bash
# AI 专家自动加载钩子
# 在用户执行命令时自动检测并加载对应的AI专家提示词

# 配置
EXPERTS_DIR="${HOME}/.izsh/ai_experts"
EXPERTS_CONFIG="${EXPERTS_DIR}/experts.json"
CURRENT_EXPERT_FILE="/tmp/.izsh_current_expert_$$"

# 查找匹配的专家ID
find_expert_for_command() {
    local cmd="$1"

    # 检查配置文件是否存在
    if [[ ! -f "$EXPERTS_CONFIG" ]]; then
        return 1
    fi

    # 使用 Python 查找匹配的专家
    python3 -c "
import json
import sys
import re

try:
    with open('$EXPERTS_CONFIG') as f:
        config = json.load(f)

    cmd = '''$cmd'''
    matched_experts = []

    for expert_id, expert in config.get('experts', {}).items():
        # 跳过禁用的专家
        if not expert.get('enabled', True):
            continue
        if not expert.get('auto_load', True):
            continue

        priority = expert.get('priority', 0)

        # 检查正则模式匹配
        for pattern in expert.get('patterns', []):
            try:
                if re.match(pattern, cmd):
                    matched_experts.append((priority, expert_id))
                    break
            except:
                pass

        # 检查命令名称匹配
        for command in expert.get('commands', []):
            # 支持通配符
            if command.endswith('*'):
                prefix = command[:-1]
                if cmd.startswith(prefix):
                    matched_experts.append((priority, expert_id))
                    break
            else:
                # 精确匹配命令名（命令后面可以跟参数）
                if cmd == command or cmd.startswith(command + ' '):
                    matched_experts.append((priority, expert_id))
                    break

    # 按优先级排序，返回最高优先级的专家
    if matched_experts:
        matched_experts.sort(reverse=True)
        print(matched_experts[0][1])
        sys.exit(0)
    else:
        sys.exit(1)

except Exception as e:
    sys.exit(1)
" 2>/dev/null
}

# 获取专家名称
get_expert_name() {
    local expert_id="$1"

    python3 -c "
import json
try:
    with open('$EXPERTS_CONFIG') as f:
        config = json.load(f)
    print(config['experts']['$expert_id']['name'])
except:
    print('$expert_id')
" 2>/dev/null
}

# 加载专家提示词
load_expert_prompt() {
    local expert_id="$1"

    # 查找提示词文件
    local prompt_file="${EXPERTS_DIR}/templates/${expert_id}.prompt"
    if [[ ! -f "$prompt_file" ]]; then
        # 尝试 custom 目录
        prompt_file="${EXPERTS_DIR}/custom/${expert_id}.prompt"
    fi

    if [[ ! -f "$prompt_file" ]]; then
        return 1
    fi

    # 读取提示词内容
    cat "$prompt_file"
    return 0
}

# 主函数：自动加载专家
auto_load_ai_expert() {
    local cmd="$1"

    # 如果命令为空，跳过
    if [[ -z "$cmd" ]]; then
        return 0
    fi

    # 提取命令名称（去除路径和参数）
    local cmd_name=$(echo "$cmd" | awk '{print $1}' | xargs basename)

    # 查找匹配的专家
    local expert_id=$(find_expert_for_command "$cmd_name")

    if [[ -n "$expert_id" ]]; then
        # 加载专家提示词
        local prompt_content=$(load_expert_prompt "$expert_id")

        if [[ -n "$prompt_content" ]]; then
            # 保存当前专家信息
            echo "$expert_id" > "$CURRENT_EXPERT_FILE"

            # 导出专家提示词到环境变量
            export IZSH_CURRENT_EXPERT="$expert_id"
            export IZSH_EXPERT_PROMPT="$prompt_content"

            # 显示欢迎消息（默认关闭，可通过 IZSH_SHOW_EXPERT_WELCOME=true 启用）
            if [[ "$IZSH_SHOW_EXPERT_WELCOME" == "true" ]]; then
                local expert_name=$(get_expert_name "$expert_id")
                echo -e "\033[36m🤖 已加载 AI 专家: $expert_name\033[0m" >&2
                echo -e "\033[33m💡 提示: 您可以使用 'ai-expert view $expert_id' 查看专家提示词\033[0m" >&2
            fi
        fi
    else
        # 清除之前的专家上下文
        unset IZSH_CURRENT_EXPERT
        unset IZSH_EXPERT_PROMPT
        rm -f "$CURRENT_EXPERT_FILE" 2>/dev/null
    fi
}

# 清理函数：命令执行后清除专家上下文（可选）
clear_expert_context() {
    # 如果设置了保持专家上下文，不清除
    if [[ "$IZSH_KEEP_EXPERT_CONTEXT" == "true" ]]; then
        return 0
    fi

    unset IZSH_CURRENT_EXPERT
    unset IZSH_EXPERT_PROMPT
    rm -f "$CURRENT_EXPERT_FILE" 2>/dev/null
}

# 获取当前加载的专家
get_current_expert() {
    if [[ -f "$CURRENT_EXPERT_FILE" ]]; then
        cat "$CURRENT_EXPERT_FILE"
    elif [[ -n "$IZSH_CURRENT_EXPERT" ]]; then
        echo "$IZSH_CURRENT_EXPERT"
    fi
}

# AI 建议函数增强版（包含专家提示词）
ai_suggest_with_expert() {
    local query="$*"

    # 如果有加载的专家，将提示词作为上下文
    if [[ -n "$IZSH_EXPERT_PROMPT" ]]; then
        local expert_name=$(get_expert_name "$IZSH_CURRENT_EXPERT")
        local enhanced_query="作为 ${expert_name}，请回答以下问题：

【专家上下文】
$IZSH_EXPERT_PROMPT

【用户问题】
$query"

        # 调用原始 ai_suggest 函数
        ai_suggest "$enhanced_query"
    else
        # 没有专家上下文，直接调用
        ai_suggest "$query"
    fi
}

# 别名函数
alias ask-expert='ai_suggest_with_expert'

# 如果作为独立脚本运行，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "测试 AI 专家自动加载..."
    echo ""

    echo "测试命令: git status"
    auto_load_ai_expert "git status"
    echo "当前专家: $(get_current_expert)"
    echo ""

    echo "测试命令: docker ps"
    auto_load_ai_expert "docker ps"
    echo "当前专家: $(get_current_expert)"
    echo ""

    echo "测试命令: python"
    auto_load_ai_expert "python"
    echo "当前专家: $(get_current_expert)"
    echo ""

    echo "测试命令: vim test.txt"
    auto_load_ai_expert "vim test.txt"
    echo "当前专家: $(get_current_expert)"
    echo ""

    echo "测试完成！"
fi
