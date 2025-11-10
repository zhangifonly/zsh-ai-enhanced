# iZsh UTF-8 编码问题分析

## 🐛 问题描述

当用户在 iZsh 中输入中文命令（如"列目录"）时，AI 返回错误的翻译（如"echo HELLO"）。

## 🔍 问题定位

通过调试发现：

### 正确的 UTF-8 编码
```
"列目录" = e5 88 97 e7 9b ae e5 bd 95
```

### 实际传递的编码（乱码）
```
args[0] = e5 83 a8 83 b7 e7 83 bb ae e5 bd 83 b5
显示为：僨��烻�彃�
```

### 问题点
- ✅ Locale 设置正确（zh_CN.UTF-8）
- ✅ MULTIBYTE_SUPPORT 已启用
- ✅ echo 输出 UTF-8 正确
- ❌ **zsh 解析命令行参数时字符被破坏**

## 💡 临时解决方案

### 方案 1：使用英文命令
```bash
# 而不是"列目录"，使用英文
list directory     # → ls
show files         # → ls
```

### 方案 2：创建别名
在 `~/.izshrc` 中添加：
```bash
alias 列表='ls'
alias 查看='cat'
alias 删除='rm'
alias 复制='cp'
alias 移动='mv'
```

### 方案 3：使用 ai 命令直接调用
```bash
# 不要直接输入中文命令，而是：
ai "列目录"
# 然后复制输出的命令执行
```

## 🔧 根本原因

这是 zsh 内部字符编码转换的问题。当 zsh 解析命令行并将参数传递给 C 模块时，多字节 UTF-8 字符被错误地转换了。

可能的原因：
1. zsh 的内部字符串表示使用了某种转义或编码
2. 参数传递过程中字符集转换出错
3. 宽字符（wchar_t）和多字节字符（char*）转换问题

## 🔬 进一步调查方向

### 1. 检查 zsh 内部字符串表示
zsh 可能使用 Meta 字符来表示某些特殊字符：
- Meta 字符（0x83）用于转义高位字节
- 可能需要使用 `unmeta()` 函数解码

### 2. 查看 zsh 源码中的多字节处理
- `Src/utils.c` 中的字符编码函数
- `getstrvalue()` 如何处理多字节字符
- 参数解析器如何转换字符串

### 3. 测试 Meta 字符假设

如果是 Meta 编码问题：
```
原始：e5 88 97
Meta：e5 83 a8 83 b7 (?)
```

规律：每个高位字节被拆分为 0x83 + (byte & 0x7f)

## ✅ 可能的修复方案

### 方案 A：在 C 代码中解码 Meta 字符
```c
/* 在 ai.c 中添加 Meta 解码 */
char *unmeta_string(char *str) {
    // zsh 内部可能有 unmeta() 函数
    // 需要查找并使用
}
```

### 方案 B：使用 zsh 的字符串函数
```c
/* 使用 zsh 提供的字符串处理函数 */
char *user_input = getsparam("参数名");  // 获取参数的正确方式
```

### 方案 C：修改参数传递方式
在 shell 层面进行编码修复，然后再传递给 C 模块。

## 📝 下一步行动

1. **立即**：提供临时解决方案给用户（使用英文或别名）
2. **短期**：研究 zsh Meta 字符编码，添加解码函数
3. **长期**：提交 patch 给 zsh 项目或找到正确的 API

## 🎯 用户建议

目前请使用以下替代方案：

### 推荐：使用英文描述
```bash
list directory      → ls
show current path   → pwd
create folder test  → mkdir test
remove file xxx     → rm xxx
```

### 或者：使用 ai 命令
```bash
ai "列目录"   # 查看翻译结果
ls            # 手动执行
```

### 创建中文别名
```bash
# 编辑 ~/.izshrc 添加：
alias 列表='ls'
alias 当前目录='pwd'
alias 创建目录='mkdir'
alias 查看文件='cat'
```

---

**状态**: 问题已定位，需要进一步研究 zsh 内部编码机制
**优先级**: 高
**复杂度**: 中等（需要深入了解 zsh 内部实现）
