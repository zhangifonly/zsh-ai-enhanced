#!/bin/bash
# iZsh 独立应用测试脚本

echo "════════════════════════════════════════"
echo "  🧪 iZsh 独立应用配置测试"
echo "════════════════════════════════════════"
echo ""

# 检查 1: 桌面快捷方式
echo "✓ 检查 1: 桌面快捷方式"
if [ -f ~/Desktop/iZsh.command ]; then
    echo "   ✅ 桌面快捷方式存在"
    ls -lh ~/Desktop/iZsh.command | awk '{print "   文件大小: " $5}'
    if [ -x ~/Desktop/iZsh.command ]; then
        echo "   ✅ 有执行权限"
    else
        echo "   ⚠️  没有执行权限，正在修复..."
        chmod +x ~/Desktop/iZsh.command
        echo "   ✅ 已添加执行权限"
    fi
else
    echo "   ❌ 桌面快捷方式不存在"
fi
echo ""

# 检查 2: 启动脚本
echo "✓ 检查 2: 启动脚本"
if [ -f ~/Documents/ClaudeCode/zsh/zsh/iZsh.command ]; then
    echo "   ✅ 启动脚本存在"
    if [ -x ~/Documents/ClaudeCode/zsh/zsh/iZsh.command ]; then
        echo "   ✅ 有执行权限"
    else
        echo "   ⚠️  没有执行权限，正在修复..."
        chmod +x ~/Documents/ClaudeCode/zsh/zsh/iZsh.command
        echo "   ✅ 已添加执行权限"
    fi
else
    echo "   ❌ 启动脚本不存在"
fi
echo ""

# 检查 3: Terminal 配置文件
echo "✓ 检查 3: Terminal 配置文件"
TERMINAL_PROFILE=~/Library/Application\ Support/Terminal/iZsh.terminal
if [ -f "$TERMINAL_PROFILE" ]; then
    echo "   ✅ Terminal 配置文件存在"
    echo "   位置: $TERMINAL_PROFILE"
else
    echo "   ❌ Terminal 配置文件不存在"
fi
echo ""

# 检查 4: iZsh 可执行文件
echo "✓ 检查 4: iZsh 可执行文件"
if [ -f ~/.local/bin/izsh ]; then
    echo "   ✅ iZsh 可执行文件存在"
    ~/.local/bin/izsh --version 2>&1 | head -1 | sed 's/^/   版本: /'
else
    echo "   ❌ iZsh 可执行文件不存在"
fi
echo ""

# 检查 5: 配置文件
echo "✓ 检查 5: 配置文件"
if [ -f ~/.izshrc ]; then
    echo "   ✅ 配置文件存在"
    grep "IZSH_AI_ENABLED" ~/.izshrc | head -1 | sed 's/^/   /'
    grep "IZSH_AI_MODEL" ~/.izshrc | head -1 | sed 's/^/   /'
else
    echo "   ❌ 配置文件不存在"
fi
echo ""

# 检查 6: AI 模块
echo "✓ 检查 6: AI 模块"
if [ -f ~/.local/lib/izsh/1.0.0-izsh/zsh/ai.so ]; then
    echo "   ✅ AI 模块存在"
    ls -lh ~/.local/lib/izsh/1.0.0-izsh/zsh/ai.so | awk '{print "   文件大小: " $5}'
else
    echo "   ❌ AI 模块不存在"
fi
echo ""

# 检查 7: 环境依赖
echo "✓ 检查 7: 环境依赖"
if [ -f /Users/zhangzhen/anaconda3/lib/libcurl.4.dylib ]; then
    echo "   ✅ libcurl 库存在"
else
    echo "   ❌ libcurl 库不存在"
fi
echo ""

# 总结
echo "════════════════════════════════════════"
echo "  📊 测试总结"
echo "════════════════════════════════════════"
echo ""
echo "🎯 可用的启动方式："
echo ""
echo "1️⃣  桌面快捷方式（推荐）"
echo "   双击: ~/Desktop/iZsh.command"
echo ""
echo "2️⃣  Terminal 配置文件"
echo "   Terminal → 偏好设置 → 描述文件 → 导入"
echo "   文件: ~/Library/Application Support/Terminal/iZsh.terminal"
echo ""
echo "3️⃣  命令行启动"
echo "   cd ~/Documents/ClaudeCode/zsh/zsh"
echo "   ./start_izsh.sh"
echo ""
echo "════════════════════════════════════════"
echo ""
echo "💡 现在可以："
echo "   1. 双击桌面上的 iZsh.command 启动"
echo "   2. 查看完整指南: 独立终端应用配置指南.md"
echo ""
