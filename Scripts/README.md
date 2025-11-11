# iZsh Scripts 脚本集合

本目录包含 iZsh 的辅助脚本和功能模块。

## 文件列表

### logging.sh
**完整的日志系统模块**

- 提供全面的日志记录功能
- 支持多种日志级别（DEBUG, INFO, WARN, ERROR）
- 自动日志轮转
- 日志查看和分析命令

**安装方法**：
```bash
# 复制到用户目录
cp Scripts/logging.sh ~/.izsh/

# 在 ~/.izshrc 中加载（通常已自动配置）
source ~/.izsh/logging.sh
```

**详细文档**：见 `LOG_USAGE.md`

### LOG_USAGE.md
**日志系统使用指南**

- 完整的使用文档
- 命令参考
- 问题诊断示例
- 最佳实践

## 日志系统快速开始

### 1. 安装日志系统

日志系统在 iZsh 安装时自动部署，无需手动安装。

### 2. 查看日志

```bash
# 查看所有日志
izsh-logs

# 查看特定类型
izsh-logs error      # 错误日志
izsh-logs ai         # AI调用日志
izsh-logs command    # 命令执行日志
```

### 3. 实时监控

```bash
# 实时监控所有日志
izsh-logs-tail

# 监控特定类型
izsh-logs-tail error
```

### 4. 日志统计

```bash
izsh-logs-stat
```

### 5. 清理日志

```bash
izsh-logs-clean
```

## 配置选项

在 `~/.izshrc` 中配置：

```bash
# 日志级别
export IZSH_LOG_LEVEL=INFO  # DEBUG, INFO, WARN, ERROR

# 禁用日志（不推荐）
export IZSH_LOGGING_ENABLED=0
```

## 日志文件位置

所有日志保存在 `~/.izsh/logs/`：

- `startup.log` - 启动日志
- `ai.log` - AI调用日志
- `command.log` - 命令执行日志
- `error.log` - 错误日志
- `debug.log` - 调试日志
- `performance.log` - 性能日志

## 问题诊断

### AI 翻译失败

```bash
# 1. 查看错误日志
izsh-logs error

# 2. 查看AI日志
izsh-logs ai 100

# 3. 检查启动日志
izsh-logs startup
```

### 性能问题

```bash
# 查看性能日志
izsh-logs perf

# 查找慢操作（>1秒）
grep -E '[0-9]{4,}ms' ~/.izsh/logs/performance.log
```

## 更多信息

- 详细文档：`LOG_USAGE.md`
- 源代码：`logging.sh`
- 问题反馈：https://github.com/zhangifonly/zsh-ai-enhanced/issues
