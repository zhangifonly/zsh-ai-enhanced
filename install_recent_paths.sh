#!/bin/bash
# iZsh 路径记录功能 - 安装脚本

set -e

echo "=========================================="
echo "iZsh 路径记录功能 - 安装向导"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 源文件
SOURCE_SCRIPT="$HOME/Documents/ClaudeCode/zsh/zsh/recent_paths.sh"

# 目标位置
TARGET_DIR="$HOME/.izsh"
TARGET_SCRIPT="$TARGET_DIR/recent_paths.sh"
IZSHRC="$HOME/.izshrc"

# 检查源文件
echo -e "${BLUE}1. 检查源文件...${NC}"
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo -e "${RED}❌ 源文件不存在: $SOURCE_SCRIPT${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 源文件检查通过${NC}"
echo ""

# 创建目标目录
echo -e "${BLUE}2. 创建目标目录...${NC}"
mkdir -p "$TARGET_DIR"
echo -e "${GREEN}✅ 目录创建完成${NC}"
echo ""

# 复制脚本
echo -e "${BLUE}3. 安装脚本文件...${NC}"
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
echo -e "  ✓ recent_paths.sh -> $TARGET_SCRIPT"
echo -e "${GREEN}✅ 脚本安装完成${NC}"
echo ""

# 添加到 ~/.izshrc
echo -e "${BLUE}4. 配置 iZsh 集成...${NC}"

INTEGRATION_BLOCK="# iZsh 路径记录功能
if [ -f \"\$HOME/.izsh/recent_paths.sh\" ]; then
    source \"\$HOME/.izsh/recent_paths.sh\"

    # 注册 zshexit hook（退出时保存路径）
    zshexit() {
        save_current_path
    }

    # 命令别名
    alias 最近路径='recent_path_command'
    alias recent-path='recent_path_command'
    alias rp='recent_path_command'
    alias rpl='recent_path_command list'
fi"

if [ -f "$IZSHRC" ]; then
    if ! grep -q "iZsh 路径记录功能" "$IZSHRC"; then
        echo "" >> "$IZSHRC"
        echo "$INTEGRATION_BLOCK" >> "$IZSHRC"
        echo -e "  ✓ 集成配置已添加到 ~/.izshrc"
        echo -e "${GREEN}✅ iZsh 集成完成${NC}"
    else
        echo -e "  ${YELLOW}⚠️  集成配置已存在，跳过${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ~/.izshrc 不存在，请手动添加配置${NC}"
    echo ""
    echo "请手动添加以下内容到 ~/.izshrc："
    echo ""
    echo "$INTEGRATION_BLOCK"
fi
echo ""

# 显示安装摘要
echo -e "${GREEN}=========================================="
echo "✅ 安装完成！"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📁 安装位置：${NC}"
echo "  - 脚本文件: $TARGET_SCRIPT"
echo "  - 记录文件: ~/.izsh/recent_paths"
echo ""
echo -e "${CYAN}🎯 功能说明：${NC}"
echo "  ✅ 每次关闭 iZsh 窗口时自动记录当前路径"
echo "  ✅ 最多保存最近 10 个路径"
echo "  ✅ 自动跳过 HOME 目录和无效路径"
echo ""
echo -e "${BLUE}🚀 使用方式：${NC}"
echo ""
echo "  # 回到最近的路径"
echo -e "  ${GREEN}最近路径${NC}"
echo ""
echo "  # 回到第2个最近的路径"
echo -e "  ${GREEN}最近路径 2${NC}"
echo ""
echo "  # 查看所有最近的路径"
echo -e "  ${GREEN}最近路径 list${NC}"
echo -e "  ${GREEN}rpl${NC}              # 简写"
echo ""
echo "  # 使用英文命令"
echo -e "  ${GREEN}recent-path${NC}"
echo -e "  ${GREEN}rp${NC}               # 简写"
echo ""
echo -e "${BLUE}🔄 重新加载配置：${NC}"
echo -e "  ${GREEN}source ~/.izshrc${NC}"
echo ""
echo -e "${YELLOW}💡 提示：${NC}"
echo "  - 命令支持中文和英文"
echo "  - 路径自动去重，最近的总在前面"
echo "  - 使用 'rp list' 快速查看所有记录"
echo "  - 使用 'rp clean' 清理无效路径"
echo ""
echo -e "${CYAN}📖 查看帮助：${NC}"
echo -e "  ${GREEN}recent-path help${NC}"
echo ""
echo -e "${GREEN}开始使用路径记录功能！🎉${NC}"
echo ""
