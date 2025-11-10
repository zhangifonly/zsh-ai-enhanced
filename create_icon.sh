#!/bin/bash
# 创建 iZsh 图标脚本

# 使用 SF Symbols 或系统图标创建简单图标
# 这里我们创建一个基于文本的简单图标

ICONSET_DIR=~/Applications/iZsh.app/Contents/Resources/AppIcon.iconset

# 使用 sips 从系统 Terminal 图标创建变体
if [ -f /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns ]; then
    echo "使用 Terminal 图标作为基础..."

    # 提取并创建各种尺寸
    sips -z 16 16 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null
    sips -z 32 32 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null
    sips -z 32 32 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null
    sips -z 64 64 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null
    sips -z 128 128 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
    sips -z 256 256 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null
    sips -z 256 256 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
    sips -z 512 512 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null
    sips -z 512 512 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    sips -z 1024 1024 /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns --out "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null

    # 生成 .icns 文件
    iconutil -c icns "$ICONSET_DIR" -o ~/Applications/iZsh.app/Contents/Resources/AppIcon.icns

    echo "✅ 图标创建完成"
else
    echo "⚠️  无法找到 Terminal 图标，使用默认图标"
fi
