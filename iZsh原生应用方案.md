# iZsh Native - 原生终端应用

## 使用 SwiftTerm 库

### 项目结构

```
iZshNative/
├── Package.swift              # Swift Package Manager 配置
├── Sources/
│   └── iZshNative/
│       ├── main.swift        # 主入口
│       ├── AppDelegate.swift # 应用代理
│       └── TerminalWindow.swift # 终端窗口
└── Resources/
    └── Info.plist
```

### 依赖

- **SwiftTerm**: https://github.com/migueldeicaza/SwiftTerm
  - 1193 stars
  - MIT License
  - 完整的 Xterm/VT100 终端模拟器
  - 支持所有 VT100 控制序列
  - 原生 Swift 实现

### 安装步骤

1. 使用 Swift Package Manager:
```bash
cd ~/Documents/ClaudeCode/zsh/zsh
swift package init --type executable --name iZshNative
```

2. 添加 SwiftTerm 依赖到 Package.swift

3. 实现终端窗口和 iZsh 集成

4. 编译为原生 macOS 应用

### 特性

- ✅ 完全原生的 macOS 应用
- ✅ 自定义菜单栏
- ✅ 完整的终端模拟
- ✅ VT100/Xterm 兼容
- ✅ 支持颜色和格式化
- ✅ 集成 iZsh shell
- ✅ AI 主题UI

## 快速创建方案

由于创建完整的原生终端应用较复杂，我建议采用更简单的方案：

### 方案 A: 使用现有终端（iTerm2 Profile）
- 创建 iZsh 专用的 iTerm2 profile
- 自定义主题和配置
- 最快最简单

### 方案 B: 使用 Electron
- 使用 xterm.js
- 跨平台
- 开发快速

### 方案 C: 完整原生应用（推荐但需要更多时间）
- 使用 SwiftTerm
- 完全原生
- 最佳性能

您希望采用哪个方案？
