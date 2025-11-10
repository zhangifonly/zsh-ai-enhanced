# HTTP API 客户端实现计划

## 项目概述

为 iZsh AI 模块添加 HTTP API 客户端功能，支持调用 OpenAI、Claude、Ollama 等兼容 API 的 AI 服务。

## 技术栈

- **HTTP 客户端**: libcurl
- **JSON 处理**: cJSON (嵌入式)
- **异步处理**: fork + pipe
- **缓存**: LRU (内存)

## 实施计划

### 阶段 1: 准备工作 (0.5天)

#### 任务 1.1: 环境准备
- [ ] 确认系统已安装 libcurl 开发库
  ```bash
  # macOS
  brew install curl

  # Ubuntu/Debian
  sudo apt-get install libcurl4-openssl-dev

  # 验证
  curl-config --version
  curl-config --libs
  ```

- [ ] 下载 cJSON 源码
  ```bash
  cd Src/Modules
  wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.c
  wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.h
  ```

#### 任务 1.2: 配置构建系统
- [ ] 修改 configure.ac 添加 libcurl 检测

  在 `dnl Do you want to look for pcre support?` 附近添加:
  ```bash
  dnl Do you want to look for libcurl support?
  AC_ARG_ENABLE(curl,
  AS_HELP_STRING([--enable-curl],[enable the search for the libcurl library (required for AI module HTTP support)]))

  AC_ARG_VAR(CURL_CONFIG, [pathname of curl-config if it is not in PATH])
  if test "x$enable_curl" = xyes; then
    AC_CHECK_PROG([CURL_CONFIG], curl-config, curl-config)
    if test "x$CURL_CONFIG" = x; then
      enable_curl=no
      AC_MSG_WARN([curl-config not found: AI module HTTP support disabled.])
      AC_MSG_NOTICE([Set CURL_CONFIG to pathname of curl-config if it is not in PATH.])
    fi
  fi
  ```

  在头文件检测部分添加:
  ```bash
  if test "x$enable_curl" = xyes; then
    CPPFLAGS="`$CURL_CONFIG --cflags` $CPPFLAGS"
    AC_CHECK_HEADERS([curl/curl.h])
  fi
  ```

  在函数检测部分添加:
  ```bash
  if test x$enable_curl = xyes; then
    LIBS="`$CURL_CONFIG --libs` $LIBS"
    AC_CHECK_FUNCS(curl_easy_init curl_easy_setopt curl_easy_perform)
  fi
  ```

- [ ] 修改 Src/Modules/ai.mdd

  ```bash
  name=zsh/ai
  link=`if test x$enable_curl = xyes; then echo dynamic; else echo no; fi`
  load=no

  autofeatures="b:ai b:ai_suggest b:ai_analyze"

  objects="ai.o cJSON.o"
  ```

- [ ] 重新配置和构建
  ```bash
  ./Util/preconfig
  ./configure --enable-curl
  cd Src && make prep
  make
  ```

### 阶段 2: MVP 1 - 基础 HTTP 调用 (1-2天)

#### 任务 2.1: 实现 HTTP 响应结构和回调

在 `Src/Modules/ai.c` 中添加:

```c
#ifdef HAVE_CURL_CURL_H
#include <curl/curl.h>
#endif

#include "cJSON.h"

/* HTTP 响应结构 */
struct ai_http_response {
    char *body;
    size_t body_len;
    long status_code;
};

/* libcurl 写回调函数 */
static size_t
ai_http_write_callback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    struct ai_http_response *resp = (struct ai_http_response *)userp;

    char *ptr = (char *)realloc(resp->body, resp->body_len + realsize + 1);
    if (!ptr) {
        fprintf(stderr, "ai: out of memory\n");
        return 0;
    }

    resp->body = ptr;
    memcpy(&(resp->body[resp->body_len]), contents, realsize);
    resp->body_len += realsize;
    resp->body[resp->body_len] = '\0';

    return realsize;
}
```

#### 任务 2.2: 实现 HTTP POST 函数

```c
/*
 * 执行 HTTP POST 请求
 * 返回: 0 成功, -1 失败
 */
static int
ai_http_post(const char *url, const char *api_key, const char *json_data,
             struct ai_http_response *resp)
{
#ifdef HAVE_CURL_CURL_H
    CURL *curl;
    CURLcode res;
    struct curl_slist *headers = NULL;

    /* 初始化响应结构 */
    resp->body = NULL;
    resp->body_len = 0;
    resp->status_code = 0;

    curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "ai: failed to initialize curl\n");
        return -1;
    }

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
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, ai_http_write_callback);
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

    if (res != CURLE_OK) {
        fprintf(stderr, "ai: HTTP request failed: %s\n", curl_easy_strerror(res));
        return -1;
    }

    return 0;
#else
    fprintf(stderr, "ai: libcurl support not compiled\n");
    return -1;
#endif
}
```

#### 任务 2.3: 实现基础错误处理

```c
/*
 * 检查 HTTP 响应状态码并报告错误
 * 返回: 0 成功, -1 失败
 */
static int
ai_check_http_status(long status_code, const char *nam)
{
    if (status_code >= 200 && status_code < 300) {
        return 0;
    }

    if (status_code == 401) {
        zwarnnam(nam, "API 密钥无效或已过期 (HTTP %ld)", status_code);
    } else if (status_code == 429) {
        zwarnnam(nam, "API 调用频率超限，请稍后再试 (HTTP %ld)", status_code);
    } else if (status_code >= 500) {
        zwarnnam(nam, "API 服务器错误 (HTTP %ld)", status_code);
    } else {
        zwarnnam(nam, "HTTP 错误 %ld", status_code);
    }

    return -1;
}
```

#### 任务 2.4: 更新 bin_ai 命令测试 HTTP 调用

```c
static int
bin_ai(char *nam, char **args, Options ops, UNUSED(int func))
{
    /* ... 现有检查 ... */

    char *question = zjoin(args, ' ', 1);

    /* 简单的 JSON 请求 (硬编码，MVP 2 会改进) */
    char json_req[2048];
    snprintf(json_req, sizeof(json_req),
        "{\"model\":\"%s\",\"messages\":[{\"role\":\"user\",\"content\":\"%s\"}]}",
        ai_model, question);

    /* 构建完整 URL */
    char full_url[1024];
    snprintf(full_url, sizeof(full_url), "%s/v1/chat/completions", ai_api_url);

    /* 执行 HTTP 请求 */
    struct ai_http_response resp;
    printf("🤖 正在调用 AI API...\n");

    if (ai_http_post(full_url, ai_api_key, json_req, &resp) != 0) {
        free(question);
        return 1;
    }

    /* 检查状态码 */
    if (ai_check_http_status(resp.status_code, nam) != 0) {
        if (resp.body) free(resp.body);
        free(question);
        return 1;
    }

    /* 输出原始响应 (MVP 1 阶段) */
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("响应 (HTTP %ld):\n", resp.status_code);
    if (resp.body) {
        printf("%s\n", resp.body);
        free(resp.body);
    }
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    free(question);
    return 0;
}
```

#### 任务 2.5: 测试

- [ ] 编译和加载模块
  ```bash
  make
  zmodload zsh/ai
  ```

- [ ] 配置 API
  ```bash
  export IZSH_AI_ENABLED=1
  export IZSH_AI_API_KEY="your-api-key"
  export IZSH_AI_API_URL="https://api.openai.com/v1"
  export IZSH_AI_MODEL="gpt-3.5-turbo"
  ```

- [ ] 测试基础调用
  ```bash
  ai "你好"
  ai "什么是 Zsh?"
  ```

- [ ] 测试错误处理
  ```bash
  # 测试无效 API key
  export IZSH_AI_API_KEY="invalid"
  ai "test"

  # 测试网络错误
  export IZSH_AI_API_URL="https://nonexistent.example.com"
  ai "test"
  ```

- [ ] 内存泄漏检测
  ```bash
  valgrind --leak-check=full zsh -c "zmodload zsh/ai; ai 'test'"
  ```

### 阶段 3: MVP 2 - JSON 处理 (1-2天)

#### 任务 3.1: 实现 JSON 请求构建

```c
/*
 * 构建 OpenAI 格式的 JSON 请求
 * 返回: JSON 字符串 (需要调用者释放)
 */
static char *
ai_build_openai_request(const char *model, const char *prompt)
{
    cJSON *root = cJSON_CreateObject();
    if (!root) return NULL;

    cJSON *messages = cJSON_CreateArray();
    cJSON *message = cJSON_CreateObject();

    cJSON_AddStringToObject(message, "role", "user");
    cJSON_AddStringToObject(message, "content", prompt);
    cJSON_AddItemToArray(messages, message);

    cJSON_AddStringToObject(root, "model", model);
    cJSON_AddItemToObject(root, "messages", messages);
    cJSON_AddNumberToObject(root, "temperature", 0.7);

    char *json_str = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);

    return json_str;
}
```

#### 任务 3.2: 实现 JSON 响应解析

```c
/*
 * 解析 OpenAI 格式的 JSON 响应
 * 返回: AI 回复文本 (使用 ztrdup, 需要调用者使用 zsfree 释放)
 */
static char *
ai_parse_openai_response(const char *json_str, const char *nam)
{
    cJSON *root = cJSON_Parse(json_str);
    if (!root) {
        const char *error_ptr = cJSON_GetErrorPtr();
        if (error_ptr) {
            zwarnnam(nam, "JSON 解析失败: %s", error_ptr);
        } else {
            zwarnnam(nam, "JSON 解析失败");
        }
        return NULL;
    }

    /* 检查是否有错误 */
    cJSON *error = cJSON_GetObjectItem(root, "error");
    if (error) {
        cJSON *message = cJSON_GetObjectItem(error, "message");
        if (cJSON_IsString(message)) {
            zwarnnam(nam, "API 错误: %s", message->valuestring);
        }
        cJSON_Delete(root);
        return NULL;
    }

    /* 提取回复内容 */
    cJSON *choices = cJSON_GetObjectItem(root, "choices");
    if (!cJSON_IsArray(choices) || cJSON_GetArraySize(choices) == 0) {
        zwarnnam(nam, "API 响应格式错误: 缺少 choices");
        cJSON_Delete(root);
        return NULL;
    }

    cJSON *choice = cJSON_GetArrayItem(choices, 0);
    cJSON *message = cJSON_GetObjectItem(choice, "message");
    cJSON *content = cJSON_GetObjectItem(message, "content");

    char *result = NULL;
    if (cJSON_IsString(content) && content->valuestring) {
        result = ztrdup(content->valuestring);
    } else {
        zwarnnam(nam, "API 响应格式错误: 缺少 content");
    }

    cJSON_Delete(root);
    return result;
}
```

#### 任务 3.3: 更新 bin_ai 命令使用 JSON 处理

```c
static int
bin_ai(char *nam, char **args, Options ops, UNUSED(int func))
{
    /* ... 现有检查 ... */

    char *question = zjoin(args, ' ', 1);

    /* 构建 JSON 请求 */
    char *json_req = ai_build_openai_request(ai_model, question);
    if (!json_req) {
        zwarnnam(nam, "构建 JSON 请求失败");
        free(question);
        return 1;
    }

    /* 构建完整 URL */
    char full_url[1024];
    snprintf(full_url, sizeof(full_url), "%s/v1/chat/completions", ai_api_url);

    /* 执行 HTTP 请求 */
    struct ai_http_response resp;
    printf("🤖 正在思考...\n");

    if (ai_http_post(full_url, ai_api_key, json_req, &resp) != 0) {
        free(json_req);
        free(question);
        return 1;
    }

    free(json_req);

    /* 检查状态码 */
    if (ai_check_http_status(resp.status_code, nam) != 0) {
        if (resp.body) free(resp.body);
        free(question);
        return 1;
    }

    /* 解析 JSON 响应 */
    char *answer = ai_parse_openai_response(resp.body, nam);
    free(resp.body);

    if (!answer) {
        free(question);
        return 1;
    }

    /* 美化输出 */
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("问题: %s\n", question);
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("%s\n", answer);
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    zsfree(answer);
    free(question);
    return 0;
}
```

#### 任务 3.4: 测试

- [ ] 测试完整问答流程
  ```bash
  ai "什么是 Zsh?"
  ai "如何在 Zsh 中定义函数?"
  ai "解释一下 Zsh 的补全系统"
  ```

- [ ] 测试 JSON 错误处理
  ```bash
  # 模拟 API 返回错误 (需要手动修改代码或使用 mock server)
  ```

### 阶段 4: MVP 3 - 异步处理 (2-3天)

#### 任务 4.1: 实现 fork + pipe 异步调用

```c
/*
 * 异步执行 AI API 调用
 * 返回: 0 成功, 1 失败
 */
static int
ai_async_call(const char *nam, const char *question)
{
    int pipefd[2];
    pid_t pid;

    /* 创建管道 */
    if (pipe(pipefd) == -1) {
        zwarnnam(nam, "创建管道失败: %s", strerror(errno));
        return 1;
    }

    /* fork 子进程 */
    pid = fork();
    if (pid == -1) {
        zwarnnam(nam, "fork 失败: %s", strerror(errno));
        close(pipefd[0]);
        close(pipefd[1]);
        return 1;
    }

    if (pid == 0) {
        /* 子进程: 执行 API 调用 */
        close(pipefd[0]);  /* 关闭读端 */

        /* 构建 JSON 请求 */
        char *json_req = ai_build_openai_request(ai_model, question);
        if (!json_req) {
            close(pipefd[1]);
            _exit(1);
        }

        /* 构建完整 URL */
        char full_url[1024];
        snprintf(full_url, sizeof(full_url), "%s/v1/chat/completions", ai_api_url);

        /* 执行 HTTP 请求 */
        struct ai_http_response resp;
        if (ai_http_post(full_url, ai_api_key, json_req, &resp) != 0) {
            free(json_req);
            close(pipefd[1]);
            _exit(1);
        }

        free(json_req);

        /* 检查状态码 */
        if (resp.status_code < 200 || resp.status_code >= 300) {
            if (resp.body) free(resp.body);
            close(pipefd[1]);
            _exit(1);
        }

        /* 解析响应 */
        char *answer = ai_parse_openai_response(resp.body, nam);
        free(resp.body);

        if (answer) {
            /* 写入管道 */
            write(pipefd[1], answer, strlen(answer));
            zsfree(answer);
        }

        close(pipefd[1]);
        _exit(0);

    } else {
        /* 父进程: 读取结果 */
        close(pipefd[1]);  /* 关闭写端 */

        printf("🤖 正在思考 (进程 %d)...\n", pid);

        /* 使用 poll 非阻塞读取 */
#ifdef HAVE_POLL
        struct pollfd fds[1];
        fds[0].fd = pipefd[0];
        fds[0].events = POLLIN;

        char buffer[4096];
        ssize_t nread;
        int total_read = 0;

        while (1) {
            int ret = poll(fds, 1, 100);  /* 100ms 超时 */
            if (ret < 0) {
                if (errno == EINTR) continue;
                zwarnnam(nam, "poll 失败: %s", strerror(errno));
                break;
            }

            if (ret == 0) {
                /* 超时，打印进度提示 */
                if (total_read == 0) {
                    printf(".");
                    fflush(stdout);
                }
                continue;
            }

            if (fds[0].revents & POLLIN) {
                nread = read(pipefd[0], buffer, sizeof(buffer) - 1);
                if (nread > 0) {
                    buffer[nread] = '\0';
                    if (total_read == 0) {
                        printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
                        printf("问题: %s\n", question);
                        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
                    }
                    printf("%s", buffer);
                    total_read += nread;
                } else if (nread == 0) {
                    /* EOF */
                    break;
                } else {
                    if (errno != EINTR) {
                        zwarnnam(nam, "读取失败: %s", strerror(errno));
                        break;
                    }
                }
            }

            if (fds[0].revents & (POLLERR | POLLHUP)) {
                break;
            }
        }

        if (total_read > 0) {
            printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        }
#else
        /* 降级到阻塞读取 */
        char buffer[4096];
        ssize_t nread;

        printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        printf("问题: %s\n", question);
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

        while ((nread = read(pipefd[0], buffer, sizeof(buffer) - 1)) > 0) {
            buffer[nread] = '\0';
            printf("%s", buffer);
        }

        printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
#endif

        close(pipefd[0]);

        /* 等待子进程 */
        int status;
        waitpid(pid, &status, 0);

        if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
            zwarnnam(nam, "API 调用失败");
            return 1;
        }
    }

    return 0;
}
```

#### 任务 4.2: 更新 bin_ai 使用异步调用

```c
static int
bin_ai(char *nam, char **args, Options ops, UNUSED(int func))
{
    /* ... 现有检查 ... */

    char *question = zjoin(args, ' ', 1);

    int ret = ai_async_call(nam, question);

    free(question);
    return ret;
}
```

#### 任务 4.3: 测试

- [ ] 测试异步调用
  ```bash
  ai "解释一下 Zsh 的历史机制" &
  # shell 应该可以继续使用
  ls
  pwd
  # 等待结果返回
  ```

- [ ] 测试错误处理
  ```bash
  # 子进程崩溃不应影响父进程
  ```

### 阶段 5: MVP 4 - 缓存机制 (1-2天)

#### 任务 5.1: 实现缓存数据结构

```c
/* 缓存条目 */
struct ai_cache_entry {
    unsigned long key;
    char *prompt;
    char *response;
    time_t timestamp;
    struct ai_cache_entry *prev;
    struct ai_cache_entry *next;
};

/* LRU 缓存 */
static struct {
    struct ai_cache_entry *head;
    struct ai_cache_entry *tail;
    int size;
    int max_size;
    int hits;
    int misses;
} ai_cache = {NULL, NULL, 0, 100, 0, 0};
```

#### 任务 5.2: 实现缓存操作

```c
/* 哈希函数 */
static unsigned long
ai_hash_string(const char *str)
{
    unsigned long hash = 5381;
    int c;

    while ((c = *str++))
        hash = ((hash << 5) + hash) + c;

    return hash;
}

/* 生成缓存键 */
static unsigned long
ai_cache_key(const char *prompt, const char *model)
{
    char combined[2048];
    snprintf(combined, sizeof(combined), "%s|%s", prompt, model);
    return ai_hash_string(combined);
}

/* 查找缓存 */
static char *
ai_cache_get(unsigned long key)
{
    if (!ai_cache_enabled) return NULL;

    struct ai_cache_entry *entry = ai_cache.head;

    while (entry) {
        if (entry->key == key) {
            ai_cache.hits++;

            /* 移到链表头部 */
            if (entry != ai_cache.head) {
                entry->prev->next = entry->next;
                if (entry->next)
                    entry->next->prev = entry->prev;
                else
                    ai_cache.tail = entry->prev;

                entry->prev = NULL;
                entry->next = ai_cache.head;
                ai_cache.head->prev = entry;
                ai_cache.head = entry;
            }

            return entry->response;
        }
        entry = entry->next;
    }

    ai_cache.misses++;
    return NULL;
}

/* 添加缓存 */
static void
ai_cache_put(unsigned long key, const char *prompt, const char *response)
{
    if (!ai_cache_enabled) return;

    /* 如果已满，移除尾部 */
    if (ai_cache.size >= ai_cache.max_size) {
        struct ai_cache_entry *old = ai_cache.tail;
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

    /* 创建新条目 */
    struct ai_cache_entry *entry = (struct ai_cache_entry *)zalloc(sizeof(*entry));
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

/* 清理缓存 */
static void
ai_cache_clear(void)
{
    struct ai_cache_entry *entry = ai_cache.head;

    while (entry) {
        struct ai_cache_entry *next = entry->next;
        zsfree(entry->prompt);
        zsfree(entry->response);
        zfree(entry, sizeof(*entry));
        entry = next;
    }

    ai_cache.head = NULL;
    ai_cache.tail = NULL;
    ai_cache.size = 0;
    ai_cache.hits = 0;
    ai_cache.misses = 0;
}
```

#### 任务 5.3: 集成缓存到 bin_ai

```c
static int
bin_ai(char *nam, char **args, Options ops, UNUSED(int func))
{
    /* ... 现有检查 ... */

    char *question = zjoin(args, ' ', 1);

    /* 检查缓存 */
    unsigned long cache_key = ai_cache_key(question, ai_model);
    char *cached = ai_cache_get(cache_key);

    if (cached) {
        printf("💾 从缓存获取 (命中率: %d/%d = %.1f%%)\n",
               ai_cache.hits, ai_cache.hits + ai_cache.misses,
               100.0 * ai_cache.hits / (ai_cache.hits + ai_cache.misses));
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        printf("问题: %s\n", question);
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        printf("%s\n", cached);
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

        free(question);
        return 0;
    }

    /* 缓存未命中，调用 API */
    /* ... 现有 API 调用代码 ... */

    /* 调用成功后添加到缓存 */
    if (answer) {
        ai_cache_put(cache_key, question, answer);
    }

    /* ... 其余代码 ... */
}
```

#### 任务 5.4: 在 finish_ 中清理缓存

```c
int
finish_(UNUSED(Module m))
{
    /* 清理缓存 */
    ai_cache_clear();

    /* ... 现有清理代码 ... */

    return 0;
}
```

#### 任务 5.5: 测试

- [ ] 测试缓存命中
  ```bash
  ai "什么是 Zsh?"     # 缓存未命中
  ai "什么是 Zsh?"     # 缓存命中
  ```

- [ ] 测试缓存大小限制
  ```bash
  # 调用超过 100 次不同问题，验证 LRU 淘汰
  ```

- [ ] 测试缓存统计
  ```bash
  # 多次调用后查看命中率
  ```

### 阶段 6: 测试和文档 (1天)

#### 任务 6.1: 编写测试

创建 `Test/V01ai.ztst`:
```zsh
%prep
  if ! zmodload zsh/ai 2>/dev/null; then
    ZTST_unimplemented="the zsh/ai module is not available"
  fi

%test
  # 测试模块加载
  zmodload zsh/ai
  0:模块加载

  # 测试配置
  export IZSH_AI_ENABLED=1
  export IZSH_AI_API_KEY="test-key"
  export IZSH_AI_API_URL="https://api.openai.com/v1"
  export IZSH_AI_MODEL="gpt-3.5-turbo"
  0:配置设置

  # 测试基础命令
  ai 2>&1 | grep "用法"
  0:ai 命令帮助

  # 更多测试...
```

#### 任务 6.2: 编写文档

创建 `Doc/Zsh/mod_ai.yo`:
```yodl
texinode(The zsh/ai Module)(...)(...)(...)
sect(The zsh/ai Module)

The tt(zsh/ai) module provides AI-powered command assistance.

subsect(Builtins)

startitem()
findex(ai)
item(tt(ai) var(question))(
Ask the AI assistant a question.
)
enditem()

subsect(Configuration)

The module uses the following environment variables:

startitem()
vindex(IZSH_AI_ENABLED)
item(tt(IZSH_AI_ENABLED))(
Enable or disable AI features (0 or 1).
)
...
```

## 验收标准

### MVP 1
- [x] 能够调用 OpenAI API 并获取原始 JSON 响应
- [x] 网络错误和 HTTP 错误能够正确报告
- [x] 无内存泄漏

### MVP 2
- [x] 能够解析 JSON 响应并提取 AI 回复
- [x] JSON 错误能够正确处理
- [x] 输出格式美观

### MVP 3
- [x] API 调用不阻塞 shell
- [x] 异步结果能够正确显示
- [x] 子进程错误不影响 shell 稳定性

### MVP 4
- [x] 相同问题第二次查询使用缓存
- [x] 缓存大小限制生效
- [x] 缓存命中率统计正确

## 时间估算

| 阶段 | 任务 | 预计时间 |
|------|------|----------|
| 1 | 准备工作 | 0.5天 |
| 2 | MVP 1: 基础 HTTP 调用 | 1-2天 |
| 3 | MVP 2: JSON 处理 | 1-2天 |
| 4 | MVP 3: 异步处理 | 2-3天 |
| 5 | MVP 4: 缓存机制 | 1-2天 |
| 6 | 测试和文档 | 1天 |
| **总计** | | **6.5-10.5天** |

## 风险管理

### 风险 1: libcurl 在某些系统上不可用
- **缓解**: configure 时检测，不可用时禁用模块
- **备用方案**: 提供基于 curl 命令的简化实现

### 风险 2: 内存泄漏
- **缓解**: 严格使用 Zsh 内存 API，定期 valgrind 检测
- **监控**: 每个阶段结束运行内存检测

### 风险 3: 异步处理不稳定
- **缓解**: 充分测试各种异常情况，使用进程隔离
- **监控**: 压力测试，大量并发调用

## 下一步

开始阶段 1: 准备工作
