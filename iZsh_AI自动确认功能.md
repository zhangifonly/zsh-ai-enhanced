# iZsh AI 自动确认功能

## 🎯 功能概述

iZsh 的 AI 自动确认功能可以智能处理交互式程序的确认提示，当运行 Claude Code 或其他需要用户确认的程序时：

### 支持的交互类型

1. **文本确认提示**（Y/n, yes/no, 1/2/3 等）
   - 显示倒计时（默认 3 秒）
   - 用户可以随时按键选择
   - 超时后 AI 自动分析并选择最佳选项

2. **交互式菜单**（箭头键导航）
   - 自动检测菜单界面（>、→、▶ 等标记）
   - AI 分析所有选项，选择最完整、最积极的方案
   - 自动发送箭头键导航到最佳选项
   - 自动按回车确认

3. **多方案选择**（带详细描述的选项）
   - 提取选项的完整描述
   - AI 综合评估每个方案的优缺点
   - 选择最完善、功能最全面的方案

## 🚀 使用方法

### 方法 1：使用 `ai_confirm` 函数（手动集成）

在您的 shell 脚本中直接调用：

```bash
#!/Users/zhangzhen/.local/bin/izsh

# 基本用法
result=$(ai_confirm "是否继续？" "Y/n" 3)

# 根据结果执行不同操作
if [[ "$result" =~ [Yy] ]]; then
    echo "用户选择继续"
else
    echo "用户选择取消"
fi
```

**参数说明**：
- 参数1：提示文本
- 参数2：选项描述（如 `Y/n`, `yes/no`, `1/2/3`）
- 参数3：超时秒数（可选，默认 3 秒）

### 方法 2：使用 `ai_auto_run` 包装命令

```bash
# 在 iZsh 中运行
ai_auto_run "claude-code"
```

这会设置环境变量 `IZSH_AI_AUTO_CONFIRM=1`，让子进程知道可以使用 AI 确认功能。

### 方法 3：使用 Claude Code 包装器（推荐）

#### 直接运行包装器

```bash
python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py claude-code
```

#### 使用便捷别名

在 iZsh 中已经配置了别名：

```bash
# 使用 AI 自动确认模式运行 Claude Code
claude-ai

# 等价于
# python3 ~/Documents/ClaudeCode/zsh/zsh/claude_code_wrapper.py claude-code
```

## 📺 效果展示

### 倒计时界面

```
是否继续安装？ [Y/n] (3s)
是否继续安装？ [Y/n] (2s)
是否继续安装？ [Y/n] (1s)
⏰ 超时，AI 正在分析最佳选项...
✅ AI 自动选择: Y
```

### 用户手动输入

```
是否继续安装？ [Y/n] (3s)
是否继续安装？ [Y/n] (2s) y    ← 用户按了 'y'
y
```

### Claude Code 文本确认示例

```bash
[iZsh] ~% claude-ai

🤖 AI 自动确认模式已启用
提示：所有确认将在 3 秒后自动由 AI 选择
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Welcome to Claude Code!
Do you want to enable telemetry? [Y/n] (3s) (2s) (1s)
⏰ 超时，AI 正在分析最佳选项...
✅ AI 自动选择: Y

Telemetry enabled.
...
```

### Claude Code 交互式菜单示例

```bash
[iZsh] ~% claude-ai

🤖 AI 自动确认模式已启用
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Choose your configuration:
  → Quick setup (5 minutes)
    Standard setup (recommended)
    Complete setup (all features)
    Custom setup

🔍 检测到交互式菜单，AI 正在分析...
✅ AI 选择: Complete setup (all features)
[AI 自动按↓↓键导航，然后按回车确认]

Starting complete setup...
```

### 多方案选择示例

```bash
Choose deployment strategy:
1) Rolling deployment - Zero downtime, gradual rollout
2) Blue-green deployment - Quick rollback capability
3) Canary release - Test with small percentage first (recommended)
4) Direct deployment - Immediate replacement (risky)

[1/2/3/4] (3s) (2s) (1s)
⏰ 超时，AI 正在分析最佳选项...
✅ AI 自动选择: 3

AI 选择理由：金丝雀发布是最稳妥的方案，可以在小范围验证后再全量发布
```

## ⚙️ 配置选项

### 环境变量

在 `~/.izshrc` 中配置：

```bash
# AI 自动确认超时（秒）
export IZSH_AI_CONFIRM_TIMEOUT=3  # 默认 3 秒

# 启用 AI 自动确认模式
export IZSH_AI_AUTO_CONFIRM=1     # 1=启用, 0=禁用
```

### 自定义超时时间

```bash
# 临时设置 5 秒超时
export IZSH_AI_CONFIRM_TIMEOUT=5
claude-ai

# 或者在调用时指定
ai_confirm "是否继续？" "Y/n" 5
```

## 🔧 技术实现

### ai_confirm 函数流程

```
┌─────────────────────────────────┐
│   显示提示和选项                 │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│   开始倒计时 (3s, 2s, 1s...)    │
│   动态刷新同一行                 │
└────────┬──────────────┬─────────┘
         │              │
    用户输入          超时
         │              │
         ▼              ▼
┌────────────┐    ┌──────────────┐
│ 返回用户   │    │ 调用 AI 分析 │
│ 选择       │    │ 选择最佳选项 │
└────────────┘    └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │ 返回 AI 选择 │
                  └──────────────┘
```

### Claude Code 包装器流程

```
┌────────────────────────────────┐
│  启动 Claude Code 进程         │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│  逐字符读取输出                 │
│  检测确认提示模式               │
└───────┬────────────────────────┘
        │
        ▼
  检测到提示？
        │
    是  │  否
        ▼
┌────────────────┐      ┌─────────────┐
│ 调用 ai_confirm│      │ 继续读取输出│
│ 获取 AI 选择   │      │             │
└───────┬────────┘      └─────────────┘
        │
        ▼
┌────────────────────────────────┐
│  发送选择到 Claude Code        │
│  继续处理后续输出               │
└────────────────────────────────┘
```

### 支持的确认提示模式

#### 1. 文本确认模式

| 模式 | 示例 |
|------|------|
| `[Y/n]` | "Continue? [Y/n]" |
| `[yes/no]` | "Proceed? [yes/no]" |
| `[1/2/3]` | "Select option: [1/2/3]" |
| `[continue/cancel]` | "Action: [continue/cancel]" |
| `[c/q]` | "Continue or quit? [c/q]" |
| `[a/r/s/k]` | "Approve/Reject/Skip/Kill? [a/r/s/k]" |

#### 2. 交互式菜单模式

自动检测以下菜单标记：

| 标记类型 | 符号 | 示例 |
|---------|------|------|
| 箭头指示器 | `>` `→` `▶` | `→ Option 1` |
| 选中标记 | `*` `●` `■` | `* Selected item` |
| 高亮文本 | ANSI 转义序列 | 反色/加粗显示 |

**处理流程**：
1. 检测菜单标记（箭头、星号等）
2. 提取所有菜单项的文本
3. AI 分析选择最佳项
4. 计算需要按多少次↑/↓键
5. 自动导航并按回车确认

#### 3. 带描述的选项模式

```
1) Quick install - Default settings, 5 minutes
2) Standard install - Recommended, common features
3) Complete install - All features including docs
4) Custom install - Manual component selection
```

**AI 处理**：
- 提取每个选项的编号和完整描述
- 分析描述中的关键词（推荐、默认、完整等）
- 综合评估选择最佳方案

## 💡 AI 选择策略

AI 会根据提示内容智能选择：

### 核心原则

1. **完整性优先**：选择功能最全面、最完整的方案
   - 例如："完整安装" > "标准安装" > "最小安装"

2. **推荐优先**：有明确"推荐"或"默认"标记时优先考虑
   - 例如：标记为 "(recommended)" 或 "(default)" 的选项

3. **积极原则**：选择能让程序继续执行的选项
   - 例如："继续" > "跳过" > "取消"

4. **安全平衡**：在完整性和安全性之间找到平衡
   - 例如：高安全级别 + 完整功能

5. **稳妥策略**：避免风险最高的选项
   - 例如："金丝雀发布" > "直接部署"

### 简单确认示例

| 提示 | 选项 | AI 选择 | 理由 |
|------|------|---------|------|
| "是否继续安装？" | Y/n | **Y** | 继续执行原则 |
| "是否删除所有文件？" | Y/n | **n** | 安全原则 |
| "选择模式：1)快速 2)标准 3)详细" | 1/2/3 | **2** | 标准模式兼顾性能和功能 |
| "是否启用遥测？" | Y/n | **Y** | 有助于改进软件 |
| "是否覆盖现有配置？" | Y/n | **n** | 保护现有数据 |

### 多方案选择示例

| 场景 | 选项 | AI 选择 | 理由 |
|------|------|---------|------|
| **安装模式** | 1)快速 2)标准 3)完整 4)自定义 | **3 完整** | 功能最全面 |
| **配置方案** | 1)最小 2)推荐 3)完整 | **2 推荐** | 有明确推荐标记 |
| **部署策略** | 1)滚动 2)蓝绿 3)金丝雀 4)直接 | **3 金丝雀** | 最稳妥的方案 |
| **安全级别** | 1)基础 2)标准 3)高级 4)最高 | **4 最高** | 安全性最完善 |
| **性能配置** | 1)性能 2)平衡 3)功能 | **2 平衡** | 兼顾性能和功能 |

### 交互式菜单示例

```
→ Quick setup (5 minutes)
  Standard setup (recommended)
  Complete setup (all features)
  Custom setup
```

**AI 分析**：
- Quick: 速度快但功能少
- Standard: 有推荐标记
- **Complete: 功能最全面** ← AI 选择
- Custom: 需要手动配置

**结果**：AI 选择 "Complete setup"（完整性优先原则）

## 🧪 测试

### 运行测试脚本

```bash
cd ~/Documents/ClaudeCode/zsh/zsh
./test_ai_confirm.sh
```

测试内容：
1. 基本确认（等待用户输入）
2. 超时自动选择
3. 多选项确认
4. 模拟交互式安装程序

### 手动测试

在 iZsh 中：

```bash
# 测试基本功能
result=$(ai_confirm "测试提示" "Y/n" 3)
echo "结果: $result"

# 测试 Claude Code 包装器
claude-ai --version
```

## 📚 集成到您的脚本

### 示例 1：安装脚本

```bash
#!/Users/zhangzhen/.local/bin/izsh

echo "开始安装 MyApp..."

# 许可协议
license=$(ai_confirm "是否接受许可协议？" "Y/n" 3)
if [[ ! "$license" =~ [Yy] ]]; then
    echo "安装已取消"
    exit 1
fi

# 安装位置
location=$(ai_confirm "安装到默认位置？" "Y/n" 3)
if [[ "$location" =~ [Yy] ]]; then
    INSTALL_DIR="/usr/local"
else
    echo "请输入安装目录："
    read INSTALL_DIR
fi

# 快捷方式
shortcut=$(ai_confirm "创建桌面快捷方式？" "Y/n" 3)

echo "开始安装..."
# ... 安装逻辑 ...
echo "安装完成！"
```

### 示例 2：批量操作脚本

```bash
#!/Users/zhangzhen/.local/bin/izsh

for file in *.log; do
    echo "处理文件: $file"

    # AI 自动决定是否处理每个文件
    action=$(ai_confirm "处理 $file？" "Y/n/s(skip all)" 2)

    case "$action" in
        [Yy])
            echo "处理 $file..."
            # 处理逻辑
            ;;
        [Ss])
            echo "跳过所有剩余文件"
            break
            ;;
        *)
            echo "跳过 $file"
            ;;
    esac
done
```

## ⚠️ 注意事项

### 1. 安全考虑

AI 自动确认功能虽然方便，但对于敏感操作请谨慎使用：

```bash
# 不推荐：自动确认删除操作
# ai_confirm "删除所有文件？" "Y/n" 3

# 推荐：手动确认危险操作
echo "删除所有文件？[Y/n]"
read response
```

### 2. 超时设置

超时时间建议：
- **开发/测试**：3-5 秒（默认）
- **自动化脚本**：1-2 秒（快速）
- **重要操作**：5-10 秒（给用户足够时间）

### 3. 兼容性

- ✅ **支持**：iZsh 原生脚本
- ✅ **支持**：通过包装器运行的任何程序
- ⚠️ **限制**：需要程序使用标准输入/输出进行交互
- ❌ **不支持**：GUI 确认对话框

## 🎊 总结

iZsh AI 自动确认功能：

- ✅ **智能决策**：AI 自动选择最佳选项
- ✅ **用户友好**：倒计时清晰，可随时中断
- ✅ **易于集成**：简单的函数调用或包装器
- ✅ **灵活配置**：可自定义超时和行为
- ✅ **安全可靠**：超时失败有默认值

完美适配 Claude Code 等交互式程序，让您的工作流程更加流畅！🚀

---

**版本**: 1.0.0
**发布日期**: 2025-11-10
**状态**: 生产就绪 ✅
