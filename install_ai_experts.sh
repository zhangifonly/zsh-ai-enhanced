#!/bin/bash
# AI 命令专家系统 - 一键安装脚本

set -e

echo "=========================================="
echo "AI 命令专家系统 - 安装向导"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 源目录
SOURCE_DIR="$HOME/Documents/ClaudeCode/zsh/zsh/ai_experts"
PANEL_SCRIPT="$HOME/Documents/ClaudeCode/zsh/zsh/ai_expert_panel.py"
QUERY_SCRIPT="$HOME/Documents/ClaudeCode/zsh/zsh/ai_experts/web_query.py"
AUTO_LOAD_SCRIPT="$HOME/Documents/ClaudeCode/zsh/zsh/ai_experts/auto_load_expert.sh"

# 目标目录
TARGET_DIR="$HOME/.izsh/ai_experts"
BIN_DIR="/usr/local/bin"

# 检查源文件
echo -e "${BLUE}1. 检查源文件...${NC}"
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ 源目录不存在: $SOURCE_DIR${NC}"
    exit 1
fi

if [ ! -f "$PANEL_SCRIPT" ]; then
    echo -e "${RED}❌ 管理脚本不存在: $PANEL_SCRIPT${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 源文件检查通过${NC}"
echo ""

# 创建目标目录
echo -e "${BLUE}2. 创建目标目录...${NC}"
mkdir -p "$TARGET_DIR/templates"
mkdir -p "$TARGET_DIR/custom"
echo -e "${GREEN}✅ 目录创建完成${NC}"
echo ""

# 复制文件
echo -e "${BLUE}3. 复制专家配置和模板...${NC}"

# 复制配置文件
if [ -f "$SOURCE_DIR/experts.json" ]; then
    cp "$SOURCE_DIR/experts.json" "$TARGET_DIR/"
    echo "  ✓ experts.json"
fi

# 复制 README
if [ -f "$SOURCE_DIR/README.md" ]; then
    cp "$SOURCE_DIR/README.md" "$TARGET_DIR/"
    echo "  ✓ README.md"
fi

# 复制快速开始
if [ -f "$SOURCE_DIR/快速开始.md" ]; then
    cp "$SOURCE_DIR/快速开始.md" "$TARGET_DIR/"
    echo "  ✓ 快速开始.md"
fi

# 复制模板文件
if [ -d "$SOURCE_DIR/templates" ]; then
    cp "$SOURCE_DIR/templates"/*.prompt "$TARGET_DIR/templates/" 2>/dev/null || true
    template_count=$(ls "$TARGET_DIR/templates"/*.prompt 2>/dev/null | wc -l)
    echo "  ✓ $template_count 个专家模板"
fi

# 复制自动加载脚本
if [ -f "$AUTO_LOAD_SCRIPT" ]; then
    cp "$AUTO_LOAD_SCRIPT" "$TARGET_DIR/"
    chmod +x "$TARGET_DIR/auto_load_expert.sh"
    echo "  ✓ auto_load_expert.sh"
fi

echo -e "${GREEN}✅ 文件复制完成${NC}"
echo ""

# 创建符号链接
echo -e "${BLUE}4. 创建命令链接...${NC}"

# 检查是否有权限
if [ -w "$BIN_DIR" ]; then
    chmod +x "$PANEL_SCRIPT"
    chmod +x "$QUERY_SCRIPT"

    # 创建 ai-expert 链接
    if [ -L "$BIN_DIR/ai-expert" ]; then
        rm "$BIN_DIR/ai-expert"
    fi
    ln -s "$PANEL_SCRIPT" "$BIN_DIR/ai-expert"
    echo "  ✓ ai-expert -> $PANEL_SCRIPT"

    # 创建 ai-query 链接
    if [ -L "$BIN_DIR/ai-query" ]; then
        rm "$BIN_DIR/ai-query"
    fi
    ln -s "$QUERY_SCRIPT" "$BIN_DIR/ai-query"
    echo "  ✓ ai-query -> $QUERY_SCRIPT"

    echo -e "${GREEN}✅ 命令链接创建成功${NC}"
else
    echo -e "${YELLOW}⚠️  需要 sudo 权限创建全局命令链接${NC}"
    echo ""
    echo "请手动运行以下命令："
    echo ""
    echo -e "  ${BLUE}sudo ln -s $PANEL_SCRIPT $BIN_DIR/ai-expert${NC}"
    echo -e "  ${BLUE}sudo ln -s $QUERY_SCRIPT $BIN_DIR/ai-query${NC}"
    echo ""
fi
echo ""

# 添加别名和自动加载到 ~/.izshrc
echo -e "${BLUE}5. 配置 iZsh 集成...${NC}"

IZSHRC="$HOME/.izshrc"
ALIAS_BLOCK="# AI 命令专家系统别名
alias experts='ai-expert list'
alias expert-edit='ai-expert edit'
alias expert-new='ai-expert create'
alias expert-view='ai-expert view'
alias cmd-help='ai-query command'
alias expert-help='ai-query expert'
alias find-fix='ai-query solve'
alias best-practice='ai-query best'"

AUTO_LOAD_BLOCK="# AI 命令专家系统 - 自动加载
if [ -f \"\$HOME/.izsh/ai_experts/auto_load_expert.sh\" ]; then
    source \"\$HOME/.izsh/ai_experts/auto_load_expert.sh\"

    # 注册 preexec 钩子（命令执行前自动加载专家）
    if ! (( \${preexec_functions[(I)auto_load_ai_expert]} )); then
        preexec_functions+=(auto_load_ai_expert)
    fi
fi"

if [ -f "$IZSHRC" ]; then
    # 添加别名
    if ! grep -q "AI 命令专家系统别名" "$IZSHRC"; then
        echo "" >> "$IZSHRC"
        echo "$ALIAS_BLOCK" >> "$IZSHRC"
        echo -e "  ✓ 别名已添加"
    else
        echo -e "  ${YELLOW}⚠️  别名已存在${NC}"
    fi

    # 添加自动加载
    if ! grep -q "AI 命令专家系统 - 自动加载" "$IZSHRC"; then
        echo "" >> "$IZSHRC"
        echo "$AUTO_LOAD_BLOCK" >> "$IZSHRC"
        echo -e "  ✓ 自动加载钩子已添加"
    else
        echo -e "  ${YELLOW}⚠️  自动加载钩子已存在${NC}"
    fi

    echo -e "${GREEN}✅ iZsh 集成完成${NC}"
else
    echo -e "${YELLOW}⚠️  ~/.izshrc 不存在，请手动添加配置${NC}"
fi
echo ""

# 显示安装摘要
echo -e "${GREEN}=========================================="
echo "✅ 安装完成！"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📁 安装位置：${NC}"
echo "  - 配置目录: $TARGET_DIR"
echo "  - 命令工具: $BIN_DIR/ai-expert, $BIN_DIR/ai-query"
echo ""
echo -e "${BLUE}🤖 自动加载功能：${NC}"
echo "  - 已启用专家自动检测"
echo "  - 执行 git、docker、python 等命令时自动加载对应专家"
echo "  - 专家提示词会注入到 AI 上下文中"
echo "  - 使用 \$IZSH_CURRENT_EXPERT 查看当前专家"
echo ""
echo -e "${BLUE}🎯 快速开始：${NC}"
echo ""
echo "  # 查看所有专家"
echo -e "  ${GREEN}ai-expert list${NC}"
echo ""
echo "  # 查看 Git 专家提示词"
echo -e "  ${GREEN}ai-expert view git${NC}"
echo ""
echo "  # 编辑 Claude 专家"
echo -e "  ${GREEN}ai-expert edit claude${NC}"
echo ""
echo "  # 创建自定义专家"
echo -e "  ${GREEN}ai-expert create${NC}"
echo ""
echo "  # 查询 Docker 命令用法"
echo -e "  ${GREEN}ai-query command docker${NC}"
echo ""
echo "  # 查询 Claude Code 最新功能"
echo -e "  ${GREEN}ai-query expert claude${NC}"
echo ""
echo "  # 搜索最佳实践"
echo -e "  ${GREEN}ai-query best 'Python async'${NC}"
echo ""
echo -e "${BLUE}📖 文档：${NC}"
echo "  - 快速开始: $TARGET_DIR/快速开始.md"
echo "  - 详细说明: $TARGET_DIR/README.md"
echo "  - 在线帮助: ai-expert help"
echo ""
echo -e "${BLUE}🔄 重新加载配置：${NC}"
echo -e "  ${GREEN}source ~/.izshrc${NC}"
echo ""
echo -e "${YELLOW}💡 提示：${NC}"
echo "  - 使用 'experts' 快速查看所有专家"
echo "  - 使用 'expert-edit <id>' 编辑专家"
echo "  - 使用 'cmd-help <命令>' 查询命令用法"
echo "  - 执行命令时会自动加载对应的 AI 专家"
echo "  - 设置 IZSH_SHOW_EXPERT_WELCOME=false 隐藏欢迎消息"
echo ""
echo -e "${GREEN}享受 AI 命令专家系统！🎉${NC}"
echo ""
