# HTTP API 客户端实现 - 操作日志

## 任务概述
为 iZsh AI 模块实现 HTTP API 客户端功能，支持调用 OpenAI 兼容的 API。

## 阶段 0: 深度分析与上下文收集

### 时间: 2025-11-10

### 完成的工作

#### 1. 上下文收集（已完成）

**已查阅的文件:**
- ✅ `Src/Modules/ai.c` - AI 模块当前实现
- ✅ `Src/Modules/ai.mdd` - AI 模块描述文件
- ✅ `Src/Modules/pcre.c` - 外部库集成参考
- ✅ `Src/Modules/pcre.mdd` - PCRE 模块配置参考
- ✅ `Src/Modules/tcp.c` - 网络编程和异步处理参考
- ✅ `Src/Modules/tcp.mdd` - TCP 模块配置
- ✅ `configure.ac` - 构建系统配置 (PCRE 外部库检测部分)

**项目模式提取:**
1. **外部库集成模式** (从 pcre 模块学习):
   - configure.ac 中添加 AC_ARG_ENABLE 选项
   - 使用 AC_CHECK_PROG 检测库配置工具
   - 使用 AC_CHECK_HEADERS 检测头文件
   - 使用 AC_CHECK_FUNCS 检测函数
   - .mdd 文件中使用条件编译

2. **网络编程模式** (从 tcp 模块学习):
   - 使用 poll/select 进行异步 I/O
   - 提供跨平台兼容性封装
   - 完善的错误处理

3. **Zsh 模块开发模式**:
   - 使用 Zsh 内存管理 API (ztrdup, zsfree)
   - 使用 BUILTIN 宏注册命令
   - 模块生命周期: setup_ → boot_ → cleanup_ → finish_

#### 2. 技术选型决策

**HTTP 客户端: libcurl** ✅
- 理由:
  - 成熟稳定，支持 HTTPS/SSL
  - 跨平台兼容性好
  - 错误处理完善
  - AI API 需要复杂的 HTTP header 管理
- 替代方案: fork + curl 命令 (实现简单但功能受限)

**JSON 解析库: cJSON** ✅
- 理由:
  - 单文件实现，可直接嵌入模块
  - 支持 JSON 构建和解析
  - MIT 许可，无依赖冲突
  - API 简单易用
- 替代方案: jansson (功能全但需要独立编译), jsmn (仅解析)

**异步处理: fork + pipe** ✅
- 理由:
  - 实现简单可靠
  - 进程隔离，不影响 shell 状态
  - API 调用耗时长 (1-5秒)，fork 开销可接受
- 替代方案: pthread (需要线程安全处理), 非阻塞 I/O (实现复杂)

#### 3. 识别的关键疑问

**高优先级疑问:**

1. ✅ **如何在 configure.ac 中添加 libcurl 检测?**
   - 解答: 参考 pcre 模块，使用 AC_CHECK_LIB 和 AC_CHECK_HEADERS
   - 需要: AC_CHECK_LIB(curl, curl_easy_init)
   - 需要: AC_CHECK_HEADERS(curl/curl.h)

2. ✅ **如何在 .mdd 文件中声明库依赖?**
   - 解答: 使用条件编译，参考 pcre.mdd
   - 示例: `link=\`if test x$enable_curl = xyes; then echo dynamic; else echo no; fi\``
   - 注意: config.modules 自动生成，不手动编辑

3. ✅ **Zsh 是否有内置的异步任务机制?**
   - 解答: Zsh 有后台任务管理 (jobs)
   - 参考: tcp 模块使用 poll/select
   - 实现: fork 子进程 + pipe 通信，父进程轮询 pipe

4. ⚠️ **如何设计统一的 API 抽象层支持多种后端?**
   - OpenAI 格式: POST /v1/chat/completions
   - Claude 格式: POST /v1/messages
   - Ollama 格式: POST /api/generate
   - 策略: 根据 API_URL 自动识别，或提供 IZSH_AI_API_TYPE 配置

5. ⚠️ **缓存键如何生成? 如何实现 LRU?**
   - 缓存键: prompt + model + parameters 的 hash
   - LRU 实现: 双向链表 + 哈希表
   - 存储: 内存缓存 (首选) vs 文件系统

**中优先级疑问:**

6. ⚠️ **如何处理 API 调用超时?**
   - libcurl 提供 CURLOPT_TIMEOUT 选项
   - 默认值: 30 秒
   - 需要提供配置项: IZSH_AI_TIMEOUT

7. ⚠️ **如何防止 API key 泄漏到日志?**
   - 不在错误信息中输出完整 API key
   - 仅显示前几位: sk-***
   - 清理内存中的 API key (zsfree)

**低优先级疑问:**

8. **如何实现异步结果通知?**
   - 选项1: 轮询子进程状态
   - 选项2: 使用 Zsh 钩子函数
   - 选项3: 直接阻塞等待 (MVP 阶段)

9. **是否需要支持流式响应 (SSE)?**
   - OpenAI/Claude 支持流式返回
   - 实现: libcurl 的 CURLOPT_WRITEFUNCTION 回调
   - 决策: MVP 不支持，后续增强

#### 4. 充分性检查

**检查结果:**

- ✅ **我能定义清晰的接口契约吗?**
  - HTTP 请求: URL, headers (Authorization, Content-Type), body (JSON)
  - HTTP 响应: status code, body (JSON)
  - 接口抽象: ai_http_request(url, api_key, prompt) → response_text

- ✅ **我理解关键技术选型的理由吗?**
  - libcurl: HTTPS 支持 + 成熟稳定
  - cJSON: 单文件 + 易集成
  - fork+pipe: 简单可靠 + 进程隔离

- ⚠️ **我识别了主要风险点吗?**
  - 网络错误: 超时、连接失败、DNS
  - HTTP 错误: 4xx (认证失败), 5xx (服务器错误)
  - JSON 错误: 解析失败、格式异常
  - 安全: API key 泄漏、SSL 证书验证
  - 性能: 缓存策略、并发控制

- ✅ **我知道如何验证实现吗?**
  - 单元测试: 使用本地 mock HTTP server
  - 集成测试: 调用真实 API (需要测试 key)
  - 测试文件: Test/V01ai.ztst

**决策: 可以进入任务规划阶段** ✅

需要补充的信息:
- [ ] 多种 API 后端的统一抽象设计
- [ ] 缓存 LRU 实现细节
- [ ] 异步结果通知机制

这些信息可以在规划和实施阶段逐步完善。

## 下一步行动

1. 使用 sequential-thinking 工具进行深度分析
2. 制定详细的实现计划 (4 个 MVP 阶段)
3. 开始 MVP 1 实现: 基础 HTTP 调用

## 风险和缓解措施

### 风险 1: libcurl 可能在某些系统上不可用
- 缓解: configure 时检测，不可用时禁用模块
- 备用方案: 提供 fork + curl 命令的简化实现

### 风险 2: API 格式差异较大，难以统一
- 缓解: 先支持 OpenAI 格式，后续逐步扩展
- 设计: 使用策略模式，每种后端一个处理函数

### 风险 3: 异步处理可能影响 shell 稳定性
- 缓解: 使用进程隔离 (fork)，避免共享状态
- 测试: 充分测试各种异常情况

### 风险 4: 内存泄漏
- 缓解: 严格使用 Zsh 内存管理 API
- 测试: 使用 valgrind 检测内存泄漏

## 代码质量检查点

- [ ] 所有字符串使用 ztrdup/zsfree
- [ ] 所有错误使用 zwarnnam 报告
- [ ] 所有外部库调用检查返回值
- [ ] 所有内存分配检查失败情况
- [ ] 所有条件编译使用 #ifdef
- [ ] 代码风格符合项目规范 (4 空格缩进, K&R 风格)
