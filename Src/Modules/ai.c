/*
 * ai.c - AI integration module for iZsh
 *
 * This file is part of iZsh, the intelligent Z shell.
 *
 * Copyright (c) 2025 iZsh Project
 * All rights reserved.
 *
 * This module provides AI-powered command correction, suggestion,
 * and analysis capabilities for iZsh.
 */

#include "ai.mdh"
#include "ai.pro"

/* 引入 cJSON 和 curl 库 */
#include "cJSON.h"

#ifdef HAVE_CURL_CURL_H
#include <curl/curl.h>
#define CURL_AVAILABLE 1
#else
#define CURL_AVAILABLE 0
#endif

/* ============================================
 * HTTP 响应数据结构
 * ============================================ */

struct http_response {
    char *data;
    size_t size;
};

/* ============================================
 * 配置管理
 * ============================================ */

/* AI 功能开关 */
static int ai_enabled = 0;

/* AI 调试模式（通过环境变量 IZSH_AI_DEBUG=1 启用） */
static int ai_debug_enabled = 0;

/* 调试输出宏 */
#define AI_DEBUG(...) do { if (ai_debug_enabled) fprintf(stderr, __VA_ARGS__); } while(0)

/* AI 干预级别: 0=off, 1=suggest, 2=auto */
static int ai_intervention_level = 1;

/* API 配置 */
static char *ai_api_key = NULL;
static char *ai_api_url = NULL;
static char *ai_model = NULL;
static char *ai_api_type = NULL;  /* API 类型: "openai" 或 "anthropic" */

/* 缓存配置 */
static int ai_cache_enabled = 1;
static int ai_cache_size = 100;

/* ============================================
 * 配置读取函数
 * ============================================ */

/*
 * 从环境变量读取 AI 配置
 */
static void
ai_load_config(void)
{
    char *env_val;

    /* 读取 AI 功能开关 */
    if ((env_val = getsparam("IZSH_AI_ENABLED"))) {
        ai_enabled = atoi(env_val);
    }

    /* 读取调试模式开关 */
    if ((env_val = getsparam("IZSH_AI_DEBUG"))) {
        ai_debug_enabled = atoi(env_val);
    }

    /* 读取干预级别 */
    if ((env_val = getsparam("IZSH_AI_INTERVENTION_LEVEL"))) {
        if (!strcmp(env_val, "off"))
            ai_intervention_level = 0;
        else if (!strcmp(env_val, "suggest"))
            ai_intervention_level = 1;
        else if (!strcmp(env_val, "auto"))
            ai_intervention_level = 2;
    }

    /* 读取 API 配置 */
    if ((env_val = getsparam("IZSH_AI_API_KEY"))) {
        ai_api_key = ztrdup(env_val);
    }

    if ((env_val = getsparam("IZSH_AI_API_URL"))) {
        ai_api_url = ztrdup(env_val);
    } else {
        ai_api_url = ztrdup("https://api.openai.com/v1");
    }

    if ((env_val = getsparam("IZSH_AI_MODEL"))) {
        ai_model = ztrdup(env_val);
    } else {
        ai_model = ztrdup("gpt-3.5-turbo");
    }

    /* 读取 API 类型 */
    if ((env_val = getsparam("IZSH_AI_API_TYPE"))) {
        ai_api_type = ztrdup(env_val);
    } else {
        ai_api_type = ztrdup("anthropic");  /* 默认 Anthropic */
    }

    /* 读取缓存配置 */
    if ((env_val = getsparam("IZSH_AI_CACHE_ENABLED"))) {
        ai_cache_enabled = atoi(env_val);
    }

    if ((env_val = getsparam("IZSH_AI_CACHE_SIZE"))) {
        ai_cache_size = atoi(env_val);
    }
}

/* ============================================
 * HTTP 和 JSON 核心函数
 * ============================================ */

#if CURL_AVAILABLE

/*
 * HTTP 响应写入回调函数
 * libcurl 会调用此函数来写入接收到的数据
 */
static size_t
http_write_callback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    struct http_response *resp = (struct http_response *)userp;

    char *ptr = realloc(resp->data, resp->size + realsize + 1);
    if (!ptr) {
        return 0;  /* 内存分配失败 */
    }

    resp->data = ptr;
    memcpy(&(resp->data[resp->size]), contents, realsize);
    resp->size += realsize;
    resp->data[resp->size] = 0;

    return realsize;
}

/*
 * 构建 OpenAI 格式的 JSON 请求
 *
 * @param prompt 用户输入的问题
 * @param model  模型名称
 * @return JSON 字符串（调用者需要 free）
 */
static char *
ai_build_request_json(const char *prompt, const char *model)
{
    cJSON *root = cJSON_CreateObject();
    if (!root) return NULL;

    cJSON_AddStringToObject(root, "model", model);

    cJSON *messages = cJSON_CreateArray();
    cJSON *message = cJSON_CreateObject();
    cJSON_AddStringToObject(message, "role", "user");
    cJSON_AddStringToObject(message, "content", prompt);
    cJSON_AddItemToArray(messages, message);

    cJSON_AddItemToObject(root, "messages", messages);

    /* Anthropic API 要求 max_tokens 参数 - 命令翻译只需要很少token */
    cJSON_AddNumberToObject(root, "max_tokens", 50);

    char *json_str = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);

    return json_str;
}

/*
 * 解析 AI API 的 JSON 响应（支持多种格式）
 *
 * @param json_str JSON 响应字符串
 * @return AI 回复内容（调用者需要 zsfree）
 */
static char *
ai_parse_response_json(const char *json_str)
{
    char *result = NULL;
    cJSON *root = cJSON_Parse(json_str);

    if (!root) {
        AI_DEBUG("[AI Debug] JSON 解析失败\n");
        return NULL;
    }

    /* 调试：打印原始 JSON */
    char *debug_json = cJSON_PrintUnformatted(root);
    if (debug_json) {
        AI_DEBUG("[AI Debug] 响应 JSON: %s\n", debug_json);
        free(debug_json);
    }

    /* 格式1: 标准 OpenAI 格式 - {"choices":[{"message":{"content":"..."}}]} */
    cJSON *choices = cJSON_GetObjectItem(root, "choices");
    if (choices && cJSON_IsArray(choices) && cJSON_GetArraySize(choices) > 0) {
        cJSON *first_choice = cJSON_GetArrayItem(choices, 0);
        cJSON *message = cJSON_GetObjectItem(first_choice, "message");
        if (message) {
            cJSON *content = cJSON_GetObjectItem(message, "content");
            if (content && cJSON_IsString(content)) {
                result = ztrdup(content->valuestring);
                AI_DEBUG("[AI Debug] 使用标准 OpenAI 格式解析成功\n");
            }
        }
    }

    /* 格式2: 简化成功格式 - {"success":true, "data":"...", "content":"..."} */
    if (!result) {
        cJSON *success = cJSON_GetObjectItem(root, "success");
        if (success && cJSON_IsTrue(success)) {
            /* 尝试 data 字段 */
            cJSON *data = cJSON_GetObjectItem(root, "data");
            if (data && cJSON_IsString(data)) {
                result = ztrdup(data->valuestring);
                AI_DEBUG("[AI Debug] 使用简化格式（data字段）解析\n");
            }
            /* 尝试 content 字段 */
            if (!result) {
                cJSON *content = cJSON_GetObjectItem(root, "content");
                if (content && cJSON_IsString(content)) {
                    result = ztrdup(content->valuestring);
                    AI_DEBUG("[AI Debug] 使用简化格式（content字段）解析\n");
                }
            }
            /* 如果只有 success:true，没有实际内容 */
            if (!result) {
                AI_DEBUG("[AI Debug] 警告: API 返回 success=true 但没有实际内容\n");
                result = ztrdup("API 返回成功，但响应中没有 AI 回答内容。\n"
                               "可能的原因：\n"
                               "1. API 实现不完整\n"
                               "2. 需要异步方式获取结果\n"
                               "3. 需要额外的参数或配置\n\n"
                               "建议：请检查 API 文档或联系 API 提供商。");
            }
        }
    }

    /* 格式3: Anthropic 格式 - {"content":[{"text":"..."}]} */
    if (!result) {
        cJSON *content_array = cJSON_GetObjectItem(root, "content");
        if (content_array && cJSON_IsArray(content_array) && cJSON_GetArraySize(content_array) > 0) {
            cJSON *first_content = cJSON_GetArrayItem(content_array, 0);
            if (first_content) {
                cJSON *text = cJSON_GetObjectItem(first_content, "text");
                if (text && cJSON_IsString(text)) {
                    result = ztrdup(text->valuestring);
                    AI_DEBUG("[AI Debug] 使用 Anthropic 格式解析成功\n");
                }
            }
        }
    }

    /* 格式4: 错误响应 - 支持两种格式 */
    if (!result) {
        cJSON *error = cJSON_GetObjectItem(root, "error");
        if (error) {
            char error_buf[512];

            /* 格式4a: OpenAI 格式 - {"error":{"message":"..."}} */
            if (cJSON_IsObject(error)) {
                cJSON *error_msg = cJSON_GetObjectItem(error, "message");
                if (error_msg && cJSON_IsString(error_msg)) {
                    snprintf(error_buf, sizeof(error_buf), "API 错误: %s", error_msg->valuestring);
                    result = ztrdup(error_buf);
                    AI_DEBUG("[AI Debug] API 返回 OpenAI 格式错误\n");
                }
            }
            /* 格式4b: NewAPI 格式 - {"error":"直接字符串"} */
            else if (cJSON_IsString(error)) {
                snprintf(error_buf, sizeof(error_buf), "API 错误: %s", error->valuestring);
                result = ztrdup(error_buf);
                AI_DEBUG("[AI Debug] API 返回 NewAPI 格式错误\n");
            }
        }
    }

    if (!result) {
        AI_DEBUG("[AI Debug] 无法识别的响应格式\n");
    }

    cJSON_Delete(root);
    return result;
}

/*
 * 执行 HTTP POST 请求调用 AI API
 *
 * @param prompt 用户输入的问题
 * @return AI 回复内容（调用者需要 zsfree），失败返回 NULL
 */
static char *
ai_http_post(const char *prompt)
{
    CURL *curl;
    CURLcode res;
    struct http_response resp = {NULL, 0};
    char *result = NULL;

    /* 构建请求 JSON */
    char *request_json = ai_build_request_json(prompt, ai_model);
    if (!request_json) {
        return NULL;
    }

    curl = curl_easy_init();
    if (!curl) {
        free(request_json);
        return NULL;
    }

    /* 构建完整的 API URL - 根据 API 类型选择端点 */
    char api_url[512];
    if (ai_api_type && !strcmp(ai_api_type, "anthropic")) {
        snprintf(api_url, sizeof(api_url), "%s/messages", ai_api_url);
    } else {
        snprintf(api_url, sizeof(api_url), "%s/chat/completions", ai_api_url);
    }

    /* 调试：显示请求信息 */
    AI_DEBUG("[AI Debug] ========== API 请求 ==========\n");
    AI_DEBUG("[AI Debug] URL: %s\n", api_url);
    AI_DEBUG("[AI Debug] Model: %s\n", ai_model);
    AI_DEBUG("[AI Debug] 请求 JSON: %s\n", request_json);
    AI_DEBUG("[AI Debug] ================================\n");

    /* 构建 HTTP headers */
    struct curl_slist *headers = NULL;
    char auth_header[512];
    snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", ai_api_key);

    headers = curl_slist_append(headers, "Content-Type: application/json");
    headers = curl_slist_append(headers, auth_header);

    /* Anthropic API 需要额外的版本头 */
    if (ai_api_type && !strcmp(ai_api_type, "anthropic")) {
        headers = curl_slist_append(headers, "anthropic-version: 2023-06-01");
    }

    /* 设置 curl 选项 */
    curl_easy_setopt(curl, CURLOPT_URL, api_url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request_json);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, http_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&resp);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);

    /* 执行请求 */
    AI_DEBUG("[AI Debug] 正在发送请求...\n");
    res = curl_easy_perform(curl);

    /* 获取 HTTP 状态码 */
    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    AI_DEBUG("[AI Debug] HTTP 状态码: %ld\n", http_code);

    if (res != CURLE_OK) {
        /* HTTP 请求失败 */
        AI_DEBUG("[AI Debug] curl 错误: %s\n", curl_easy_strerror(res));
    } else {
        /* 显示响应信息 */
        AI_DEBUG("[AI Debug] ========== API 响应 ==========\n");
        AI_DEBUG("[AI Debug] 响应长度: %zu bytes\n", resp.size);
        if (resp.data && resp.size > 0) {
            /* 解析响应 JSON */
            result = ai_parse_response_json(resp.data);
        } else {
            AI_DEBUG("[AI Debug] 响应为空\n");
        }
        AI_DEBUG("[AI Debug] ================================\n");
    }

    /* 清理 */
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(request_json);
    if (resp.data) free(resp.data);

    return result;
}

#endif  /* CURL_AVAILABLE */

/* ============================================
 * AI 命令 - ai
 * ============================================ */

/*
 * ai 命令的实现
 * 用法: ai <question>
 * 示例: ai "如何查找大文件？"
 */
static int
bin_ai(char *nam, char **args, Options ops, UNUSED(int func))
{
    /* 检查 AI 功能是否启用 */
    if (!ai_enabled) {
        zwarnnam(nam, "AI 功能未启用。请在 ~/.izshrc 中设置 IZSH_AI_ENABLED=1");
        return 1;
    }

    /* 检查是否提供了问题 */
    if (!args[0]) {
        zwarnnam(nam, "用法: %s <问题>", nam);
        return 1;
    }

    /* 检查 API 密钥 */
    if (!ai_api_key || !*ai_api_key) {
        zwarnnam(nam, "未配置 AI API 密钥。请设置 IZSH_AI_API_KEY 环境变量");
        return 1;
    }

    /* 拼接所有参数 */
    char *question = zjoin(args, ' ', 1);

#if CURL_AVAILABLE
    /* 调用 AI API */
    printf("🤖 AI 助手正在思考...\n");

    char *answer = ai_http_post(question);

    if (answer) {
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        printf("%s\n", answer);
        printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        zsfree(answer);
        free(question);
        return 0;
    } else {
        zwarnnam(nam, "API 调用失败，请检查网络连接和配置");
        free(question);
        return 1;
    }
#else
    /* 如果没有编译 curl 支持，输出提示信息 */
    printf("🤖 AI 助手 (HTTP 功能未启用)\n");
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("问题: %s\n", question);
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("提示: 请使用 --enable-curl 选项重新编译以启用 HTTP API 调用功能\n");
    printf("配置信息:\n");
    printf("  API URL: %s\n", ai_api_url ? ai_api_url : "(未设置)");
    printf("  模型: %s\n", ai_model ? ai_model : "(未设置)");
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    free(question);
    return 1;
#endif
}

/* ============================================
 * AI 建议命令 - ai_suggest
 * ============================================ */

/*
 * ai_suggest 命令的实现
 * 用法: ai_suggest <自然语言描述>
 * 示例: ai_suggest "列目录"
 */
static int
bin_ai_suggest(char *nam, char **args, Options ops, UNUSED(int func))
{
    if (!ai_enabled) {
        zwarnnam(nam, "AI 功能未启用");
        return 1;
    }

    if (!args[0]) {
        zwarnnam(nam, "用法: %s <命令描述>", nam);
        return 1;
    }

    /* 检查 API 配置 */
    if (!ai_api_key || !*ai_api_key) {
        zwarnnam(nam, "未配置 AI API 密钥");
        return 1;
    }

    /* 解码 zsh 的 Meta 字符编码以支持 UTF-8 */
    for (char **p = args; *p; p++) {
        int len;
        *p = unmetafy(*p, &len);
    }

    /* 手动拼接参数，避免 zjoin 的编码问题 */
    size_t total_len = 0;
    for (char **p = args; *p; p++) {
        total_len += strlen(*p) + 1; /* +1 for space or null */
    }

    char *user_input = (char *)zalloc(total_len);
    if (!user_input) {
        zwarnnam(nam, "内存分配失败");
        return 1;
    }

    user_input[0] = '\0';
    for (char **p = args; *p; p++) {
        if (p != args) {
            strcat(user_input, " ");
        }
        strcat(user_input, *p);
    }


#if CURL_AVAILABLE
    /* 构建精简的 prompt 用于命令翻译 - 使用更严格的格式要求 */
    char prompt[1024];
    snprintf(prompt, sizeof(prompt),
        "翻译为Shell命令: \"%s\"\n"
        "规则: 只输出命令,无解释,无markdown\n"
        "例: 列目录→ls, 查看file.txt→cat file.txt",
        user_input);

    AI_DEBUG("[AI Suggest] 正在翻译命令...\n");

    char *suggested_cmd = ai_http_post(prompt);

    if (suggested_cmd) {
        /* 清理 AI 返回的命令 */
        char *clean_cmd = suggested_cmd;

        /* 去除前导空白 */
        while (*clean_cmd && (*clean_cmd == ' ' || *clean_cmd == '\t' || *clean_cmd == '\n')) {
            clean_cmd++;
        }

        /* 只取第一行作为命令（去除换行后的内容） */
        char *first_newline = strchr(clean_cmd, '\n');
        if (first_newline) {
            *first_newline = '\0';
        }

        /* 去除尾部空白 */
        char *end = clean_cmd + strlen(clean_cmd) - 1;
        while (end > clean_cmd && (*end == ' ' || *end == '\t' || *end == '\n')) {
            *end = '\0';
            end--;
        }

        /* 输出建议的命令（返回给调用者使用） */
        printf("%s\n", clean_cmd);

        zsfree(suggested_cmd);
        zfree(user_input, total_len);
        return 0;
    } else {
        zwarnnam(nam, "命令翻译失败");
        zfree(user_input, total_len);
        return 1;
    }
#else
    printf("💡 命令建议功能需要 CURL 支持\n");
    zfree(user_input, total_len);
    return 1;
#endif
}

/* ============================================
 * AI 分析命令 - ai_analyze
 * ============================================ */

/*
 * ai_analyze 命令的实现
 * 用法: ai_analyze <命令>
 * 示例: ai_analyze "rm -rf /"
 */
static int
bin_ai_analyze(char *nam, char **args, Options ops, UNUSED(int func))
{
    if (!ai_enabled) {
        zwarnnam(nam, "AI 功能未启用");
        return 1;
    }

    if (!args[0]) {
        zwarnnam(nam, "用法: %s <命令>", nam);
        return 1;
    }

    char *command = zjoin(args, ' ', 1);

    printf("🔍 AI 命令分析 (占位符)\n");
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("命令: %s\n", command);
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("提示: 命令分析功能将在后续阶段实现\n");

    free(command);
    return 0;
}

/* ============================================
 * 模块注册
 * ============================================ */

/* 内置命令表 */
static struct builtin bintab[] = {
    BUILTIN("ai", 0, bin_ai, 0, -1, 0, NULL, NULL),
    BUILTIN("ai_suggest", 0, bin_ai_suggest, 0, -1, 0, NULL, NULL),
    BUILTIN("ai_analyze", 0, bin_ai_analyze, 0, -1, 0, NULL, NULL),
};

/* 模块特性 */
static struct features module_features = {
    bintab, sizeof(bintab)/sizeof(*bintab),
    NULL, 0,
    NULL, 0,
    NULL, 0,
    0
};

/* ============================================
 * 模块生命周期函数
 * ============================================ */

/*
 * setup_ - 模块设置（在加载时调用）
 */
/**/
int
setup_(UNUSED(Module m))
{
    return 0;
}

/*
 * features_ - 返回模块特性
 */
/**/
int
features_(Module m, char ***features)
{
    *features = featuresarray(m, &module_features);
    return 0;
}

/*
 * enables_ - 启用模块特性
 */
/**/
int
enables_(Module m, int **enables)
{
    return handlefeatures(m, &module_features, enables);
}

/*
 * boot_ - 模块初始化（在启用时调用）
 */
/**/
int
boot_(UNUSED(Module m))
{
    /* 加载配置 */
    ai_load_config();

    /* 输出初始化信息（仅在 AI 启用时） */
    if (ai_enabled) {
        printf("✨ iZsh AI 模块已加载\n");
        printf("   干预级别: %s\n",
               ai_intervention_level == 0 ? "关闭" :
               ai_intervention_level == 1 ? "建议" : "自动");
        printf("   API: %s\n", ai_api_url ? ai_api_url : "(未配置)");
        printf("   模型: %s\n", ai_model ? ai_model : "(未配置)");
    }

    return 0;
}

/*
 * cleanup_ - 模块清理（在禁用时调用）
 */
/**/
int
cleanup_(Module m)
{
    return setfeatureenables(m, &module_features, NULL);
}

/*
 * finish_ - 模块卸载（在移除时调用）
 */
/**/
int
finish_(UNUSED(Module m))
{
    /* 释放配置内存 */
    if (ai_api_key) {
        zsfree(ai_api_key);
        ai_api_key = NULL;
    }
    if (ai_api_url) {
        zsfree(ai_api_url);
        ai_api_url = NULL;
    }
    if (ai_model) {
        zsfree(ai_model);
        ai_model = NULL;
    }

    if (ai_enabled) {
        printf("👋 iZsh AI 模块已卸载\n");
    }

    return 0;
}
