#!/usr/bin/env zsh
# iZsh 路径记录功能 - 记住最近的工作目录

# 配置
RECENT_PATHS_FILE="${HOME}/.izsh/recent_paths"
MAX_PATHS=10  # 保存最近10个路径

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 初始化：创建目录
init_recent_paths() {
    local dir=$(dirname "$RECENT_PATHS_FILE")
    mkdir -p "$dir"
    touch "$RECENT_PATHS_FILE"
}

# 保存当前路径（退出时调用）
save_current_path() {
    init_recent_paths

    local current_path="$PWD"

    # 跳过 HOME 目录和不存在的目录
    if [[ "$current_path" == "$HOME" ]] || [[ ! -d "$current_path" ]]; then
        return 0
    fi

    # 读取现有路径
    local existing_paths=()
    if [[ -f "$RECENT_PATHS_FILE" ]]; then
        while IFS= read -r line; do
            existing_paths+=("$line")
        done < "$RECENT_PATHS_FILE"
    fi

    # 移除重复的路径（如果已存在，删除旧的）
    local new_paths=("$current_path")
    for path in "${existing_paths[@]}"; do
        if [[ "$path" != "$current_path" ]] && [[ -d "$path" ]]; then
            new_paths+=("$path")
        fi
    done

    # 限制保存的数量
    local save_count=0
    > "$RECENT_PATHS_FILE"  # 清空文件
    for path in "${new_paths[@]}"; do
        if [[ $save_count -lt $MAX_PATHS ]]; then
            echo "$path" >> "$RECENT_PATHS_FILE"
            ((save_count++))
        else
            break
        fi
    done
}

# 获取最近的路径
get_recent_path() {
    local index=${1:-0}  # 默认获取最近的第1个

    init_recent_paths

    if [[ ! -f "$RECENT_PATHS_FILE" ]]; then
        return 1
    fi

    local paths=()
    while IFS= read -r line; do
        if [[ -d "$line" ]]; then
            paths+=("$line")
        fi
    done < "$RECENT_PATHS_FILE"

    if [[ ${#paths[@]} -eq 0 ]]; then
        return 1
    fi

    if [[ $index -ge ${#paths[@]} ]]; then
        return 1
    fi

    echo "${paths[$index]}"
}

# 列出所有最近的路径
list_recent_paths() {
    init_recent_paths

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📁 最近访问的路径${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ! -f "$RECENT_PATHS_FILE" ]]; then
        echo -e "${YELLOW}暂无最近访问的路径记录${NC}"
        return 0
    fi

    local index=0
    local current_path="$PWD"

    while IFS= read -r path; do
        if [[ -d "$path" ]]; then
            local marker=""
            if [[ "$path" == "$current_path" ]]; then
                marker="${GREEN} ← 当前位置${NC}"
            fi

            # 显示相对于HOME的路径（更简洁）
            local display_path="$path"
            if [[ "$path" == "$HOME"* ]]; then
                display_path="~${path#$HOME}"
            fi

            echo -e "${BLUE}[$((index + 1))]${NC} $display_path$marker"
            ((index++))
        fi
    done < "$RECENT_PATHS_FILE"

    if [[ $index -eq 0 ]]; then
        echo -e "${YELLOW}暂无有效的路径记录${NC}"
    else
        echo ""
        echo -e "${YELLOW}使用方式：${NC}"
        echo -e "  ${GREEN}最近路径${NC}          # 回到最近的路径（第1个）"
        echo -e "  ${GREEN}最近路径 2${NC}        # 回到第2个最近的路径"
        echo -e "  ${GREEN}recent-path${NC}      # 同上"
        echo -e "  ${GREEN}recent-path list${NC} # 显示此列表"
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 主命令：切换到最近的路径
recent_path_command() {
    local action="$1"

    # 如果参数是 list 或 ls，显示列表
    if [[ "$action" == "list" ]] || [[ "$action" == "ls" ]] || [[ "$action" == "-l" ]]; then
        list_recent_paths
        return 0
    fi

    # 如果参数是数字，切换到第N个路径
    local index=0
    if [[ "$action" =~ ^[0-9]+$ ]]; then
        index=$((action - 1))  # 用户输入从1开始，索引从0开始
    fi

    # 获取路径
    local target_path=$(get_recent_path $index)

    if [[ -z "$target_path" ]]; then
        echo -e "${YELLOW}⚠️  没有找到最近的路径记录${NC}" >&2
        echo ""
        echo -e "${BLUE}提示：${NC}使用 ${GREEN}最近路径 list${NC} 查看所有记录" >&2
        return 1
    fi

    # 切换到目标路径
    if [[ -d "$target_path" ]]; then
        cd "$target_path" || return 1
        echo -e "${GREEN}✅ 已切换到：${NC}$target_path"

        # 显示目录内容
        echo ""
        ls -lh
    else
        echo -e "${YELLOW}⚠️  路径不存在：${NC}$target_path" >&2
        return 1
    fi
}

# 清理无效路径
clean_recent_paths() {
    init_recent_paths

    if [[ ! -f "$RECENT_PATHS_FILE" ]]; then
        return 0
    fi

    local valid_paths=()
    while IFS= read -r path; do
        if [[ -d "$path" ]]; then
            valid_paths+=("$path")
        fi
    done < "$RECENT_PATHS_FILE"

    # 重写文件
    > "$RECENT_PATHS_FILE"
    for path in "${valid_paths[@]}"; do
        echo "$path" >> "$RECENT_PATHS_FILE"
    done

    echo -e "${GREEN}✅ 已清理无效路径，保留 ${#valid_paths[@]} 条记录${NC}"
}

# 帮助信息
show_help() {
    cat << EOF
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${CYAN}📁 iZsh 路径记录功能${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${YELLOW}功能说明：${NC}
  自动记录每次关闭窗口时的路径，快速回到上次工作目录

${YELLOW}使用方式：${NC}
  ${GREEN}最近路径${NC}              # 回到最近的路径（第1个）
  ${GREEN}最近路径 2${NC}            # 回到第2个最近的路径
  ${GREEN}最近路径 list${NC}         # 显示所有最近的路径
  ${GREEN}recent-path${NC}          # 同 "最近路径"
  ${GREEN}recent-path list${NC}     # 同 "最近路径 list"
  ${GREEN}recent-path clean${NC}    # 清理无效路径

${YELLOW}别名：${NC}
  ${GREEN}rp${NC}                   # recent-path 的简写
  ${GREEN}rpl${NC}                  # recent-path list 的简写

${YELLOW}示例：${NC}
  # 在项目A工作后关闭窗口
  $ cd ~/projects/projectA
  $ exit

  # 重新打开窗口，在项目B工作
  $ cd ~/projects/projectB

  # 快速回到项目A
  $ 最近路径
  ✅ 已切换到：/Users/username/projects/projectA

${YELLOW}配置：${NC}
  记录文件：~/.izsh/recent_paths
  最大记录数：${MAX_PATHS} 条

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
EOF
}

# 如果直接运行脚本，解析参数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        save)
            save_current_path
            ;;
        list|ls)
            list_recent_paths
            ;;
        clean)
            clean_recent_paths
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            recent_path_command "$@"
            ;;
    esac
fi
