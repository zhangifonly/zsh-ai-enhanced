# iZsh NewAPI 配置指南

## 📋 概述

本文档介绍如何配置 iZsh 使用 NewAPI 服务 (`https://q.quuvv.cn`)。

## ✅ 已完成的配置

### 1. iZsh 配置文件

**文件位置**：`~/.izshrc`

已配置内容：
```bash
# macOS 动态库路径
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib

# AI 功能开关
export IZSH_AI_ENABLED=1

# NewAPI 接口配置
export IZSH_AI_API_URL="https://q.quuvv.cn/v1"
export IZSH_AI_API_KEY="sk-RQxMGajqZMP6cqxZ4fI7D7fjWvMAm0ZfNUbJg4rzIeXa39SP"
export IZSH_AI_MODEL="claude-sonnet-4-5"

# 干预级别
export IZSH_AI_INTERVENTION_LEVEL="suggest"
```

### 2. 可用模型列表

NewAPI 服务支持以下 11 个模型：

| 模型 ID | 提供商 | 推荐 |
|---------|--------|------|
| `claude-sonnet-4-5-20250929` | custom | ⭐⭐⭐ |
| `claude-sonnet-4-5` | custom | ⭐⭐⭐ |
| `claude-3-5-sonnet-20241022` | vertex-ai | ⭐⭐ |
| `gpt-5-codex` | custom | ⭐⭐ |
| `gemini-2.5-pro` | custom | ⭐⭐ |
| `claude-haiku-4-5-20251001` | custom | ⭐ |
| `claude-3-5-haiku-20241022` | vertex-ai | ⭐ |
| `claude-3-7-sonnet-20250219` | vertex-ai | ⭐ |
| `claude-opus-4-1-20250805` | custom | ⭐ |
| `claude-opus-4-20250514` | vertex-ai | ⭐ |
| `claude-sonnet-4-20250514` | vertex-ai | ⭐ |

## ⚠️ 需要完成的配置

### 当前问题

运行 `ai` 命令时显示：
```
API 错误: 当前 API 不支持所选模型 claude-sonnet-4-5
```

或
```
API 错误: 该令牌无权访问模型 XXX
```

### 原因

NewAPI 使用**令牌级别的模型权限管理**。每个 API 令牌需要在管理后台**明确分配**模型访问权限。

## 🔧 配置步骤

### 步骤 1：登录 NewAPI 管理后台

1. 访问：**https://q.quuvv.cn**
2. 使用您的账号登录

### 步骤 2：找到令牌管理

1. 在管理后台找到 **"令牌管理"** 或 **"API Keys"** 菜单
2. 查找令牌：`sk-RQxMGajqZMP6cqxZ4fI7D7fjWvMAm0ZfNUbJg4rzIeXa39SP`

### 步骤 3：分配模型权限

1. 点击令牌的 **"编辑"** 或 **"权限"** 按钮
2. 在模型列表中勾选至少一个模型，推荐：
   - ✅ `claude-sonnet-4-5` (推荐，当前配置使用)
   - ✅ `gemini-2.5-pro` (备选)
   - ✅ `claude-3-5-sonnet-20241022` (备选)

### 步骤 4：保存配置

点击 **"保存"** 或 **"更新"** 按钮

### 步骤 5：验证配置

运行测试脚本：
```bash
cd ~/Documents/ClaudeCode/zsh/zsh
./test_newapi.sh
```

或直接测试：
```bash
izsh -c 'ai "你好"'
```

## ✅ 成功标志

配置成功后，您应该看到类似输出：
```
✨ iZsh AI 模块已加载
   干预级别: 建议
   API: https://q.quuvv.cn/v1
   模型: claude-sonnet-4-5
🤖 AI 助手正在思考...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
你好！我是一个AI助手...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🚀 使用方法

### 基本用法

```bash
# 启动 iZsh
izsh

# 询问问题
ai "如何查找大文件？"

# 命令建议
ai_suggest "mkdri test"

# 错误分析
ai_analyze "command not found: pthon"
```

### 切换模型

编辑 `~/.izshrc`，修改：
```bash
export IZSH_AI_MODEL="gemini-2.5-pro"  # 切换到 Gemini
```

### 切换 API 提供商

如果您有其他 API，可以在 `~/.izshrc` 中切换：

```bash
# 使用 OpenAI 官方 API
export IZSH_AI_API_URL="https://api.openai.com/v1"
export IZSH_AI_API_KEY="sk-your-openai-key"
export IZSH_AI_MODEL="gpt-4"
```

## 🐛 故障排查

### 问题 1：无权访问模型

**错误信息**：
```
API 错误: 该令牌无权访问模型 XXX
API 错误: 当前 API 不支持所选模型 XXX
```

**解决方案**：
1. 登录 NewAPI 后台
2. 为令牌分配该模型的权限
3. 或者切换到有权限的其他模型

### 问题 2：网络连接失败

**错误信息**：
```
curl_easy_perform() failed: Could not resolve host
```

**解决方案**：
1. 检查网络连接
2. 检查代理设置
3. 确认 API 地址正确

### 问题 3：库加载失败 (macOS)

**错误信息**：
```
Library not loaded: @rpath/libcurl.4.dylib
```

**解决方案**：
在 `~/.izshrc` 中添加：
```bash
export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib
```

### 问题 4：中文乱码

**错误信息**：
```
佃�好
```

**解决方案**：
确保终端使用 UTF-8 编码：
```bash
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
```

## 📊 调试模式

iZsh 已内置详细的调试输出，每次 API 调用都会显示：

```
[AI Debug] ========== API 请求 ==========
[AI Debug] URL: https://q.quuvv.cn/v1/chat/completions
[AI Debug] Model: claude-sonnet-4-5
[AI Debug] 请求 JSON: {...}
[AI Debug] ================================
[AI Debug] 正在发送请求...
[AI Debug] HTTP 状态码: 200
[AI Debug] ========== API 响应 ==========
[AI Debug] 响应长度: 1234 bytes
[AI Debug] 响应 JSON: {...}
[AI Debug] ================================
```

这些信息可以帮助诊断问题。

## 📁 重要文件

| 文件 | 说明 |
|------|------|
| `~/.izshrc` | iZsh 主配置文件 |
| `~/.izsh_ai_config` | AI 配置界面生成的配置 (可选) |
| `~/Documents/ClaudeCode/zsh/zsh/test_newapi.sh` | API 测试脚本 |
| `~/.local/bin/izsh` | iZsh 可执行文件 |

## 🔄 下一步

1. ✅ **完成 NewAPI 后台配置**（分配模型权限）
2. ✅ **测试 AI 功能**（`ai "测试问题"`）
3. ⏳ **探索高级功能**（命令纠错、智能建议）

## 📞 获取帮助

如果遇到问题：

1. 查看调试输出（stderr 中的 `[AI Debug]` 信息）
2. 运行测试脚本：`./test_newapi.sh`
3. 检查 NewAPI 后台的令牌配置
4. 确认余额充足（如果 NewAPI 需要付费）

## 🎉 总结

✅ **iZsh AI 功能已完全实现**
✅ **NewAPI 接口已配置**
⏳ **等待后台分配模型权限**

一旦完成后台配置，您就可以享受智能终端的强大功能了！
