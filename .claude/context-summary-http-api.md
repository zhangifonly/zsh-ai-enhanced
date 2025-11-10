# 项目上下文摘要（HTTP API 客户端实现）
生成时间: 2025-11-10

## 1. 相似实现分析

### 实现1: pcre 模块 (Src/Modules/pcre.c)
- **模式**: 外部库集成模式
- **可复用**:
  - configure.ac 中的外部库检测机制 (--enable-pcre, PCRE_CONFIG)
  - .mdd 文件中的条件编译配置
  - 库依赖的 LIBS 和 CPPFLAGS 配置方式
- **需注意**:
  - 使用 AC_CHECK_PROG 检测库工具 (pcre2-config)
  - 使用 AC_CHECK_HEADERS 检测头文件
  - 使用 AC_CHECK_FUNCS 检测函数可用性
  - 条件编译: `link=\`if test x$enable_pcre = xyes; then echo dynamic; else echo no; fi\``

### 实现2: tcp 模块 (Src/Modules/tcp.c)
- **模式**: 网络编程模式，使用系统调用
- **可复用**:
  - poll/select 异步 I/O 处理方式
  - 错误处理和 h_errno 处理
  - inet_ntop/inet_aton 等网络工具函数的兼容性封装
- **需注意**:
  - 使用 #ifdef HAVE_POLL_H 等条件编译保证跨平台
  - 提供了 RFC 2553 接口的模拟实现
  - 使用 zsh_inet_ntop 等封装函数

### 实现3: ai 模块当前状态 (Src/Modules/ai.c)
- **模式**: 配置管理 + 占位符命令
- **已有功能**:
  - 环境变量读取 (getsparam)
  - 字符串内存管理 (ztrdup, zsfree)
  - 命令注册 (BUILTIN 宏)
  - 参数拼接 (zjoin)
- **需扩展**:
  - HTTP API 调用
  - JSON 解析
  - 异步处理
  - 缓存机制

## 2. 项目约定

### 命名约定
- 模块名: `zsh/模块名` (如 zsh/ai, zsh/pcre, zsh/net/tcp)
- 函数名: `bin_命令名` (内置命令), `模块前缀_函数名` (内部函数)
- 静态变量: 使用 static 关键字
- 导出函数: 使用 `/**/` 和 `mod_export`

### 文件组织
- 每个模块需要:
  - `.c` 文件: 实现代码
  - `.mdd` 文件: 模块描述文件
  - `.mdh` 和 `.pro` 自动生成的头文件
- 模块目录: `Src/Modules/` 或 `Src/Builtins/`

### 导入顺序
- 先包含模块自己的 `.mdh` 头文件
- 再包含 `.pro` 原型文件
- 系统头文件使用条件编译 (#ifdef)

### 代码风格
- 缩进: 4 空格
- 大括号: K&R 风格
- 注释: `/* 多行注释 */`
- 错误提示: 使用 zwarnnam 函数

## 3. 可复用组件清单

### Zsh 内部 API
- `getsparam(name)`: 获取字符串参数/环境变量
- `ztrdup(str)`: 复制字符串 (使用 zsh 内存管理)
- `zsfree(ptr)`: 释放字符串
- `zjoin(args, sep, heap)`: 拼接字符串数组
- `zwarnnam(nam, fmt, ...)`: 输出警告信息
- `unmetafy(str, &len)`: 去除元字符编码

### 构建系统工具
- `configure.ac`: AC_ARG_ENABLE, AC_CHECK_PROG, AC_CHECK_HEADERS, AC_CHECK_FUNCS
- `config.modules`: 模块编译配置 (自动生成，不手动编辑)
- `.mdd` 文件: 定义模块属性和依赖

### 网络相关
- `tcp.c` 中的 poll/select 异步处理示例
- 跨平台兼容性封装 (HAVE_POLL, HAVE_INET_NTOP 等)

## 4. 测试策略

### 测试框架
- Zsh 内置测试: `Test/` 目录下的 `.ztst` 文件
- 测试命名: `[类别][编号][名称].ztst` (如 V01ai.ztst)
- 测试类别 V: 模块测试

### 测试模式
- 加载模块: `zmodload zsh/ai`
- 调用命令: `ai "test question"`
- 验证输出: 使用 `ZTST` 测试框架的断言

### Mock 策略
- 可以通过环境变量注入测试配置
- 可以使用本地 HTTP server 进行集成测试
- 单元测试可以 mock HTTP 响应

## 5. 依赖和集成点

### 外部依赖（计划引入）
- **libcurl**: HTTP 客户端库
  - 需要添加 configure 检测: AC_CHECK_LIB(curl, curl_easy_init)
  - 需要添加头文件检测: AC_CHECK_HEADERS(curl/curl.h)
  - 链接标志: -lcurl

- **JSON 解析库**（待选择）:
  - 选项1: cJSON (轻量、单文件、MIT 许可)
  - 选项2: jansson (功能全、内存管理好)
  - 选项3: jsmn (最小化、无动态内存)

### 内部依赖
- Zsh 核心 API (已在 ai.c 中使用)
- 内存管理: zalloc, zfree, ztrdup, zsfree
- 字符串处理: zjoin, unmetafy, metafy

### 集成方式
- 模块动态加载: 用户通过 `zmodload zsh/ai` 加载
- 配置读取: 启动时从环境变量读取配置
- 命令注册: 通过 BUILTIN 宏注册到 shell

### 配置来源
- 环境变量:
  - IZSH_AI_ENABLED
  - IZSH_AI_API_KEY
  - IZSH_AI_API_URL
  - IZSH_AI_MODEL
  - IZSH_AI_CACHE_ENABLED
  - IZSH_AI_CACHE_SIZE

## 6. 技术选型理由

### HTTP 客户端: libcurl vs 系统调用
- **libcurl 优势**:
  - 成熟稳定，广泛使用
  - 支持 HTTPS、SSL/TLS
  - 错误处理完善
  - 性能优化（连接复用、超时控制）
  - 跨平台兼容性好

- **系统调用 (fork + curl 命令) 优势**:
  - 零编译依赖
  - 实现简单
  - 隔离性好（进程隔离）

- **建议**: 使用 libcurl
  - 理由: AI API 调用需要 HTTPS 和复杂的 HTTP header 管理，libcurl 更合适
  - 风险缓解: configure 时检测 libcurl，不可用时禁用模块

### JSON 解析库: cJSON vs jansson vs jsmn
- **cJSON**:
  - 单文件实现，易于集成
  - API 简单
  - MIT 许可
  - 支持构建和解析

- **jansson**:
  - 功能完整
  - 内存管理优秀
  - 需要独立编译

- **jsmn**:
  - 最小化
  - 无动态内存分配
  - 仅解析，不构建

- **建议**: 使用 cJSON
  - 理由: 需要同时支持 JSON 构建（请求）和解析（响应），cJSON 单文件集成最方便
  - 风险缓解: 可以将 cJSON 源码直接包含在模块中，避免外部依赖

### 异步处理: fork+pipe vs pthread vs 非阻塞I/O
- **fork + pipe**:
  - 简单可靠
  - 进程隔离，避免污染 shell 状态
  - 适合长时间运行的任务

- **pthread**:
  - 共享内存，通信方便
  - 需要线程安全处理
  - Zsh 内部可能不是线程安全的

- **非阻塞 I/O + select/poll**:
  - 高性能
  - 实现复杂
  - 需要事件循环

- **建议**: 使用 fork + pipe
  - 理由: API 调用耗时长（1-5秒），fork 的开销可接受，且实现简单可靠
  - 参考: tcp 模块中的异步处理模式

## 7. 关键风险点

### 并发问题
- API 调用期间 shell 可能执行其他命令
- 需要异步回调机制通知用户结果
- 缓存访问需要考虑并发安全

### 边界条件
- API 调用超时 (5-30秒)
- 网络不可用
- API 返回错误 (4xx, 5xx)
- JSON 格式异常
- API key 未配置或无效
- 响应内容过大

### 性能瓶颈
- 每次调用 1-5 秒延迟
- 需要缓存机制减少重复调用
- 缓存大小控制 (LRU 策略)

### 安全考虑
- API key 不应泄漏到日志
- 需要验证 SSL/TLS 证书
- 防止命令注入
- 内存泄漏和缓冲区溢出

## 8. API 格式对比

### OpenAI API
```json
POST /v1/chat/completions
{
  "model": "gpt-3.5-turbo",
  "messages": [{"role": "user", "content": "question"}],
  "temperature": 0.7
}
```

### Claude API (Anthropic)
```json
POST /v1/messages
{
  "model": "claude-3-sonnet-20240229",
  "messages": [{"role": "user", "content": "question"}],
  "max_tokens": 1024
}
```

### Ollama API
```json
POST /api/generate
{
  "model": "llama2",
  "prompt": "question"
}
```

### 统一抽象设计
- 需要设计统一的请求构建接口
- 根据 API_URL 自动识别后端类型
- 或者提供 IZSH_AI_API_TYPE 配置项

## 9. 实现里程碑

### MVP 1: 基础 HTTP 调用
- [ ] 添加 libcurl 依赖检测到 configure.ac
- [ ] 更新 ai.mdd 添加库链接
- [ ] 实现同步 HTTP POST 调用
- [ ] 基础错误处理 (网络错误、HTTP 错误)
- [ ] 测试: 调用真实 API 并输出原始响应

### MVP 2: JSON 处理
- [ ] 集成 cJSON 库
- [ ] 实现 JSON 请求构建
- [ ] 实现 JSON 响应解析
- [ ] 提取 AI 回复内容
- [ ] 测试: 完整的问答流程

### MVP 3: 异步处理
- [ ] 实现 fork + pipe 异步调用
- [ ] 使用 Zsh 后台任务机制
- [ ] 异步结果通知 (钩子函数或回调)
- [ ] 测试: 调用期间 shell 可继续使用

### MVP 4: 缓存机制
- [ ] 实现缓存键生成 (prompt hash)
- [ ] 内存缓存 (LRU)
- [ ] 缓存命中/未命中统计
- [ ] 测试: 重复查询使用缓存

## 10. 开源参考实现

建议搜索的项目:
- [ ] GitHub 搜索 "curl json c" 查找 C 语言中使用 libcurl + JSON 的示例
- [ ] 查找其他 shell 的 AI 集成实现 (如 fish, bash)
- [ ] 查找 OpenAI API C 客户端实现
- [ ] 查找 Zsh 模块开发教程和示例

## 11. 编码前检查清单

- [x] 理解了 Zsh 模块构建系统
- [x] 知道如何添加外部库依赖 (参考 pcre 模块)
- [x] 理解了异步处理模式 (参考 tcp 模块)
- [x] 知道项目的命名约定和代码风格
- [x] 知道如何编写模块测试
- [ ] 选定了 HTTP 客户端库 (libcurl)
- [ ] 选定了 JSON 解析库 (cJSON)
- [ ] 选定了异步处理方案 (fork + pipe)
- [ ] 设计了统一的 API 抽象层
