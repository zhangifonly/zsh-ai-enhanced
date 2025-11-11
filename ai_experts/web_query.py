#!/usr/bin/env python3
"""
AI 专家联网查询工具

功能：
- 查询命令的最新文档和用法
- 搜索最佳实践和教程
- 获取官方文档
- 查找社区讨论和问题解决方案
"""

import sys
import json
import subprocess
import os
from pathlib import Path

# 颜色定义
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    CYAN = '\033[36m'
    RED = '\033[31m'

def color_print(text, color=Colors.RESET, bold=False):
    """彩色打印"""
    prefix = Colors.BOLD if bold else ''
    print(f"{prefix}{color}{text}{Colors.RESET}")

def call_ai(prompt):
    """调用 iZsh 的 AI 功能"""
    try:
        # 使用 ai_suggest 函数
        result = subprocess.run(
            [os.path.expanduser('~/.local/bin/izsh'), '-c',
             f'source ~/.izshrc 2>/dev/null && ai_suggest "{prompt}"'],
            capture_output=True,
            text=True,
            timeout=30,
            env={**os.environ,
                 'DYLD_LIBRARY_PATH': '/Users/zhangzhen/anaconda3/lib',
                 'OBJC_DISABLE_INITIALIZE_FORK_SAFETY': 'YES'}
        )
        return result.stdout.strip()
    except Exception as e:
        return f"AI 调用失败: {e}"

def web_search(query):
    """
    使用 AI 进行网络搜索

    这里假设 iZsh 集成了网络搜索功能
    如果没有，可以使用其他方式如 curl + API
    """
    search_prompt = f"""请帮我搜索以下内容的最新信息：

{query}

请提供：
1. 官方文档链接
2. 主要功能和用法
3. 常见命令示例
4. 最佳实践建议
5. 常见问题解决方案

如果无法联网，请基于你的知识库提供信息，并注明可能不是最新的。"""

    return call_ai(search_prompt)

def query_command_usage(command):
    """查询命令用法"""

    color_print(f"\n{'='*70}", Colors.CYAN, True)
    color_print(f"  查询命令用法: {command}", Colors.CYAN, True)
    color_print(f"{'='*70}", Colors.CYAN, True)

    # 先尝试本地 man 手册
    color_print("\n📖 本地文档查询...", Colors.BLUE)
    try:
        result = subprocess.run(
            ['man', command],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            lines = result.stdout.split('\n')
            # 显示 man 手册的前 30 行
            color_print("\n本地 man 手册摘要：", Colors.GREEN)
            for line in lines[:30]:
                print(line)
            print("...")
            color_print("\n💡 使用 'man " + command + "' 查看完整文档", Colors.YELLOW)
        else:
            color_print("本地 man 手册未找到", Colors.YELLOW)
    except Exception as e:
        color_print(f"本地查询失败: {e}", Colors.RED)

    # 尝试 --help
    color_print(f"\n📋 运行 {command} --help...", Colors.BLUE)
    try:
        for help_flag in ['--help', '-h', 'help']:
            result = subprocess.run(
                [command, help_flag],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0 or result.stdout:
                lines = result.stdout.split('\n') if result.stdout else result.stderr.split('\n')
                color_print("\n帮助信息摘要：", Colors.GREEN)
                for line in lines[:20]:
                    print(line)
                if len(lines) > 20:
                    print("...")
                break
    except Exception:
        pass

    # 联网查询最新文档
    color_print("\n🌐 联网查询最新用法...", Colors.BLUE)
    query = f"{command} 命令用法、示例和最佳实践"

    color_print("\n正在搜索...", Colors.YELLOW)
    result = web_search(query)

    color_print("\nAI 搜索结果：", Colors.GREEN, True)
    print(result)

    color_print(f"\n{'='*70}", Colors.CYAN, True)

def query_expert_usage(expert_name):
    """查询专家工具的用法"""

    color_print(f"\n{'='*70}", Colors.CYAN, True)
    color_print(f"  查询专家工具: {expert_name}", Colors.CYAN, True)
    color_print(f"{'='*70}", Colors.CYAN, True)

    # 构造查询
    query = f"{expert_name} 工具的最新功能、用法、最佳实践和示例"

    color_print("\n🌐 联网查询最新文档...", Colors.BLUE)
    color_print("正在搜索...", Colors.YELLOW)

    result = web_search(query)

    color_print("\nAI 搜索结果：", Colors.GREEN, True)
    print(result)

    # 如果是 Claude Code 或 GitHub Copilot，提供额外的资源链接
    resources = {
        'claude': [
            'https://docs.anthropic.com/claude/docs/claude-code',
            'https://github.com/anthropics/claude-code',
        ],
        'copilot': [
            'https://docs.github.com/en/copilot',
            'https://github.com/github/copilot-docs',
        ],
        'codex': [
            'https://platform.openai.com/docs/guides/code',
            'https://github.com/features/copilot',
        ]
    }

    for key, urls in resources.items():
        if key in expert_name.lower():
            color_print("\n📚 官方资源链接：", Colors.CYAN, True)
            for url in urls:
                print(f"  - {url}")

    color_print(f"\n{'='*70}", Colors.CYAN, True)

def search_best_practices(topic):
    """搜索最佳实践"""

    color_print(f"\n{'='*70}", Colors.CYAN, True)
    color_print(f"  搜索最佳实践: {topic}", Colors.CYAN, True)
    color_print(f"{'='*70}", Colors.CYAN, True)

    query = f"{topic} 的最佳实践、常见陷阱、性能优化建议和实战经验"

    color_print("\n🌐 联网搜索...", Colors.BLUE)
    color_print("正在搜索...", Colors.YELLOW)

    result = web_search(query)

    color_print("\nAI 搜索结果：", Colors.GREEN, True)
    print(result)

    color_print(f"\n{'='*70}", Colors.CYAN, True)

def find_solutions(problem):
    """查找问题解决方案"""

    color_print(f"\n{'='*70}", Colors.CYAN, True)
    color_print(f"  查找解决方案", Colors.CYAN, True)
    color_print(f"{'='*70}", Colors.CYAN, True)

    query = f"""我遇到以下问题：

{problem}

请帮我查找：
1. 可能的原因
2. 解决方案和步骤
3. 类似问题的讨论（Stack Overflow, GitHub Issues）
4. 预防方法

如果无法联网搜索，请基于常见情况提供建议。"""

    color_print("\n🌐 联网搜索解决方案...", Colors.BLUE)
    color_print("正在搜索...", Colors.YELLOW)

    result = call_ai(query)

    color_print("\nAI 搜索结果：", Colors.GREEN, True)
    print(result)

    color_print(f"\n{'='*70}", Colors.CYAN, True)

def show_help():
    """显示帮助信息"""
    help_text = f"""
{Colors.CYAN}{Colors.BOLD}AI 专家联网查询工具{Colors.RESET}

{Colors.YELLOW}用法:{Colors.RESET}
    ai-query [命令] [参数]

{Colors.YELLOW}命令:{Colors.RESET}
    command <cmd>          查询命令用法（如 docker, git）
    expert <name>          查询专家工具用法（如 claude, copilot）
    best <topic>           搜索最佳实践
    solve <problem>        查找问题解决方案
    help                   显示此帮助

{Colors.YELLOW}示例:{Colors.RESET}
    ai-query command docker        # 查询 docker 命令用法
    ai-query expert claude         # 查询 Claude Code 用法
    ai-query best "Python async"   # 搜索 Python 异步最佳实践
    ai-query solve "npm install 失败"  # 查找 npm 安装失败的解决方案

{Colors.YELLOW}快捷别名（可添加到 ~/.izshrc）:{Colors.RESET}
    alias cmd-help='ai-query command'
    alias expert-help='ai-query expert'
    alias find-solution='ai-query solve'

{Colors.YELLOW}提示:{Colors.RESET}
    - 本工具会先查询本地文档（man, --help）
    - 然后使用 AI 联网搜索最新信息
    - 如果 AI 无法联网，会基于知识库提供信息
    - 搜索结果会突出显示关键信息
"""
    print(help_text)

def main():
    """主函数"""
    if len(sys.argv) < 2:
        color_print("\n❌ 请指定命令", Colors.RED)
        show_help()
        return

    command = sys.argv[1]

    if command == 'command' or command == 'cmd':
        if len(sys.argv) < 3:
            color_print("\n❌ 请指定要查询的命令", Colors.RED)
            print("用法: ai-query command <命令名>")
            return
        query_command_usage(sys.argv[2])

    elif command == 'expert':
        if len(sys.argv) < 3:
            color_print("\n❌ 请指定专家工具名称", Colors.RED)
            print("用法: ai-query expert <工具名>")
            return
        query_expert_usage(sys.argv[2])

    elif command == 'best' or command == 'practices':
        if len(sys.argv) < 3:
            color_print("\n❌ 请指定主题", Colors.RED)
            print("用法: ai-query best <主题>")
            return
        topic = ' '.join(sys.argv[2:])
        search_best_practices(topic)

    elif command == 'solve' or command == 'fix':
        if len(sys.argv) < 3:
            color_print("\n❌ 请描述问题", Colors.RED)
            print("用法: ai-query solve <问题描述>")
            return
        problem = ' '.join(sys.argv[2:])
        find_solutions(problem)

    elif command == 'help' or command == '-h' or command == '--help':
        show_help()

    else:
        color_print(f"\n❌ 未知命令: {command}", Colors.RED)
        show_help()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        color_print("\n\n👋 已取消", Colors.YELLOW)
        sys.exit(0)
    except Exception as e:
        color_print(f"\n❌ 错误: {e}", Colors.RED)
        import traceback
        traceback.print_exc()
        sys.exit(1)
