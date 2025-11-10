# HTTP API 客户端实现 - 深度分析

## 问题拆解

### 核心问题
如何为 Zsh AI 模块实现一个可靠、高效、安全的 HTTP API 客户端?

### 子问题分解

1. **构建系统集成**
   - 如何检测和链接 libcurl?
   - 如何处理 libcurl 不可用的情况?
   - 如何集成 cJSON (嵌入 vs 外部依赖)?

2. **HTTP 客户端实现**
   - 如何构建 HTTPS POST 请求?
   - 如何设置 HTTP headers (Authorization, Content-Type)?
   - 如何处理响应?
   - 如何处理错误和超时?

3. **JSON 处理**
   - 如何构建 JSON 请求体?
   - 如何解析 JSON 响应?
   - 如何提取 AI 回复内容?
   - 如何处理 JSON 格式错误?

4. **异步处理**
   - 如何避免阻塞 shell?
   - 如何实现父子进程通信?
   - 如何通知用户结果?

5. **多后端支持**
   - OpenAI, Claude, Ollama 的 API 格式差异?
   - 如何设计统一抽象?
   - 如何识别后端类型?

6. **缓存机制**
   - 如何生成缓存键?
   - 如何实现 LRU?
   - 缓存存储在哪里?

7. **错误处理**
   - 网络错误 (超时、连接失败)
   - HTTP 错误 (4xx, 5xx)
   - API 错误 (配额、认证)
   - JSON 错误 (解析失败)

8. **安全性**
   - API key 如何安全传递?
   - 如何防止泄漏到日志?
   - SSL/TLS 证书验证?

9. **测试**
   - 如何 mock HTTP 请求?
   - 如何测试异步流程?
   - 如何测试错误处理?

## 技术调研方向

### 1. libcurl 集成

**configure.ac 修改:**
```bash
# 添加 --enable-curl 选项
AC_ARG_ENABLE(curl,
  AS_HELP_STRING([--enable-curl],
    [enable libcurl for HTTP API support]))

# 检测 libcurl
if test "x$enable_curl" = xyes; then
  AC_CHECK_PROG([CURL_CONFIG], curl-config, curl-config)
  if test "x$CURL_CONFIG" = x; then
    enable_curl=no
    AC_MSG_WARN([curl-config not found: AI module HTTP support disabled.])
  else
    CURL_CFLAGS=`$CURL_CONFIG --cflags`
    CURL_LIBS=`$CURL_CONFIG --libs`
    CPPFLAGS="$CURL_CFLAGS $CPPFLAGS"
    LIBS="$CURL_LIBS $LIBS"
    AC_CHECK_HEADERS([curl/curl.h])
    AC_CHECK_FUNCS([curl_easy_init curl_easy_setopt curl_easy_perform])
  fi
fi
```

**ai.mdd 修改:**
```bash
name=zsh/ai
link=`if test x$enable_curl = xyes; then echo dynamic; else echo no; fi`
load=no

autofeatures="b:ai b:ai_suggest b:ai_analyze"

objects="ai.o"
```

### 2. cJSON 集成策略

**方案 A: 直接嵌入源码 (推荐)**
- 将 cJSON.c 和 cJSON.h 复制到 Src/Modules/
- 在 ai.mdd 中添加: `objects="ai.o cJSON.o"`
- 优点: 零外部依赖，构建简单
- 缺点: 需要维护 cJSON 代码副本

**方案 B: 外部库依赖**
- 类似 libcurl，使用 pkg-config 检测
- 优点: 使用系统库，版本管理方便
- 缺点: 增加依赖复杂度

**决策: 使用方案 A**

### 3. HTTP 请求实现

**基础结构:**
```c
/* HTTP 响应结构 */
struct http_response {
    char *body;       /* 响应体 */
    size_t body_len;  /* 响应体长度 */
    long status_code; /* HTTP 状态码 */
    char *error;      /* 错误信息 */
};

/* libcurl 写回调函数 */
static size_t
http_write_callback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    struct http_response *resp = (struct http_response *)userp;

    char *ptr = realloc(resp->body, resp->body_len + realsize + 1);
    if (!ptr) return 0;

    resp->body = ptr;
    memcpy(&(resp->body[resp->body_len]), contents, realsize);
    resp->body_len += realsize;
    resp->body[resp->body_len] = 0;

    return realsize;
}

/* HTTP POST 请求 */
static int
ai_http_post(const char *url, const char *api_key, const char *json_data,
             struct http_response *resp)
{
    CURL *curl;
    CURLcode res;
    struct curl_slist *headers = NULL;

    curl = curl_easy_init();
    if (!curl) return -1;

    /* 设置 URL */
    curl_easy_setopt(curl, CURLOPT_URL, url);

    /* 设置 headers */
    char auth_header[512];
    snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", api_key);
    headers = curl_slist_append(headers, auth_header);
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    /* 设置 POST 数据 */
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_data);

    /* 设置写回调 */
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, http_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)resp);

    /* 设置超时 */
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);

    /* 启用 SSL 证书验证 */
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);

    /* 执行请求 */
    res = curl_easy_perform(curl);

    /* 获取 HTTP 状态码 */
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &resp->status_code);

    /* 清理 */
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    return (res == CURLE_OK) ? 0 : -1;
}
```

### 4. JSON 处理

**请求构建 (OpenAI 格式):**
```c
static char *
ai_build_openai_request(const char *model, const char *prompt)
{
    cJSON *root = cJSON_CreateObject();
    cJSON *messages = cJSON_CreateArray();
    cJSON *message = cJSON_CreateObject();

    cJSON_AddStringToObject(message, "role", "user");
    cJSON_AddStringToObject(message, "content", prompt);
    cJSON_AddItemToArray(messages, message);

    cJSON_AddStringToObject(root, "model", model);
    cJSON_AddItemToObject(root, "messages", messages);
    cJSON_AddNumberToObject(root, "temperature", 0.7);

    char *json_str = cJSON_Print(root);
    cJSON_Delete(root);

    return json_str;
}
```

**响应解析 (OpenAI 格式):**
```c
static char *
ai_parse_openai_response(const char *json_str)
{
    cJSON *root = cJSON_Parse(json_str);
    if (!root) return NULL;

    cJSON *choices = cJSON_GetObjectItem(root, "choices");
    if (!cJSON_IsArray(choices) || cJSON_GetArraySize(choices) == 0) {
        cJSON_Delete(root);
        return NULL;
    }

    cJSON *choice = cJSON_GetArrayItem(choices, 0);
    cJSON *message = cJSON_GetObjectItem(choice, "message");
    cJSON *content = cJSON_GetObjectItem(message, "content");

    char *result = NULL;
    if (cJSON_IsString(content)) {
        result = ztrdup(content->valuestring);
    }

    cJSON_Delete(root);
    return result;
}
```

### 5. 多后端抽象设计

**策略模式:**
```c
/* API 后端类型 */
typedef enum {
    AI_BACKEND_OPENAI,
    AI_BACKEND_CLAUDE,
    AI_BACKEND_OLLAMA,
    AI_BACKEND_UNKNOWN
} ai_backend_type;

/* 后端操作接口 */
struct ai_backend_ops {
    ai_backend_type type;
    char *(*build_request)(const char *model, const char *prompt);
    char *(*parse_response)(const char *json_str);
    const char *endpoint;  /* API endpoint */
};

/* OpenAI 后端 */
static struct ai_backend_ops openai_ops = {
    .type = AI_BACKEND_OPENAI,
    .build_request = ai_build_openai_request,
    .parse_response = ai_parse_openai_response,
    .endpoint = "/v1/chat/completions"
};

/* Claude 后端 */
static struct ai_backend_ops claude_ops = {
    .type = AI_BACKEND_CLAUDE,
    .build_request = ai_build_claude_request,
    .parse_response = ai_parse_claude_response,
    .endpoint = "/v1/messages"
};

/* 根据 URL 识别后端 */
static struct ai_backend_ops *
ai_detect_backend(const char *url)
{
    if (strstr(url, "openai.com") || strstr(url, "api.openai"))
        return &openai_ops;
    if (strstr(url, "anthropic.com") || strstr(url, "claude"))
        return &claude_ops;
    if (strstr(url, "ollama"))
        return &openai_ops;  /* Ollama 兼容 OpenAI */

    /* 默认使用 OpenAI 格式 */
    return &openai_ops;
}
```

### 6. 异步处理 (fork + pipe)

**实现框架:**
```c
/* 异步 API 调用 */
static int
ai_async_call(const char *prompt)
{
    int pipefd[2];
    pid_t pid;

    /* 创建管道 */
    if (pipe(pipefd) == -1) {
        zwarnnam("ai", "failed to create pipe");
        return 1;
    }

    /* fork 子进程 */
    pid = fork();
    if (pid == -1) {
        zwarnnam("ai", "failed to fork");
        close(pipefd[0]);
        close(pipefd[1]);
        return 1;
    }

    if (pid == 0) {
        /* 子进程 */
        close(pipefd[0]);  /* 关闭读端 */

        /* 执行 API 调用 */
        struct http_response resp = {0};
        struct ai_backend_ops *backend = ai_detect_backend(ai_api_url);

        char *json_req = backend->build_request(ai_model, prompt);
        char full_url[1024];
        snprintf(full_url, sizeof(full_url), "%s%s", ai_api_url, backend->endpoint);

        if (ai_http_post(full_url, ai_api_key, json_req, &resp) == 0) {
            char *result = backend->parse_response(resp.body);
            if (result) {
                write(pipefd[1], result, strlen(result));
                zsfree(result);
            }
        }

        /* 清理并退出 */
        free(json_req);
        if (resp.body) free(resp.body);
        close(pipefd[1]);
        _exit(0);
    } else {
        /* 父进程 */
        close(pipefd[1]);  /* 关闭写端 */

        /* MVP 阶段: 阻塞等待结果 */
        char buffer[4096];
        ssize_t nread;

        printf("⏳ 正在调用 AI API...\n");

        while ((nread = read(pipefd[0], buffer, sizeof(buffer) - 1)) > 0) {
            buffer[nread] = '\0';
            printf("%s", buffer);
        }

        close(pipefd[0]);
        waitpid(pid, NULL, 0);
    }

    return 0;
}
```

**改进版 (非阻塞):**
- 使用 Zsh 的 addwatch() 注册文件描述符监听
- 当数据到达时触发回调函数
- 需要深入研究 Zsh 内部 API

### 7. 缓存机制

**缓存键生成:**
```c
/* 使用 MD5 或简单哈希 */
static unsigned long
ai_hash_string(const char *str)
{
    unsigned long hash = 5381;
    int c;

    while ((c = *str++))
        hash = ((hash << 5) + hash) + c;  /* hash * 33 + c */

    return hash;
}

static unsigned long
ai_cache_key(const char *prompt, const char *model)
{
    char combined[2048];
    snprintf(combined, sizeof(combined), "%s|%s", prompt, model);
    return ai_hash_string(combined);
}
```

**LRU 缓存结构:**
```c
/* 缓存条目 */
struct cache_entry {
    unsigned long key;
    char *prompt;
    char *response;
    time_t timestamp;
    struct cache_entry *prev;
    struct cache_entry *next;
};

/* LRU 缓存 */
static struct {
    struct cache_entry *head;  /* 最近使用 */
    struct cache_entry *tail;  /* 最久未使用 */
    int size;
    int max_size;
} ai_cache = {NULL, NULL, 0, 100};

/* 查找缓存 */
static char *
ai_cache_get(unsigned long key)
{
    struct cache_entry *entry = ai_cache.head;

    while (entry) {
        if (entry->key == key) {
            /* 移到链表头部 (最近使用) */
            if (entry != ai_cache.head) {
                /* 从当前位置移除 */
                entry->prev->next = entry->next;
                if (entry->next)
                    entry->next->prev = entry->prev;
                else
                    ai_cache.tail = entry->prev;

                /* 插入头部 */
                entry->prev = NULL;
                entry->next = ai_cache.head;
                ai_cache.head->prev = entry;
                ai_cache.head = entry;
            }

            return entry->response;
        }
        entry = entry->next;
    }

    return NULL;
}

/* 添加缓存 */
static void
ai_cache_put(unsigned long key, const char *prompt, const char *response)
{
    /* 如果已满，移除尾部 */
    if (ai_cache.size >= ai_cache.max_size) {
        struct cache_entry *old = ai_cache.tail;
        ai_cache.tail = old->prev;
        if (ai_cache.tail)
            ai_cache.tail->next = NULL;
        else
            ai_cache.head = NULL;

        zsfree(old->prompt);
        zsfree(old->response);
        zfree(old, sizeof(*old));
        ai_cache.size--;
    }

    /* 创建新条目并插入头部 */
    struct cache_entry *entry = (struct cache_entry *)zalloc(sizeof(*entry));
    entry->key = key;
    entry->prompt = ztrdup(prompt);
    entry->response = ztrdup(response);
    entry->timestamp = time(NULL);
    entry->prev = NULL;
    entry->next = ai_cache.head;

    if (ai_cache.head)
        ai_cache.head->prev = entry;
    else
        ai_cache.tail = entry;

    ai_cache.head = entry;
    ai_cache.size++;
}
```

### 8. 错误处理层次

**L1: 网络错误**
```c
if (res != CURLE_OK) {
    switch (res) {
        case CURLE_COULDNT_CONNECT:
            zwarnnam("ai", "无法连接到 API 服务器");
            break;
        case CURLE_OPERATION_TIMEDOUT:
            zwarnnam("ai", "API 调用超时");
            break;
        case CURLE_SSL_CONNECT_ERROR:
            zwarnnam("ai", "SSL 连接错误");
            break;
        default:
            zwarnnam("ai", "网络错误: %s", curl_easy_strerror(res));
    }
    return -1;
}
```

**L2: HTTP 错误**
```c
if (resp->status_code >= 400) {
    if (resp->status_code == 401) {
        zwarnnam("ai", "API 密钥无效或已过期");
    } else if (resp->status_code == 429) {
        zwarnnam("ai", "API 调用频率超限，请稍后再试");
    } else if (resp->status_code >= 500) {
        zwarnnam("ai", "API 服务器错误 (%ld)", resp->status_code);
    } else {
        zwarnnam("ai", "HTTP 错误 %ld", resp->status_code);
    }
    return -1;
}
```

**L3: API 错误**
```c
/* 解析 API 错误响应 */
cJSON *error = cJSON_GetObjectItem(root, "error");
if (error) {
    cJSON *message = cJSON_GetObjectItem(error, "message");
    if (cJSON_IsString(message)) {
        zwarnnam("ai", "API 错误: %s", message->valuestring);
    }
    return NULL;
}
```

**L4: JSON 解析错误**
```c
cJSON *root = cJSON_Parse(json_str);
if (!root) {
    const char *error_ptr = cJSON_GetErrorPtr();
    if (error_ptr) {
        zwarnnam("ai", "JSON 解析失败: %s", error_ptr);
    } else {
        zwarnnam("ai", "JSON 解析失败");
    }
    return NULL;
}
```

### 9. 安全性措施

**API key 保护:**
```c
/* 不在日志中输出完整 API key */
static void
ai_log_api_key_masked(const char *api_key)
{
    if (!api_key || strlen(api_key) < 8) {
        printf("API Key: (未设置)\n");
        return;
    }

    printf("API Key: %.6s***\n", api_key);
}

/* 清理内存中的敏感数据 */
static void
ai_clear_sensitive_data(char *data, size_t len)
{
    if (data) {
        memset(data, 0, len);
    }
}
```

**SSL 证书验证:**
```c
/* 默认启用，允许配置禁用 (不推荐) */
int verify_ssl = 1;
if ((env_val = getsparam("IZSH_AI_VERIFY_SSL"))) {
    verify_ssl = atoi(env_val);
}

curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, verify_ssl ? 1L : 0L);
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, verify_ssl ? 2L : 0L);
```

## 风险识别

### 高风险

1. **libcurl 不可用**
   - 影响: 模块无法编译
   - 概率: 中
   - 缓解: configure 检测，提供降级方案 (curl 命令)

2. **内存泄漏**
   - 影响: shell 长期运行性能下降
   - 概率: 中
   - 缓解: 严格使用 Zsh 内存 API，valgrind 测试

3. **API 调用阻塞 shell**
   - 影响: 用户体验差
   - 概率: 高 (MVP 阶段)
   - 缓解: 使用异步处理 (fork + pipe)

### 中风险

4. **多后端 API 格式差异**
   - 影响: 兼容性问题
   - 概率: 中
   - 缓解: 策略模式，逐步扩展

5. **缓存键冲突**
   - 影响: 返回错误的缓存结果
   - 概率: 低
   - 缓解: 使用强哈希算法，包含更多参数

6. **SSL 证书验证失败**
   - 影响: 无法调用 HTTPS API
   - 概率: 低
   - 缓解: 提供配置选项禁用验证 (不推荐)

### 低风险

7. **JSON 解析错误**
   - 影响: 无法提取 AI 回复
   - 概率: 低 (API 稳定)
   - 缓解: 完善错误处理，输出原始响应

8. **fork 失败**
   - 影响: 无法异步调用
   - 概率: 低
   - 缓解: 检测 fork 返回值，降级到同步调用

## 实现路径建议

### MVP 1: 基础 HTTP 调用 (1-2天)

**目标**: 实现同步 HTTP POST 调用，支持 OpenAI API

**任务清单**:
1. ✅ 修改 configure.ac 添加 libcurl 检测
2. ✅ 修改 ai.mdd 添加条件编译
3. ✅ 下载 cJSON.c 和 cJSON.h 到 Src/Modules/
4. ✅ 实现 http_write_callback 函数
5. ✅ 实现 ai_http_post 函数
6. ✅ 实现基础错误处理 (网络错误, HTTP 错误)
7. ✅ 测试: 调用真实 OpenAI API 并输出原始响应

**验收标准**:
- `ai "test question"` 能够调用 API 并输出原始 JSON 响应
- 网络错误和 HTTP 错误能够正确报告
- 不存在内存泄漏 (valgrind 检测)

### MVP 2: JSON 处理 (1-2天)

**目标**: 解析 JSON 响应，提取 AI 回复内容

**任务清单**:
1. ✅ 实现 ai_build_openai_request 函数
2. ✅ 实现 ai_parse_openai_response 函数
3. ✅ 集成 JSON 构建和解析到 bin_ai 命令
4. ✅ 实现 JSON 错误处理
5. ✅ 美化输出格式
6. ✅ 测试: 完整的问答流程

**验收标准**:
- `ai "你好"` 能够返回 AI 的回复文本
- JSON 解析错误能够正确报告
- 输出格式美观易读

### MVP 3: 异步处理 (2-3天)

**目标**: 使用 fork + pipe 实现异步调用，不阻塞 shell

**任务清单**:
1. ✅ 实现 ai_async_call 函数 (fork + pipe)
2. ✅ 实现父进程非阻塞读取 (使用 poll/select)
3. ✅ 添加进度提示
4. ✅ 实现错误传递 (子进程错误传递给父进程)
5. ✅ 测试: 调用期间 shell 可继续使用

**验收标准**:
- `ai "长问题"` 调用时 shell 不阻塞
- 结果返回时自动显示
- 异常退出不影响 shell 稳定性

### MVP 4: 缓存机制 (1-2天)

**目标**: 实现 LRU 缓存，减少重复 API 调用

**任务清单**:
1. ✅ 实现 ai_cache_key 函数
2. ✅ 实现 LRU 缓存数据结构
3. ✅ 实现 ai_cache_get 函数
4. ✅ 实现 ai_cache_put 函数
5. ✅ 集成到 bin_ai 命令
6. ✅ 添加缓存统计 (命中/未命中)
7. ✅ 测试: 重复查询使用缓存

**验收标准**:
- 相同问题第二次查询使用缓存 (即时返回)
- 缓存大小限制生效 (LRU 淘汰)
- 缓存命中率统计准确

### 后续增强 (可选)

1. **多后端支持**
   - 实现 Claude API 后端
   - 实现 Ollama API 后端
   - 自动后端检测

2. **流式响应**
   - 支持 SSE (Server-Sent Events)
   - 实时输出 AI 回复

3. **高级功能**
   - 对话历史管理
   - 多轮对话支持
   - 自定义 system prompt

4. **性能优化**
   - 连接池 (复用 CURL handle)
   - 并发控制 (限制同时调用数)
   - 缓存持久化 (保存到文件)

## 优先级排序

### P0 (必须完成)
1. MVP 1: 基础 HTTP 调用
2. MVP 2: JSON 处理
3. 错误处理和安全性

### P1 (高优先级)
4. MVP 3: 异步处理
5. MVP 4: 缓存机制

### P2 (中优先级)
6. 多后端支持 (Claude, Ollama)
7. 测试覆盖

### P3 (低优先级)
8. 流式响应
9. 对话历史
10. 性能优化

## 总结

**核心决策**:
- HTTP 客户端: libcurl
- JSON 处理: cJSON (嵌入)
- 异步处理: fork + pipe
- 缓存: LRU (内存)
- 多后端: 策略模式

**实施顺序**:
MVP 1 → MVP 2 → MVP 3 → MVP 4 → 增强功能

**关键风险**:
- libcurl 依赖管理
- 内存泄漏
- 异步处理稳定性

**下一步**:
开始 MVP 1 实现，修改 configure.ac 和 ai.mdd
