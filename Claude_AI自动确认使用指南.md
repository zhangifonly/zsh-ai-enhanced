# Claude Code AI 自动确认 - 完整使用指南

## ✅ 功能完成状态

### 已实现的三大核心功能

#### 1. 文本确认提示自动处理
- **支持格式**：`[Y/n]`, `[yes/no]`, `[1/2/3]`, `[continue/cancel]` 等
- **工作原理**：
  - 检测到确认提示后倒计时 3 秒
  - 用户可随时手动输入响应
  - 超时后 AI 自动分析并选择最积极的选项
- **示例**：
  ```
  Do you want to continue? [Y/n] (3s)
  Do you want to continue? [Y/n] (2s)
  Do you want to continue? [Y/n] (1s)
  ⏰ 超时，AI 正在分析最佳选项...
  ✅ AI 自动选择: Y
  ```

#### 2. Claude Code 数字菜单自动选择
- **支持格式**：
  ```
  ❯ 1. Yes
    2. Yes, allow all edits during this session (shift+tab)
    3. No, and tell Claude what to do differently (esc)
  ```
- **工作原理**：
  - 自动检测 Claude Code 特定菜单格式
  - AI 分析所有选项，忽略快捷键说明
  - 直接发送数字选择（不使用箭头键，更高效）
- **AI 选择原则**：
  - 选择最完整、功能最全面的选项
  - 优先选择"推荐"或"默认"标记的选项
  - 避免"跳过"、"取消"等消极选项
  - 选择能让程序继续运行的选项

#### 3. 通用箭头键菜单自动导航
- **支持格式**：使用 `>`, `→`, `▶`, `*`, `●`, `■` 等标记的菜单
- **工作原理**：
  - 检测菜单项和当前选中位置
  - AI 选择最佳选项
  - 自动发送箭头键（上/下）导航到目标位置
  - 自动按回车确认

## 🚀 快速启动指南

### 方法 1：使用 iZsh 应用程序（推荐）

**步骤**：
1. 打开 iZsh 应用程序
   ```bash
   open ~/Applications/iZsh.app
   ```
   或双击桌面/应用程序文件夹中的 iZsh 图标

2. 在 iZsh 中运行 Claude Code（AI 自动确认模式）
   ```bash
   [iZsh] ~% claude-auto
   ```

3. 看到启动信息
   ```
   🤖 AI 自动确认模式已启用
   提示：所有确认将在 3 秒后自动由 AI 选择
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

### 方法 2：从命令行启动（需设置环境变量）

如果要从普通终端启动 iZsh，需要设置库路径：

```bash
# 启动 iZsh
DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib \
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES \
./Src/izsh

# 或者使用已安装的版本（如果配置正确）
~/.local/bin/izsh
```

然后在 iZsh 中运行：
```bash
[iZsh] ~% claude-auto
```

### 别名说明

在 iZsh 中配置了以下别名：
- `claude-auto`: AI 自动确认模式（推荐）
- `claude-ai`: 同 claude-auto（兼容别名）
- `claude`: 原始 Claude Code 命令（/opt/homebrew/bin/claude）

## 🎯 完整工作流示例

### 示例 1：基本使用

```bash
# 1. 启动 iZsh.app
open ~/Applications/iZsh.app

# 2. 在 iZsh 中运行
[iZsh] ~% claude-auto

🤖 AI 自动确认模式已启用
提示：所有确认将在 3 秒后自动由 AI 选择
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 3. Claude Code 开始工作，遇到确认提示：

Do you want to create 项目实施计划文档.md?
 ❯ 1. Yes
   2. Yes, allow all edits during this session (shift+tab)
   3. No, and tell Claude what to do differently (esc)

🔍 检测到交互式菜单，AI 正在分析...
✅ AI 选择: Yes

# 继续执行，无需手动干预...
```

### 示例 2：多次确认场景

```bash
[iZsh] ~% claude-auto

# AI 自动处理多个确认：

1️⃣ 文件创建确认
   Do you want to create README.md? [Y/n]
   ✅ AI 自动选择: Y

2️⃣ 编辑权限确认
   Can I edit the configuration file? [Y/n]
   ✅ AI 自动选择: Y

3️⃣ 命令执行确认
   Run npm install? [Y/n]
   ✅ AI 自动选择: Y

# 所有操作自动完成，项目持续推进
```

## 🔧 配置选项

### 环境变量

在 `~/.izshrc` 中已配置：

```bash
# AI 功能开关
export IZSH_AI_ENABLED=1

# AI API 配置
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="YOUR_API_KEY_HERE"
export IZSH_AI_MODEL="claude-3-5-haiku-20241022"
export IZSH_AI_API_TYPE="anthropic"

# 自动确认超时（秒）
export IZSH_AI_CONFIRM_TIMEOUT=3

# 智能确认（只对危险命令确认）
export IZSH_AI_SMART_CONFIRM=1

# macOS 必需配置
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

### 修改超时时间

如果想修改自动确认的等待时间，编辑 `~/.izshrc`：

```bash
# 默认 3 秒
export IZSH_AI_CONFIRM_TIMEOUT=3

# 改为 5 秒
export IZSH_AI_CONFIRM_TIMEOUT=5

# 改为 1 秒（快速模式）
export IZSH_AI_CONFIRM_TIMEOUT=1
```

然后重新加载配置：
```bash
[iZsh] ~% source ~/.izshrc
```

## 🧪 测试验证

### 运行完整测试

```bash
cd ~/Documents/ClaudeCode/zsh/zsh
./test_claude_wrapper.sh
```

### 手动测试 AI 决策

在 iZsh 中测试 ai_confirm 函数：

```bash
[iZsh] ~% source ~/.izshrc
[iZsh] ~% result=$(ai_confirm "是否继续安装？" "Y/n" 3)
[iZsh] ~% echo $result
```

### 测试 Claude Code 集成

创建一个简单的测试项目：

```bash
[iZsh] ~% cd /tmp
[iZsh] /tmp% mkdir claude-test
[iZsh] /tmp% cd claude-test
[iZsh] /tmp/claude-test% claude-auto

# 给 Claude 一个任务，观察 AI 如何自动处理确认
> 请创建一个 README.md 文件，包含项目说明
```

## 📊 技术实现细节

### 核心组件

1. **Python Wrapper** (`claude_code_wrapper.py`)
   - 拦截 Claude Code 的 stdio
   - 实时检测确认提示和菜单
   - 调用 iZsh 的 AI 功能做决策
   - 自动发送响应

2. **AI 决策函数** (`ai_confirm` in `~/.izshrc`)
   - 倒计时等待用户输入
   - 超时后调用 AI 分析
   - 返回最佳选择

3. **模式检测**
   - Claude Code 特定模式：权限请求、文件操作、命令执行
   - 通用确认模式：Y/n, yes/no, 数字选项
   - 菜单检测：箭头标记、选中标记、Claude Code 菜单格式

### AI 选择策略

AI 使用以下原则做决策：

1. **完整性优先**：选择功能最全面的方案
2. **推荐优先**：有"推荐"或"默认"标记时优先选择
3. **积极原则**：选择能让程序继续执行的选项（Yes > No）
4. **安全意识**：涉及删除操作时选择安全的选项
5. **智能分析**：对于数字选项，分析每个选项含义后选择最佳

## ⚠️ 常见问题

### Q1: AI 没有响应？

**可能原因**：
- 没有在 iZsh 中运行
- 直接运行了 `claude` 而不是 `claude-auto`
- Wrapper 未启动

**解决方案**：
1. 确认在 iZsh 提示符下：`[iZsh] ~%`
2. 使用 `claude-auto` 而不是 `claude`
3. 重新启动 iZsh.app

### Q2: libcurl 库加载错误？

**错误信息**：
```
dyld: Library not loaded: @rpath/libcurl.4.dylib
```

**解决方案**：
- 使用 iZsh.app（推荐，已配置好环境）
- 或设置环境变量：
  ```bash
  export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
  ```

### Q3: 如何查看 AI 的决策过程？

在 wrapper 中已经有调试输出：
```
🔍 检测到交互式菜单，AI 正在分析...
✅ AI 选择: Yes
```

如果需要更详细的日志，可以修改 wrapper 添加 debug 输出。

### Q4: 如何临时禁用自动确认？

使用原始的 `claude` 命令（不带 wrapper）：
```bash
[iZsh] ~% /opt/homebrew/bin/claude
```

或者在普通 zsh 中运行 Claude Code。

## 📝 维护和更新

### 更新 Wrapper

编辑 wrapper 脚本：
```bash
vim ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py
```

主要配置项：
- `timeout`: 默认倒计时时间（第 97 行）
- `CLAUDE_CODE_PATTERNS`: 检测 Claude Code 提示的正则表达式（第 22-39 行）
- `CONFIRM_PATTERNS`: 通用确认模式（第 42-72 行）

### 更新 AI 配置

编辑 iZsh 配置：
```bash
vim ~/.izshrc
```

主要配置项在 "AI 功能配置" 部分（第 43-89 行）。

修改后重新加载：
```bash
[iZsh] ~% source ~/.izshrc
```

## 🎊 总结

Claude Code AI 自动确认功能已完全实现并可用：

✅ **文本确认**：Y/n, yes/no, 数字选项等
✅ **Claude Code 菜单**：❯ 1. Yes 格式，直接发送数字
✅ **箭头键菜单**：自动导航和确认
✅ **AI 智能决策**：选择最积极、最完整的方案
✅ **倒计时机制**：3 秒内可手动干预
✅ **完整集成**：无缝对接 Claude Code

**立即开始使用**：
```bash
open ~/Applications/iZsh.app
[iZsh] ~% claude-auto
```

享受完全自动化的 Claude Code 工作流！🚀
