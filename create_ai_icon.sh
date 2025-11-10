#!/bin/bash
# iZsh AI 主题图标生成脚本

ICON_DIR=~/Applications/iZsh.app/Contents/Resources
ICONSET_DIR=$ICON_DIR/AppIcon.iconset
TMP_DIR=/tmp/izsh_icon

# 创建临时目录
mkdir -p $TMP_DIR
mkdir -p $ICONSET_DIR

echo "🎨 正在生成 iZsh AI 主题图标..."

# 使用 Python 生成 SVG 图标（带渐变的 AI 终端图标）
python3 << 'PYTHON_SCRIPT'
import os

svg_content = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- 渐变背景 - 深蓝到青色 -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a237e;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#0277bd;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#00acc1;stop-opacity:1" />
    </linearGradient>

    <!-- 光晕效果 -->
    <radialGradient id="glowGradient" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#00e5ff;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#00e5ff;stop-opacity:0" />
    </radialGradient>

    <!-- 阴影 -->
    <filter id="shadow">
      <feGaussianBlur in="SourceAlpha" stdDeviation="8"/>
      <feOffset dx="0" dy="4" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.3"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- 圆角矩形背景 -->
  <rect width="1024" height="1024" rx="220" fill="url(#bgGradient)"/>

  <!-- 光晕效果 -->
  <circle cx="512" cy="400" r="300" fill="url(#glowGradient)" opacity="0.3"/>

  <!-- 终端窗口 -->
  <g filter="url(#shadow)">
    <!-- 窗口背景 -->
    <rect x="162" y="256" width="700" height="500" rx="20" fill="#1e1e1e" opacity="0.95"/>

    <!-- 窗口标题栏 -->
    <rect x="162" y="256" width="700" height="50" rx="20" fill="#2d2d2d"/>
    <rect x="162" y="286" width="700" height="20" fill="#2d2d2d"/>

    <!-- 窗口按钮 -->
    <circle cx="200" cy="281" r="10" fill="#ff5f56"/>
    <circle cx="230" cy="281" r="10" fill="#ffbd2e"/>
    <circle cx="260" cy="281" r="10" fill="#27c93f"/>

    <!-- 终端内容 - 命令提示符 -->
    <text x="200" y="360" font-family="Monaco, Menlo, monospace" font-size="32" fill="#00ff88" font-weight="bold">
      [iZsh]
    </text>
    <text x="330" y="360" font-family="Monaco, Menlo, monospace" font-size="32" fill="#4fc3f7">
      ~$
    </text>

    <!-- AI 智能标识 -->
    <text x="200" y="420" font-family="Monaco, Menlo, monospace" font-size="28" fill="#aaaaaa">
      &gt; ai
    </text>
    <text x="280" y="420" font-family="Monaco, Menlo, monospace" font-size="28" fill="#00e5ff">
      "智能翻译"
    </text>

    <!-- 闪烁光标 -->
    <rect x="200" y="460" width="16" height="32" fill="#00ff88" opacity="0.8">
      <animate attributeName="opacity" values="0.8;0.2;0.8" dur="1.5s" repeatCount="indefinite"/>
    </rect>
  </g>

  <!-- AI 图标装饰 -->
  <g transform="translate(720, 620)" filter="url(#shadow)">
    <!-- AI 芯片图标 -->
    <rect x="0" y="0" width="120" height="120" rx="15" fill="#00e5ff" opacity="0.2"/>
    <rect x="10" y="10" width="100" height="100" rx="10" fill="#00e5ff" opacity="0.9"/>

    <!-- AI 文字 -->
    <text x="60" y="75" font-family="SF Pro Display, -apple-system, sans-serif"
          font-size="48" font-weight="bold" fill="#1a237e" text-anchor="middle">
      AI
    </text>

    <!-- 电路纹理 -->
    <line x1="20" y1="30" x2="40" y2="30" stroke="#1a237e" stroke-width="2" opacity="0.5"/>
    <circle cx="40" cy="30" r="3" fill="#1a237e" opacity="0.5"/>
    <line x1="80" y1="30" x2="100" y2="30" stroke="#1a237e" stroke-width="2" opacity="0.5"/>
    <circle cx="80" cy="30" r="3" fill="#1a237e" opacity="0.5"/>

    <line x1="20" y1="90" x2="40" y2="90" stroke="#1a237e" stroke-width="2" opacity="0.5"/>
    <circle cx="40" cy="90" r="3" fill="#1a237e" opacity="0.5"/>
    <line x1="80" y1="90" x2="100" y2="90" stroke="#1a237e" stroke-width="2" opacity="0.5"/>
    <circle cx="80" cy="90" r="3" fill="#1a237e" opacity="0.5"/>
  </g>

  <!-- 底部品牌标识 -->
  <text x="512" y="900" font-family="SF Pro Display, -apple-system, sans-serif"
        font-size="48" font-weight="300" fill="#ffffff" text-anchor="middle" opacity="0.9">
    iZsh
  </text>
</svg>'''

# 保存 SVG
with open('/tmp/izsh_icon/icon.svg', 'w') as f:
    f.write(svg_content)

print("✅ SVG 图标已生成")
PYTHON_SCRIPT

# 检查是否安装了 rsvg-convert 或 qlmanage
if command -v rsvg-convert &> /dev/null; then
    echo "✅ 使用 rsvg-convert 转换图标..."
    CONVERTER="rsvg-convert"
elif command -v qlmanage &> /dev/null; then
    echo "✅ 使用 qlmanage 转换图标..."
    CONVERTER="qlmanage"
else
    echo "⚠️  未找到 SVG 转换工具，尝试安装..."
    # 尝试使用 brew 安装
    if command -v brew &> /dev/null; then
        brew install librsvg 2>/dev/null
        CONVERTER="rsvg-convert"
    else
        echo "❌ 无法转换 SVG，请手动安装 librsvg: brew install librsvg"
        exit 1
    fi
fi

# 生成各种尺寸的 PNG
echo "🎨 生成各种尺寸的图标..."

SIZES=(16 32 64 128 256 512 1024)

for size in "${SIZES[@]}"; do
    if [ "$CONVERTER" = "rsvg-convert" ]; then
        rsvg-convert -w $size -h $size /tmp/izsh_icon/icon.svg -o /tmp/izsh_icon/icon_${size}.png
    else
        # 使用 sips 从 SVG 转换（macOS 内置）
        qlmanage -t -s $size -o /tmp/izsh_icon/ /tmp/izsh_icon/icon.svg &>/dev/null
        mv /tmp/izsh_icon/icon.svg.png /tmp/izsh_icon/icon_${size}.png 2>/dev/null || true
    fi
done

# 如果 rsvg-convert 失败，使用备用方案：从大图缩放
if [ ! -f /tmp/izsh_icon/icon_1024.png ]; then
    echo "⚠️  SVG 转换失败，使用备用方案..."

    # 创建一个简单的 PNG 图标作为后备
    python3 << 'PYTHON_FALLBACK'
from PIL import Image, ImageDraw, ImageFont
import os

# 创建 1024x1024 的图像
size = 1024
img = Image.new('RGB', (size, size), color=(26, 35, 126))
draw = ImageDraw.Draw(img)

# 绘制渐变背景（简化版）
for y in range(size):
    r = int(26 + (2 - 26) * y / size)
    g = int(35 + (119 - 35) * y / size)
    b = int(126 + (189 - 126) * y / size)
    draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))

# 绘制圆角矩形（终端窗口）
terminal_rect = (162, 256, 862, 756)
draw.rounded_rectangle(terminal_rect, radius=20, fill=(30, 30, 30))

# 绘制标题栏
draw.rounded_rectangle((162, 256, 862, 306), radius=20, fill=(45, 45, 45))
draw.rectangle((162, 286, 862, 306), fill=(45, 45, 45))

# 窗口按钮
draw.ellipse((190, 271, 210, 291), fill=(255, 95, 86))
draw.ellipse((220, 271, 240, 291), fill=(255, 189, 46))
draw.ellipse((250, 271, 270, 291), fill=(39, 201, 63))

# AI 标识
try:
    font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 120)
    font_small = ImageFont.truetype("/System/Library/Fonts/Monaco.dfont", 60)
except:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# AI 文字
draw.text((450, 450), "AI", fill=(0, 229, 255), font=font_large)

# iZsh 品牌
draw.text((390, 800), "iZsh", fill=(255, 255, 255), font=font_small)

# 保存
img.save('/tmp/izsh_icon/icon_1024.png')
print("✅ 后备图标已生成")
PYTHON_FALLBACK
fi

# 创建 iconset 所需的各种尺寸
echo "📦 创建 iconset..."

# 从 1024 图标生成其他尺寸（如果主图标存在）
if [ -f /tmp/izsh_icon/icon_1024.png ]; then
    sips -z 16 16 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_16x16.png" &>/dev/null
    sips -z 32 32 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_16x16@2x.png" &>/dev/null
    sips -z 32 32 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_32x32.png" &>/dev/null
    sips -z 64 64 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_32x32@2x.png" &>/dev/null
    sips -z 128 128 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_128x128.png" &>/dev/null
    sips -z 256 256 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_128x128@2x.png" &>/dev/null
    sips -z 256 256 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_256x256.png" &>/dev/null
    sips -z 512 512 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_256x256@2x.png" &>/dev/null
    sips -z 512 512 /tmp/izsh_icon/icon_1024.png --out "$ICONSET_DIR/icon_512x512.png" &>/dev/null
    cp /tmp/izsh_icon/icon_1024.png "$ICONSET_DIR/icon_512x512@2x.png"

    echo "✅ 所有尺寸已生成"

    # 生成 .icns 文件
    echo "🎨 生成最终图标文件..."
    iconutil -c icns "$ICONSET_DIR" -o "$ICON_DIR/AppIcon.icns"

    if [ -f "$ICON_DIR/AppIcon.icns" ]; then
        echo "✅ 图标创建成功！"
        echo "📍 位置: $ICON_DIR/AppIcon.icns"

        # 刷新 Finder
        touch ~/Applications/iZsh.app
        killall Finder 2>/dev/null || true

        echo "🎉 iZsh 图标已更新！"
        echo "💡 提示：如果图标未立即更新，请注销后重新登录"
    else
        echo "❌ 图标文件生成失败"
        exit 1
    fi
else
    echo "❌ 无法生成基础图标"
    exit 1
fi

# 清理临时文件
rm -rf $TMP_DIR

echo ""
echo "✨ 完成！现在打开 Finder 查看新图标："
echo "   open ~/Applications/"
