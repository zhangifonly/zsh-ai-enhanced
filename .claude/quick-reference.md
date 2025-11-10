# HTTP API 客户端实现 - 快速参考卡

## 一键开始

```bash
# 1. 准备环境
brew install curl  # macOS
# 或 sudo apt-get install libcurl4-openssl-dev  # Ubuntu

# 2. 下载 cJSON
cd Src/Modules
wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.c
wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.h
cd ../..

# 3. 配置和构建
./Util/preconfig
./configure --enable-curl
cd Src && make prep
make

# 4. 测试
zmodload zsh/ai
export IZSH_AI_ENABLED=1
export IZSH_AI_API_KEY="your-key"
ai "你好"
```

## 关键文件修改

### configure.ac (3 处修改)

**位置 1: 添加 --enable-curl 选项**
在 `dnl Do you want to look for pcre support?` 后添加:
```bash
dnl Do you want to look for libcurl support?
AC_ARG_ENABLE(curl,
AS_HELP_STRING([--enable-curl],[enable libcurl for AI module HTTP support]))
AC_ARG_VAR(CURL_CONFIG, [pathname of curl-config if it is not in PATH])
if test "x$enable_curl" = xyes; then
  AC_CHECK_PROG([CURL_CONFIG], curl-config, curl-config)
  if test "x$CURL_CONFIG" = x; then
    enable_curl=no
    AC_MSG_WARN([curl-config not found: AI module HTTP support disabled.])
  fi
fi
```

**位置 2: 添加头文件检测**
在 `if test "x$enable_pcre" = xyes; then` 附近添加:
```bash
if test "x$enable_curl" = xyes; then
  CPPFLAGS="`$CURL_CONFIG --cflags` $CPPFLAGS"
  AC_CHECK_HEADERS([curl/curl.h])
fi
```

**位置 3: 添加函数检测**
在 `if test x$enable_pcre = xyes; then` 附近添加:
```bash
if test x$enable_curl = xyes; then
  LIBS="`$CURL_CONFIG --libs` $LIBS"
  AC_CHECK_FUNCS(curl_easy_init curl_easy_setopt curl_easy_perform)
fi
```

### Src/Modules/ai.mdd

```bash
name=zsh/ai
link=`if test x$enable_curl = xyes; then echo dynamic; else echo no; fi`
load=no

autofeatures="b:ai b:ai_suggest b:ai_analyze"

objects="ai.o cJSON.o"
```

### Src/Modules/ai.c (核心实现)

**头文件添加**:
```c
#ifdef HAVE_CURL_CURL_H
#include <curl/curl.h>
#endif
#include "cJSON.h"
```

**关键数据结构**:
```c
struct ai_http_response {
    char *body;
    size_t body_len;
    long status_code;
};
```

**核心函数**:
- `ai_http_write_callback()` - libcurl 写回调
- `ai_http_post()` - HTTP POST 请求
- `ai_build_openai_request()` - 构建 JSON 请求
- `ai_parse_openai_response()` - 解析 JSON 响应
- `ai_async_call()` - 异步调用 (fork + pipe)
- `ai_cache_get()` / `ai_cache_put()` - 缓存操作

## MVP 阶段检查清单

### MVP 1: 基础 HTTP 调用
- [ ] configure.ac 添加 libcurl 检测
- [ ] ai.mdd 添加条件编译
- [ ] 下载 cJSON 源码
- [ ] 实现 `ai_http_write_callback()`
- [ ] 实现 `ai_http_post()`
- [ ] 实现基础错误处理
- [ ] 测试: `ai "test"` 输出原始 JSON
- [ ] valgrind 检测无内存泄漏

### MVP 2: JSON 处理
- [ ] 实现 `ai_build_openai_request()`
- [ ] 实现 `ai_parse_openai_response()`
- [ ] 集成到 `bin_ai()`
- [ ] 实现 JSON 错误处理
- [ ] 测试: `ai "你好"` 返回文本回复
- [ ] 美化输出格式

### MVP 3: 异步处理
- [ ] 实现 `ai_async_call()` (fork + pipe)
- [ ] 使用 poll() 非阻塞读取
- [ ] 添加进度提示
- [ ] 测试: API 调用时 shell 不阻塞
- [ ] 测试: 子进程错误不影响 shell

### MVP 4: 缓存机制
- [ ] 实现 `ai_hash_string()`
- [ ] 实现 `ai_cache_key()`
- [ ] 实现 LRU 缓存数据结构
- [ ] 实现 `ai_cache_get()`
- [ ] 实现 `ai_cache_put()`
- [ ] 集成到 `bin_ai()`
- [ ] 测试: 重复查询使用缓存
- [ ] 在 `finish_()` 中清理缓存

## 常用命令

### 编译和测试
```bash
# 重新配置
./configure --enable-curl

# 准备模块
cd Src && make prep

# 编译
make

# 清理
make clean

# 完全清理
make distclean

# 运行测试
make check

# 运行特定测试
make TESTNUM=V01 check
```

### 调试
```bash
# 内存泄漏检测
valgrind --leak-check=full zsh -c "zmodload zsh/ai; ai 'test'"

# 详细测试输出
ZTST_verbose=1 make check

# 测试失败后继续
ZTST_continue=1 make check
```

### 配置环境
```bash
export IZSH_AI_ENABLED=1
export IZSH_AI_API_KEY="sk-xxx"
export IZSH_AI_API_URL="https://api.openai.com/v1"
export IZSH_AI_MODEL="gpt-3.5-turbo"
export IZSH_AI_CACHE_ENABLED=1
export IZSH_AI_CACHE_SIZE=100
```

## 错误排查

### 问题: libcurl 未找到
```bash
# 检查 curl-config
which curl-config
curl-config --version

# 安装 libcurl
brew install curl  # macOS
sudo apt-get install libcurl4-openssl-dev  # Ubuntu

# 指定路径
CURL_CONFIG=/usr/local/bin/curl-config ./configure --enable-curl
```

### 问题: cJSON 未找到
```bash
# 检查文件
ls -la Src/Modules/cJSON.*

# 重新下载
cd Src/Modules
wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.c
wget https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.h
```

### 问题: 模块无法加载
```bash
# 检查编译是否成功
ls -la Src/Modules/ai.so

# 检查模块配置
cat config.modules | grep ai

# 检查依赖
ldd Src/Modules/ai.so  # Linux
otool -L Src/Modules/ai.so  # macOS

# 强制重新编译
cd Src && make prep
make clean
make
```

### 问题: API 调用失败
```bash
# 测试 API key
curl -H "Authorization: Bearer $IZSH_AI_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"test"}]}' \
     https://api.openai.com/v1/chat/completions

# 检查网络
ping api.openai.com

# 检查 SSL 证书
openssl s_client -connect api.openai.com:443
```

## 代码片段速查

### HTTP POST 请求框架
```c
CURL *curl = curl_easy_init();
curl_easy_setopt(curl, CURLOPT_URL, url);
curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_data);
curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, ai_http_write_callback);
curl_easy_setopt(curl, CURLOPT_WRITEDATA, &resp);
CURLcode res = curl_easy_perform(curl);
curl_easy_cleanup(curl);
```

### JSON 构建框架
```c
cJSON *root = cJSON_CreateObject();
cJSON_AddStringToObject(root, "key", "value");
cJSON *array = cJSON_CreateArray();
cJSON_AddItemToObject(root, "items", array);
char *json_str = cJSON_PrintUnformatted(root);
cJSON_Delete(root);
```

### JSON 解析框架
```c
cJSON *root = cJSON_Parse(json_str);
cJSON *item = cJSON_GetObjectItem(root, "key");
if (cJSON_IsString(item)) {
    char *value = ztrdup(item->valuestring);
}
cJSON_Delete(root);
```

### fork + pipe 框架
```c
int pipefd[2];
pipe(pipefd);
pid_t pid = fork();
if (pid == 0) {
    /* 子进程 */
    close(pipefd[0]);
    write(pipefd[1], data, len);
    close(pipefd[1]);
    _exit(0);
} else {
    /* 父进程 */
    close(pipefd[1]);
    read(pipefd[0], buffer, sizeof(buffer));
    close(pipefd[0]);
    waitpid(pid, NULL, 0);
}
```

## 时间估算

| 阶段 | 任务 | 时间 |
|------|------|------|
| 准备 | 环境配置、下载依赖 | 0.5天 |
| MVP 1 | 基础 HTTP 调用 | 1-2天 |
| MVP 2 | JSON 处理 | 1-2天 |
| MVP 3 | 异步处理 | 2-3天 |
| MVP 4 | 缓存机制 | 1-2天 |
| 测试 | 编写测试和文档 | 1天 |
| **总计** | | **6.5-10.5天** |

## 资源链接

- **libcurl 文档**: https://curl.se/libcurl/c/
- **cJSON 仓库**: https://github.com/DaveGamble/cJSON
- **OpenAI API 文档**: https://platform.openai.com/docs/api-reference
- **Zsh 模块开发**: `Doc/Zsh/mod_*.yo`
- **测试参考**: `Test/B01cd.ztst`

## 联系和帮助

如有问题，请查阅详细文档:
- `context-summary-http-api.md` - 上下文摘要
- `sequential-thinking-analysis.md` - 深度分析
- `implementation-plan.md` - 详细计划
- `http-api-implementation-summary.md` - 综合报告

---

**快速参考卡版本**: 1.0
**生成时间**: 2025-11-10
**适用阶段**: MVP 1-4
