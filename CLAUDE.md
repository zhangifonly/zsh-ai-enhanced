# CLAUDE.md

This file provides guidance to Droid Code (droid.ai/code) when working with code in this repository.

## 项目概述

这是 **Zsh（Z Shell）5.10** 的源代码仓库。Zsh 是一个功能丰富的 Unix shell，具有强大的脚本能力、命令行编辑、补全系统等特性。

## 构建和测试命令

### 配置和构建

```bash
# 从 Git 仓库克隆后需要预配置（正常发行版跳过此步骤）
./Util/preconfig

# 配置（查看所有选项）
./configure --help

# 标准配置
./configure

# 构建
make

# 运行测试
make check

# 运行特定测试
make TESTNUM=C02 check    # 运行单个测试
make TESTNUM=C check      # 运行整个测试类别

# 详细测试输出
ZTST_verbose=1 make check

# 测试失败后继续
ZTST_continue=1 make check
```

### 安装

```bash
# 完整安装
make install

# 分步安装
make install.bin        # 仅安装二进制文件
make install.modules    # 安装动态模块（动态加载启用时必需）
make install.man        # 安装手册页
make install.fns        # 安装 shell 函数
make install.info       # 安装 info 文档
```

### 模块配置

```bash
# 准备模块配置
cd Src && make prep

# 编辑 config.modules 文件后重新准备
make prep
```

### 清理

```bash
make clean          # 清理构建文件
make distclean      # 恢复到原始状态
```

## 代码架构

### 目录结构

- **Src/**: 核心源代码
  - 主要 C 源文件（builtin.c, exec.c, glob.c, hist.c, jobs.c, lex.c 等）
  - **Builtins/**: 内置命令模块
  - **Modules/**: 可加载功能模块
  - **Zle/**: Zsh 行编辑器（Zsh Line Editor）

- **Doc/**: 文档源文件
  - **Zsh/**: YODL 格式的文档源文件（.yo）
  - 生成的手册页、TeXinfo、PDF 等

- **Test/**: 测试套件
  - 测试文件格式：`[类别][编号][名称].ztst`
  - 测试类别：
    - **A**: 基本命令解析和执行
    - **B**: 内置命令
    - **C**: 特殊语法的 shell 命令
    - **D**: 替换
    - **E**: 选项
    - **K**: 从 ksh 采用的特性
    - **P**: 特权操作（需要超级用户权限）
    - **V**: 模块
    - **W**: 内置交互式命令和构造
    - **X**: 行编辑
    - **Y**: 补全
    - **Z**: 独立系统和用户贡献

- **Functions/**: Shell 函数集合
  - 按功能分类的可自动加载函数

- **Completion/**: 补全系统
  - 命令补全定义和函数

- **StartupFiles/**: Shell 启动文件示例

- **Config/**: 构建配置脚本和工具

- **Util/**: 实用工具脚本

- **Etc/**: 杂项文档和资源

- **Misc/**: 其他文件和示例

### 模块系统

Zsh 采用模块化架构，默认启用动态加载：

- **config.modules**: 控制模块的编译和加载行为
  - `link`: `dynamic`（动态链接）/ `static`（静态链接）/ `no`（不编译）
  - `load`: `yes`（默认可见）/ `no`（需要 `zmodload` 显式加载）
  - `auto`: `yes`（configure 时自动生成）/ `no`（保留手动编辑）

- 核心模块默认编译到 shell 中：complete, compctl, zle, computil, complist, sched, parameter, zleparameter, rlimits

- 模块安装路径：`EPREFIX/lib/zsh/<版本号>/`

### 构建系统

- 使用 **autoconf** 生成 configure 脚本（configure.ac 为模板）
- 支持 VPATH 构建（源代码和构建目录分离）
- 主 Makefile 递归调用子目录 Makefile（Doc, Src, Test 等）

## 开发注意事项

### 编译器和标志

```bash
# 使用不同编译器
CC=c89 ./configure

# 添加编译标志
./configure --enable-cflags=-O2 --enable-libs=-lposix

# 或者设置环境变量
CC=c89 CFLAGS=-O2 LIBS=-lposix ./configure
```

### 调试选项

```bash
./configure --enable-zsh-debug       # 启用调试代码和符号
./configure --enable-zsh-mem-debug   # 调试内存分配
./configure --enable-zsh-hash-debug  # 调试内部哈希表
```

### 测试编写

- 参考 `Test/B01cd.ztst` 作为测试编写模板
- 测试在 `make test` 或 `make check` 时运行
- 通常在第一个错误时中止，使用 `ZTST_continue=1` 继续到结束

### 配置文件

- 检查生成的 `config.h`（用户配置段）
- 验证 `HOSTTYPE`, `OSTYPE`, `MACHTYPE`, `VENDOR` 的值
- 检查顶层 `Makefile` 的用户配置段

### 多字节字符支持

- 默认启用（--enable-multibyte）
- 支持 UTF-8 等字符集
- `MULTIBYTE` 选项在所有模拟模式下默认开启

### 大文件和 64 位整数支持

- 默认启用 `--enable-largefile`
- 在支持的 32 位系统上自动启用 64 位算术

### 文档生成

需要额外工具：
- **YODL**：处理 .yo 文档源文件
- **Perl** 和交互式手册工具（colcrt, col）

如果没有这些工具，可以从相同位置下载预生成的文档包（zsh-doc.tar.gz）。

## 重要文件

- **README**: 版本信息、安装说明、不兼容性说明
- **INSTALL**: 详细的编译和安装指南
- **MACHINES**: 特定架构的说明
- **FEATURES**: 功能列表
- **NEWS**: 最新变更
- **ChangeLog**: 详细的变更历史
- **LICENCE**: 许可信息
- **Etc/BUGS**: 已知 bug
- **Etc/FAQ**: 常见问题
- **Etc/CONTRIBUTORS**: 贡献者列表

## 配置选项摘要

常用选项：

```bash
--prefix=PREFIX              # 安装路径前缀 [/usr/local]
--enable-etcdir=DIR          # 全局脚本目录 [/etc]
--enable-fndir=DIR           # 函数安装目录
--enable-site-fndir=DIR      # 站点特定函数目录
--enable-function-subdirs    # 函数安装到子目录
--disable-dynamic            # 禁用动态模块加载
--enable-pcre                # 启用 PCRE 正则表达式支持
--enable-cap                 # 启用 POSIX capabilities 支持
--enable-multibyte           # 启用多字节字符支持
--enable-largefile           # 启用大文件支持
--enable-max-function-depth=N # 设置最大函数递归深度 [默认 4096]
--enable-custom-patchlevel=STR # 自定义补丁级别标识
```

## 提交和报告

- 邮件列表：zsh-workers@zsh.org
- 协调员：coordinator@zsh.org
- 报告 bug 时使用 `zsh -f` 重现（跳过启动文件）
- 使用 `Util/reporter` 脚本生成环境报告
