# PTY 版本 Wrapper - 修复输出显示问题

## 🐛 问题

原来的 wrapper 使用 `subprocess.PIPE`，导致：
- Claude Code 检测到不是真正的终端（TTY）
- Claude Code 的正常输出没有显示
- 用户只能看到 wrapper 的提示，看不到 Claude Code 的内容

## ✅ 解决方案

使用伪终端（PTY）版本的 wrapper：`claude_code_wrapper_pty.py`

### 关键技术

1. **使用 `pty.fork()`**
   - 创建伪终端对（master/slave）
   - Claude Code 认为在真正的终端中运行
   - 所有输出正常显示

2. **使用 `select.select()`**
   - 同时监听用户输入和程序输出
   - 实时转发双向通信
   - 不阻塞任何一方

3. **保留 AI 自动确认功能**
   - 仍然检测确认提示
   - 仍然在 3 秒后 AI 自动响应
   - 用户可以随时手动干预

## 🚀 现在的效果

```bash
[iZsh] ~% claude

🤖 AI 自动确认模式已启用
提示：所有确认将在 3 秒后自动由 AI 选择
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Welcome to Claude Code v1.x.x      ← ✅ Claude Code 的输出正常显示
Working directory: /Users/...       ← ✅ 所有输出都能看到

How can I help you?                 ← ✅ 交互提示正常显示

> 请创建一个 README                ← 您的输入

I'll create a README for you...     ← ✅ Claude Code 的响应正常显示

Do you want to create README.md? [Y/n]  ← 确认提示
⏰ 检测到确认提示，倒计时 3 秒...
✅ AI 自动选择: Y                   ← AI 自动输入

Creating README.md...               ← ✅ 继续正常输出
Done!
```

## 📝 配置更新

`~/.izshrc` 中已更新：

```bash
# 使用 PTY 版本
alias claude='python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper_pty.py /opt/homebrew/bin/claude'
```

## 🔄 使用方式（不变）

```bash
# 在 iZsh 中直接运行
[iZsh] ~% source ~/.izshrc  # 重新加载配置
[iZsh] ~% claude            # 使用新版本 wrapper
```

## 🎯 技术对比

| 特性 | PIPE 版本 | PTY 版本 |
|------|-----------|----------|
| Claude Code 输出 | ❌ 不显示 | ✅ 正常显示 |
| 交互式功能 | ⚠️ 部分失效 | ✅ 完全正常 |
| AI 自动确认 | ✅ 正常 | ✅ 正常 |
| 颜色和格式 | ❌ 丢失 | ✅ 保留 |
| 性能 | ⚡ 略快 | ⚡ 正常 |

## 📚 相关文件

- `claude_code_wrapper_pty.py` - 新版本 wrapper（使用 PTY）
- `claude_code_wrapper.py` - 旧版本（保留，但不再使用）
- `~/.izshrc` - 配置文件（已更新为使用 PTY 版本）

---

**版本**: 2.2.0
**状态**: ✅ 生产就绪
**更新时间**: 2025-11-10
