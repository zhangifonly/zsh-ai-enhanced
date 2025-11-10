#!/bin/bash
# iZsh 增强版安装脚本

set -e

echo "🚀 iZsh 增强版安装程序"
echo "================================"
echo ""

cd "$(dirname "$0")"

# 1. 创建控制面板应用包
echo "📦 创建 iZsh 控制面板..."
CONTROL_APP="$HOME/Applications/iZshControl.app"
rm -rf "$CONTROL_APP"

mkdir -p "$CONTROL_APP/Contents/MacOS"
mkdir -p "$CONTROL_APP/Contents/Resources"

# 编译控制面板
echo "🔨 编译控制面板..."
swiftc -o "$CONTROL_APP/Contents/MacOS/iZshControl" iZshControl.swift -framework Cocoa

# 创建 Info.plist
cat > "$CONTROL_APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>iZshControl</string>
    <key>CFBundleIdentifier</key>
    <string>com.izsh.control</string>
    <key>CFBundleName</key>
    <string>iZshControl</string>
    <key>CFBundleDisplayName</key>
    <string>iZsh 控制面板</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ 控制面板创建完成"

# 2. 更新主应用启动脚本
echo "🔧 更新 iZsh 主应用..."

cat > "$HOME/Applications/iZsh.app/Contents/MacOS/iZsh" << 'EOFAPP'
#!/bin/bash
# iZsh 增强版启动器

# 设置环境变量
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# 启动控制面板（如果未运行）
if ! pgrep -f "iZshControl" > /dev/null; then
    open -a "$HOME/Applications/iZshControl.app"
    sleep 0.5
fi

# 启动新的 Terminal 窗口运行 iZsh
osascript <<EOF
tell application "Terminal"
    activate
    set newWindow to do script "clear; echo ''; echo '╔═══════════════════════════════════════════════════════════╗'; echo '║                                                           ║'; echo '║    ██╗███████╗███████╗██╗  ██╗                          ║'; echo '║    ██║╚══███╔╝██╔════╝██║  ██║                          ║'; echo '║    ██║  ███╔╝ ███████╗███████║                          ║'; echo '║    ██║ ███╔╝  ╚════██║██╔══██║                          ║'; echo '║    ██║███████╗███████║██║  ██║                          ║'; echo '║    ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝                          ║'; echo '║                                                           ║'; echo '║            智能终端 - AI 驱动的 Shell                      ║'; echo '║                                                           ║'; echo '╚═══════════════════════════════════════════════════════════╝'; echo ''; echo '⚡ 正在启动 iZsh...'; echo '💡 提示: 使用菜单栏的 ⚡ 图标访问控制面板'; echo ''; export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib; export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES; exec ~/.local/bin/izsh"
    set custom title of newWindow to "iZsh - 智能终端"
end tell
EOF
EOFAPP

chmod +x "$HOME/Applications/iZsh.app/Contents/MacOS/iZsh"

echo "✅ 主应用更新完成"

# 3. 创建快速启动脚本
echo "🔗 创建快速启动脚本..."

cat > "$HOME/Desktop/启动iZsh.command" << 'EOFCMD'
#!/bin/bash
open -a "$HOME/Applications/iZsh.app"
EOFCMD

chmod +x "$HOME/Desktop/启动iZsh.command"

echo "✅ 桌面快捷方式已创建"

# 4. 设置控制面板自动启动（可选）
echo ""
echo "📋 是否设置控制面板开机自启动？"
echo "   这样每次开机后，菜单栏都会显示 iZsh 控制图标"
echo ""
read -p "设置自启动? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ~/Library/LaunchAgents

    cat > ~/Library/LaunchAgents/com.izsh.control.plist << EOFLAUNCH
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.izsh.control</string>
    <key>ProgramArguments</key>
    <array>
        <string>open</string>
        <string>-a</string>
        <string>$HOME/Applications/iZshControl.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOFLAUNCH

    echo "✅ 已设置开机自启动"
fi

# 5. 刷新系统
echo ""
echo "🔄 刷新系统..."
touch ~/Applications/iZsh.app
touch ~/Applications/iZshControl.app
killall Finder 2>/dev/null || true

echo ""
echo "✨ ================================"
echo "✨ iZsh 增强版安装完成！"
echo "✨ ================================"
echo ""
echo "📱 已安装的组件："
echo "   • iZsh 主应用: ~/Applications/iZsh.app"
echo "   • 控制面板: ~/Applications/iZshControl.app"
echo "   • 桌面快捷方式: ~/Desktop/启动iZsh.command"
echo ""
echo "🚀 启动方式："
echo "   1. 双击桌面的「启动iZsh.command」"
echo "   2. 双击 ~/Applications/iZsh.app"
echo "   3. Spotlight 搜索 \"iZsh\""
echo ""
echo "⚡ 控制面板功能："
echo "   • 菜单栏显示 ⚡ 图标"
echo "   • 浮动控制面板"
echo "   • 快捷键支持"
echo "   • 快速访问设置和帮助"
echo ""
echo "⌨️  快捷键："
echo "   • ⌘N - 新建窗口"
echo "   • ⌘K - 清屏"
echo "   • ⌘, - 打开设置"
echo "   • ⌘? - 显示帮助"
echo ""
echo "🎉 现在就试试吧！"
