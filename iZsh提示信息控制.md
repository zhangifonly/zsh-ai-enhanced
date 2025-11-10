# iZsh 提示信息控制

## 🔇 控制提示详细程度

iZsh 提供了多种方式来控制AI翻译时的提示信息。

### 默认模式（详细）

默认情况下，iZsh 会显示完整的提示信息：

```bash
[iZsh] ~% 列目录

💡 AI 正在翻译: '列目录'...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI 建议执行：
   ls
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

是否执行此命令? [Y/n/e(编辑)]
```

### 安静模式（简洁）

如果您觉得提示过于冗长，可以启用安静模式：

```bash
# 在 ~/.izshrc 中添加：
export IZSH_AI_QUIET=1
```

安静模式下的显示：

```bash
[iZsh] ~% 列目录
→ ls
是否执行此命令? [Y/n/e(编辑)]
```

### 调试模式

需要排查问题时，可以启用调试模式：

```bash
# 在 ~/.izshrc 中添加：
export IZSH_AI_DEBUG=1
```

调试模式会显示：
- API 请求详情
- 响应解析过程
- 字符编码信息
- 错误详情

## ⚙️ 配置选项总结

在 `~/.izshrc` 中可以设置以下环境变量：

### 1. 基础功能

```bash
# AI 功能开关
export IZSH_AI_ENABLED=1              # 1=启用, 0=禁用

# API 配置
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="你的密钥"
export IZSH_AI_MODEL="claude-3-5-haiku-20241022"
export IZSH_AI_API_TYPE="anthropic"
```

### 2. 行为控制

```bash
# 干预级别
export IZSH_AI_INTERVENTION_LEVEL="suggest"
# - suggest: 需要用户确认（推荐）
# - auto: 自动执行翻译的命令

# 安静模式（新增）
export IZSH_AI_QUIET=1                # 1=安静, 0=详细（默认）

# 调试模式
export IZSH_AI_DEBUG=1                # 1=启用, 0=禁用（默认）
```

### 3. 系统环境

```bash
# macOS 特定（自动设置，通常不需要修改）
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

## 📊 三种模式对比

| 特性 | 详细模式 | 安静模式 | 调试模式 |
|------|----------|----------|----------|
| 翻译提示 | ✅ 完整显示 | 🔇 最小化 | ✅ 完整+详情 |
| AI建议框 | ✅ 美化框架 | ❌ 简单箭头 | ✅ 美化框架 |
| API信息 | ❌ 隐藏 | ❌ 隐藏 | ✅ 完整显示 |
| 编码信息 | ❌ 隐藏 | ❌ 隐藏 | ✅ 十六进制 |
| 适用场景 | 日常使用 | 快速操作 | 问题排查 |

## 💡 推荐配置

### 新用户推荐

```bash
# 详细模式 - 了解AI翻译过程
export IZSH_AI_QUIET=0
export IZSH_AI_INTERVENTION_LEVEL="suggest"
```

### 熟练用户推荐

```bash
# 安静模式 - 快速高效
export IZSH_AI_QUIET=1
export IZSH_AI_INTERVENTION_LEVEL="suggest"
```

### 高级用户推荐

```bash
# 自动模式 - 完全自动化
export IZSH_AI_QUIET=1
export IZSH_AI_INTERVENTION_LEVEL="auto"
```

**注意**：自动模式会直接执行翻译的命令，请谨慎使用！

## 🔧 实时切换

您可以在当前会话中临时切换模式：

### 临时启用安静模式

```bash
export IZSH_AI_QUIET=1
```

### 临时禁用安静模式

```bash
export IZSH_AI_QUIET=0
```

### 临时启用调试

```bash
export IZSH_AI_DEBUG=1
```

## 🎯 使用场景

### 场景 1：学习 Shell 命令

**推荐**：详细模式（默认）

```bash
export IZSH_AI_QUIET=0
```

**原因**：完整的提示信息有助于理解命令翻译过程。

### 场景 2：日常快速操作

**推荐**：安静模式

```bash
export IZSH_AI_QUIET=1
```

**原因**：减少干扰，提高效率。

### 场景 3：自动化脚本

**推荐**：自动模式 + 安静模式

```bash
export IZSH_AI_QUIET=1
export IZSH_AI_INTERVENTION_LEVEL="auto"
```

**原因**：完全自动化，无需交互。

### 场景 4：问题排查

**推荐**：调试模式

```bash
export IZSH_AI_DEBUG=1
```

**原因**：查看完整的API交互过程。

## ❓ 常见问题

### Q: 如何永久设置安静模式？

A: 编辑 `~/.izshrc`，添加：
```bash
export IZSH_AI_QUIET=1
```

### Q: 安静模式下还会显示确认提示吗？

A: 是的，安静模式只是简化翻译过程的提示，确认提示仍然会显示（除非使用 auto 模式）。

### Q: 调试信息太多，如何关闭？

A: 在 `~/.izshrc` 中注释掉或删除：
```bash
# export IZSH_AI_DEBUG=1
```

### Q: 可以完全禁用AI功能吗？

A: 可以，设置：
```bash
export IZSH_AI_ENABLED=0
```

## 📝 配置文件示例

### 最小配置（安静模式）

```bash
# ~/.izshrc
export IZSH_AI_ENABLED=1
export IZSH_AI_QUIET=1
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="你的密钥"
export IZSH_AI_MODEL="claude-3-5-haiku-20241022"
export IZSH_AI_API_TYPE="anthropic"
```

### 完整配置（推荐）

```bash
# ~/.izshrc

# 基础配置
export IZSH_AI_ENABLED=1
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="你的密钥"
export IZSH_AI_MODEL="claude-3-5-haiku-20241022"
export IZSH_AI_API_TYPE="anthropic"

# 行为控制
export IZSH_AI_INTERVENTION_LEVEL="suggest"  # suggest 或 auto
export IZSH_AI_QUIET=0                       # 0=详细, 1=安静

# 调试（默认关闭）
# export IZSH_AI_DEBUG=1
```

---

**总结**：根据您的使用习惯选择合适的模式，享受智能终端体验！ 🚀
