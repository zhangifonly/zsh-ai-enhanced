# iZsh 日志系统使用指南

## 概述

iZsh 集成了完整的日志系统，记录所有重要操作，方便问题诊断和性能分析。

## 日志文件位置

所有日志文件保存在 `~/.izsh/logs/` 目录：

```
~/.izsh/logs/
├── startup.log       - 启动日志
├── ai.log            - AI 调用日志
├── command.log       - 命令执行日志
├── error.log         - 错误日志
├── debug.log         - 调试日志
├── performance.log   - 性能日志
```

## 快速使用

### 查看日志

```bash
# 查看所有类型日志（最近50行）
izsh-logs

# 查看特定类型日志
izsh-logs startup      # 启动日志
izsh-logs ai           # AI 调用日志
izsh-logs command      # 命令执行日志
izsh-logs error        # 错误日志
izsh-logs debug        # 调试日志
izsh-logs perf         # 性能日志

# 查看更多行
izsh-logs ai 100       # 查看AI日志最近100行
izsh-logs error 200    # 查看错误日志最近200行
```

### 实时监控日志

```bash
# 实时监控所有日志（类似 tail -f）
izsh-logs-tail

# 监控特定类型
izsh-logs-tail ai      # 监控AI调用
izsh-logs-tail error   # 监控错误
```

### 查看日志统计

```bash
izsh-logs-stat
```

输出示例：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 iZsh 日志统计
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

startup        :     45 行,     12 KB
ai             :    128 行,     34 KB
command        :    256 行,     56 KB
error          :      8 行,      2 KB
debug          :    512 行,    128 KB
performance    :    180 行,     25 KB

总大小: 257 KB

日志目录: /Users/zhangzhen/.izsh/logs
日志状态: ✅ 已启用
日志级别: INFO
```

### 清理日志

```bash
# 清理所有日志（需要确认）
izsh-logs-clean

# 强制清理（无需确认）
izsh-logs-clean -f
```

## 日志内容

### 启动日志 (startup.log)

记录 iZsh 启动过程：

```
[2025-11-11 13:00:00] [INFO] ========== iZsh 启动 ==========
[2025-11-11 13:00:00] [INFO] 版本: 1.0.0-izsh
[2025-11-11 13:00:00] [INFO] 用户: zhangzhen@zhangzhendeMacBook-Pro
[2025-11-11 13:00:00] [INFO] 工作目录: /Users/zhangzhen
[2025-11-11 13:00:00] [INFO] 日志级别: INFO
[2025-11-11 13:00:00] [INFO] 加载基础配置
[2025-11-11 13:00:00] [INFO] 历史文件: /Users/zhangzhen/.izsh_history
[2025-11-11 13:00:01] [INFO] 开始加载 AI 模块 zsh/ai
[2025-11-11 13:00:01] [INFO] ✅ AI 模块加载成功
[2025-11-11 13:00:02] [INFO] ========== iZsh 启动完成 ==========
```

### AI 调用日志 (ai.log)

记录所有 AI 翻译调用：

```
[2025-11-11 13:05:23] [INFO] 开始翻译: 列目录
[2025-11-11 13:05:24] [INFO] 翻译结果: ls (耗时: 856ms)
[2025-11-11 13:06:15] [INFO] 开始翻译: 查看文件内容 test.txt
[2025-11-11 13:06:16] [INFO] 翻译结果: cat test.txt (耗时: 923ms)
```

### 命令执行日志 (command.log)

记录命令执行情况：

```
[2025-11-11 13:05:23] [INFO] 命令未找到: 列目录
[2025-11-11 13:05:24] [INFO] 自动执行 (安全命令): ls
[2025-11-11 13:05:24] [INFO] 执行完成 (退出码: 0)
[2025-11-11 13:07:32] [INFO] 命令未找到: 删除文件 old.txt
[2025-11-11 13:07:33] [INFO] 危险命令，等待用户确认: rm old.txt
[2025-11-11 13:07:35] [INFO] 用户确认执行: rm old.txt
[2025-11-11 13:07:35] [INFO] 执行完成 (退出码: 0)
```

### 错误日志 (error.log)

记录所有错误：

```
[2025-11-11 13:10:45] [ERROR] AI翻译失败: 无响应
[2025-11-11 13:15:20] [ERROR] AI 模块未加载
[2025-11-11 13:20:33] [ERROR] 命令执行失败: 退出码 1
```

### 性能日志 (performance.log)

记录操作耗时：

```
[2025-11-11 13:05:24] [INFO] AI翻译: 856ms
[2025-11-11 13:06:16] [INFO] AI翻译: 923ms
[2025-11-11 13:08:42] [INFO] AI翻译: 1245ms
```

## 配置选项

### 环境变量

在 `~/.izshrc` 中配置：

```bash
# 是否启用日志（默认启用）
export IZSH_LOGGING_ENABLED=1

# 日志级别（DEBUG, INFO, WARN, ERROR）
export IZSH_LOG_LEVEL=INFO

# 单个日志文件最大大小（字节，默认10MB）
export IZSH_LOG_MAX_SIZE=10485760
```

### 日志级别说明

- `DEBUG`: 记录所有日志，包括调试信息
- `INFO`: 记录一般信息、警告和错误
- `WARN`: 仅记录警告和错误
- `ERROR`: 仅记录错误

### 临时禁用日志

```bash
# 临时禁用日志
export IZSH_LOGGING_ENABLED=0

# 重新启用
export IZSH_LOGGING_ENABLED=1
```

### 启用调试日志

```bash
# 在 ~/.izshrc 中设置
export IZSH_LOG_LEVEL=DEBUG

# 或临时启用
IZSH_LOG_LEVEL=DEBUG izsh
```

## 日志轮转

日志系统自动进行日志轮转：

- 当日志文件超过 `IZSH_LOG_MAX_SIZE`（默认10MB）时自动轮转
- 轮转时保留最近的一半内容
- 无需手动管理

## 问题诊断示例

### 示例1：AI 翻译失败

```bash
# 1. 查看错误日志
izsh-logs error

# 2. 查看AI日志
izsh-logs ai 100

# 3. 检查启动日志确认AI模块是否加载
izsh-logs startup
```

### 示例2：命令执行异常

```bash
# 查看命令执行日志
izsh-logs command 50

# 查看错误日志
izsh-logs error
```

### 示例3：性能问题

```bash
# 查看性能日志
izsh-logs perf 100

# 查找耗时超过1秒的操作
grep -E '[0-9]{4,}ms' ~/.izsh/logs/performance.log
```

## 最佳实践

1. **定期检查错误日志**
   ```bash
   izsh-logs error
   ```

2. **性能分析**
   ```bash
   izsh-logs perf 200 | grep "AI翻译"
   ```

3. **问题复现**
   - 启用DEBUG级别日志
   - 复现问题
   - 查看详细日志

4. **分享日志**
   - 需要帮助时，可以分享相关日志
   - 注意移除敏感信息（路径、用户名等）

5. **定期清理**
   ```bash
   # 每月清理一次
   izsh-logs-clean -f
   ```

## 常见问题

### Q: 日志文件太大怎么办？

A: 日志系统有自动轮转机制，但如果需要手动清理：
```bash
izsh-logs-clean -f
```

### Q: 如何查看历史日志？

A: 使用 `izsh-logs` 命令配合行数参数：
```bash
izsh-logs ai 1000  # 查看最近1000行
```

### Q: 日志影响性能吗？

A: 日志写入是异步的，对性能影响极小。如果需要极致性能，可以：
```bash
export IZSH_LOGGING_ENABLED=0
```

### Q: 如何导出日志？

A: 直接复制日志文件：
```bash
cp -r ~/.izsh/logs ~/Desktop/izsh_logs_backup
```

## 高级用法

### 自定义日志分析

```bash
# 统计AI调用次数
grep "开始翻译" ~/.izsh/logs/ai.log | wc -l

# 统计成功率
total=$(grep "开始翻译" ~/.izsh/logs/ai.log | wc -l)
success=$(grep "翻译结果" ~/.izsh/logs/ai.log | wc -l)
echo "成功率: $((success * 100 / total))%"

# 计算平均响应时间
grep "耗时" ~/.izsh/logs/ai.log | \
  sed 's/.*耗时: \([0-9]*\)ms.*/\1/' | \
  awk '{sum+=$1; count++} END {print "平均耗时:", sum/count, "ms"}'
```

### 日志搜索

```bash
# 搜索特定命令的日志
grep "ls" ~/.izsh/logs/command.log

# 搜索错误关键词
grep -i "error\|fail\|exception" ~/.izsh/logs/*.log

# 查找特定时间段的日志
grep "2025-11-11 13:" ~/.izsh/logs/ai.log
```

## 参考

- 日志目录：`~/.izsh/logs/`
- 配置文件：`~/.izshrc`
- 日志模块：`~/.izsh/logging.sh`
