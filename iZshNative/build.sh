#!/bin/bash
# iZsh Native 编译和打包脚本

set -e

echo "🚀 开始编译 iZsh Native..."

cd "$(dirname "$0")"

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf .build
rm -rf ~/Applications/iZsh.app.new

# 解析依赖
echo "📦 解析 SwiftTerm 依赖..."
swift package resolve

# 编译
echo "🔨 编译项目..."
swift build -c release

# 检查编译结果
if [ ! -f ".build/release/iZshNative" ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✅ 编译成功！"

# 创建应用包结构
echo "📱 创建应用包..."
APP_PATH="$HOME/Applications/iZsh.app.new"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 复制可执行文件
cp .build/release/iZshNative "$APP_PATH/Contents/MacOS/iZsh"
chmod +x "$APP_PATH/Contents/MacOS/iZsh"

# 创建 Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>iZsh</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.izsh.native</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>iZsh</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 iZsh Project. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDisplayName</key>
    <string>iZsh - 智能终端</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
EOF

# 复制图标
if [ -f "../iZsh.app/Contents/Resources/AppIcon.icns" ]; then
    cp "../iZsh.app/Contents/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/"
    echo "✅ 复制了图标"
fi

# 复制 SwiftTerm 框架
echo "📚 复制依赖框架..."
mkdir -p "$APP_PATH/Contents/Frameworks"

# 查找并复制 SwiftTerm 框架
SWIFTTERM_PATH=$(find .build/release -name "SwiftTerm*.framework" -o -name "libSwiftTerm*.dylib" 2>/dev/null | head -1)
if [ -n "$SWIFTTERM_PATH" ]; then
    cp -R "$SWIFTTERM_PATH" "$APP_PATH/Contents/Frameworks/"
    echo "✅ 复制了 SwiftTerm"
fi

# 代码签名（可选）
echo "🔏 代码签名..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || echo "⚠️  代码签名失败（这不影响使用）"

# 替换旧版本
if [ -d "$HOME/Applications/iZsh.app" ]; then
    echo "🔄 备份旧版本..."
    mv "$HOME/Applications/iZsh.app" "$HOME/Applications/iZsh.app.old"
fi

mv "$APP_PATH" "$HOME/Applications/iZsh.app"

echo ""
echo "✨ ================================"
echo "✨ iZsh Native 编译完成！"
echo "✨ ================================"
echo ""
echo "📱 应用位置: ~/Applications/iZsh.app"
echo "🚀 启动方式: open ~/Applications/iZsh.app"
echo ""
echo "📝 特性:"
echo "   ✅ 完全原生的 macOS 应用"
echo "   ✅ 自定义菜单栏"
echo "   ✅ SwiftTerm 终端模拟"
echo "   ✅ 集成 iZsh AI 功能"
echo ""

# 刷新 Finder
touch ~/Applications/iZsh.app
killall Finder 2>/dev/null || true

echo "🎉 完成！现在可以启动 iZsh Native 了"
