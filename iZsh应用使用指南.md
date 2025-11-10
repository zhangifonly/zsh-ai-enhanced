# iZsh 独立应用程序配置完成

## ✅ 已创建的应用

### 📱 iZsh.app - macOS 原生应用

**位置**: `~/Applications/iZsh.app`

这是一个完整的 macOS 应用程序包，包含：
- ✅ 应用程序信息 (Info.plist)
- ✅ 可执行文件 (iZsh)
- ✅ 应用图标 (基于 Terminal 图标)

---

## 🚀 使用方法

### 方法 1: Finder 中打开 ⭐

1. **打开 Finder**
2. **进入个人文件夹** (⌘ + Shift + H)
3. **打开 Applications 文件夹**
4. **双击 iZsh 应用图标**

### 方法 2: Spotlight 搜索

1. 按 **⌘ + 空格** 打开 Spotlight
2. 输入 **iZsh**
3. 按 **回车** 启动

### 方法 3: Launchpad

1. 按 **F4** 或四指捏合打开 Launchpad
2. 搜索 **iZsh**
3. 点击图标启动

### 方法 4: 拖到 Dock

1. 在 Finder 中找到 **iZsh.app**
2. 拖动到 Dock 栏
3. 之后点击 Dock 图标即可启动

---

## 🎯 应用特性

### 自动功能
- ✅ 自动设置环境变量
- ✅ 自动加载 AI 模块
- ✅ 显示启动画面
- ✅ 打开新的 Terminal 窗口
- ✅ 设置窗口标题为 "iZsh - 智能终端"

### 应用信息
- **应用名称**: iZsh - 智能终端
- **应用标识**: com.izsh.terminal
- **版本**: 1.0.0
- **类别**: 实用工具
- **系统要求**: macOS 10.13+

---

## 📊 文件结构

```
~/Applications/iZsh.app/
├── Contents/
│   ├── Info.plist           # 应用信息
│   ├── MacOS/
│   │   └── iZsh             # 可执行文件
│   └── Resources/
│       ├── AppIcon.icns     # 应用图标
│       └── AppIcon.iconset/ # 图标源文件
```

---

## 🔧 工作原理

当您双击 iZsh.app 时：

1. macOS 启动应用程序
2. 执行 `Contents/MacOS/iZsh` 脚本
3. 脚本使用 AppleScript 打开新的 Terminal 窗口
4. 在 Terminal 中设置环境变量
5. 显示启动画面
6. 启动 ~/.local/bin/izsh

---

## 🎨 自定义图标（可选）

如果您想使用自定义图标：

1. **准备图标文件**
   - 格式: PNG, 至少 512x512 像素
   - 建议: 1024x1024 像素

2. **使用在线工具转换**
   - 访问: https://cloudconvert.com/png-to-icns
   - 上传您的 PNG 图标
   - 下载 .icns 文件

3. **替换图标**
   ```bash
   # 备份原图标
   mv ~/Applications/iZsh.app/Contents/Resources/AppIcon.icns \
      ~/Applications/iZsh.app/Contents/Resources/AppIcon.icns.bak

   # 复制新图标
   cp /path/to/your/icon.icns \
      ~/Applications/iZsh.app/Contents/Resources/AppIcon.icns

   # 刷新图标缓存
   touch ~/Applications/iZsh.app
   killall Finder
   ```

---

## 🔐 首次运行

### macOS 安全提示

首次运行时，macOS 可能会显示安全警告：

> "iZsh" 无法打开，因为它来自身份不明的开发者

**解决方法**：

1. **右键点击** iZsh.app
2. 选择 **打开**
3. 在弹出的对话框中点击 **打开**
4. 之后就可以正常双击使用了

**或者在系统偏好设置中允许**：

1. 打开 **系统偏好设置** → **安全性与隐私**
2. 在 **通用** 标签页下
3. 点击 **仍要打开** 按钮

---

## 💡 高级配置

### 添加到 /Applications

如果您想让应用对所有用户可见：

```bash
# 需要管理员权限
sudo cp -R ~/Applications/iZsh.app /Applications/
```

### 设置为默认终端（实验性）

编辑 `~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist`

**注意**：这会影响系统行为，建议保持使用独立启动方式。

---

## 🛠️ 修改应用行为

### 编辑启动脚本

```bash
nano ~/Applications/iZsh.app/Contents/MacOS/iZsh
```

您可以修改：
- 启动画面文本
- 环境变量设置
- 窗口标题
- 启动参数

### 修改应用信息

```bash
nano ~/Applications/iZsh.app/Contents/Info.plist
```

可以修改：
- 应用名称
- 版本号
- 标识符
- 描述信息

---

## 📱 Dock 集成

### 添加到 Dock

**方法 1: 拖放**
1. 打开 Finder 找到 iZsh.app
2. 拖动到 Dock
3. 释放鼠标

**方法 2: 运行时添加**
1. 启动 iZsh.app
2. 在 Dock 中找到运行中的图标
3. 右键点击 → 选项 → 在 Dock 中保留

### 从 Dock 中移除

右键点击 Dock 中的图标 → 选项 → 从 Dock 中移除

---

## 🔍 故障排查

### 问题 1: 应用无法启动

**检查权限**：
```bash
chmod +x ~/Applications/iZsh.app/Contents/MacOS/iZsh
```

**查看日志**：
```bash
# 在 Console.app 中查看系统日志
open -a Console
```

### 问题 2: 图标不显示

**刷新图标缓存**：
```bash
touch ~/Applications/iZsh.app
killall Finder
```

### 问题 3: 启动后立即关闭

**测试可执行文件**：
```bash
~/Applications/iZsh.app/Contents/MacOS/iZsh
```

查看错误信息。

### 问题 4: Spotlight 搜索不到

**重建 Spotlight 索引**：
```bash
# 系统偏好设置 → Spotlight → 隐私
# 添加 ~/Applications 然后再移除
```

---

## 🎯 快速验证

### 测试应用是否正常

在终端中运行：
```bash
open ~/Applications/iZsh.app
```

应该会：
1. 打开新的 Terminal 窗口
2. 显示 iZsh 启动画面
3. 自动启动 iZsh
4. 窗口标题显示 "iZsh - 智能终端"

---

## 📚 相关文件

| 文件 | 路径 | 说明 |
|------|------|------|
| **应用程序** | `~/Applications/iZsh.app` | 主应用 |
| iZsh 可执行文件 | `~/.local/bin/izsh` | Shell 程序 |
| 配置文件 | `~/.izshrc` | 配置 |
| AI 模块 | `~/.local/lib/izsh/1.0.0-izsh/zsh/ai.so` | AI 功能 |

---

## 🎉 立即使用

### 现在就可以：

1. **打开 Finder**
2. **进入 Applications 文件夹** (在个人目录下)
3. **双击 iZsh 图标**

或者：

**⌘ + 空格 → 输入 "iZsh" → 回车**

---

## 🚀 下一步

### 可选改进

1. **创建自定义图标**
   - 使用设计软件创建独特的图标
   - 突出 "AI" 或 "智能" 主题

2. **添加快捷键**
   - 系统偏好设置 → 键盘 → 快捷键
   - 为 iZsh 设置全局快捷键

3. **集成到工作流**
   - 使用 Automator 创建工作流
   - 配合 Alfred、Raycast 等启动器

---

**享受您的独立 iZsh 应用程序！** 🎊
