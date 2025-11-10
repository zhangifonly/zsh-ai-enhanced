#!/usr/bin/env python3
"""
Claude Code AI 自动确认包装器

自动检测 Claude Code 的确认提示，并使用 iZsh 的 AI 功能自动选择最佳选项。
支持：
1. 文本确认提示（Y/n, 1/2/3 等）
2. 交互式菜单（箭头键导航）
"""

import sys
import os
import subprocess
import re
import signal
from threading import Thread, Event
import time
import termios
import tty

# Claude Code 特定的确认提示模式
CLAUDE_CODE_PATTERNS = [
    # 权限确认
    (r'Do you want to.*\?', 'permission_request'),
    (r'Can I.*\?', 'permission_request'),
    (r'Should I.*\?', 'permission_request'),
    (r'May I.*\?', 'permission_request'),
    (r'Allow.*\?', 'permission_request'),

    # 文件操作确认
    (r'create.*\?', 'file_operation'),
    (r'edit.*\?', 'file_operation'),
    (r'delete.*\?', 'file_operation'),
    (r'overwrite.*\?', 'file_operation'),

    # 命令执行确认
    (r'Run.*command.*\?', 'command_execution'),
    (r'Execute.*\?', 'command_execution'),
]

# 通用确认提示模式
CONFIRM_PATTERNS = [
    # 通用确认
    (r'\[Y/n\]|\[y/N\]', 'Y/n'),
    (r'\[yes/no\]', 'yes/no'),
    (r'\(Y/n\)|\(y/N\)', 'Y/n'),
    (r'\(yes/no\)', 'yes/no'),

    # 数字选项（支持更多数字）
    (r'\[1/2/3/4/5\]', '1/2/3/4/5'),
    (r'\[1/2/3/4\]', '1/2/3/4'),
    (r'\[1/2/3\]', '1/2/3'),
    (r'\[1/2\]', '1/2'),
    (r'\[0/1/2\]', '0/1/2'),
    (r'❯\s*\d+\.', 'numbered_menu'),  # Claude Code 菜单格式

    # 带描述的选项（如：1) Option A  2) Option B）
    (r'\d+\)\s+\w+.*?\d+\)\s+\w+', 'numbered_options'),

    # 继续/取消
    (r'\[continue/cancel\]', 'continue/cancel'),
    (r'\[proceed/abort\]', 'proceed/abort'),
    (r'\[c/q\]', 'c/q'),

    # 其他常见模式
    (r'\[a/r/s/k\]', 'a/r/s/k'),  # approve/reject/skip/kill
    (r'\[accept/reject\]', 'accept/reject'),
    (r'\[enable/disable\]', 'enable/disable'),

    # 回答问题
    (r'\?$', 'question_prompt'),
]

# 菜单检测模式
MENU_PATTERNS = [
    # Claude Code 特定菜单标记
    (r'❯\s*\d+\.', 'claude_menu'),  # ❯ 1. Yes
    # 箭头指示器
    (r'[>→▶]', 'arrow_indicator'),
    # 选中标记
    (r'[\*●■]', 'selection_marker'),
    # 反色/高亮（ANSI 转义序列）
    (r'\x1b\[7m', 'reverse_video'),
    (r'\x1b\[1m', 'bold'),
]

# 箭头键的 ANSI 转义序列
ARROW_KEYS = {
    'UP': '\x1b[A',
    'DOWN': '\x1b[B',
    'RIGHT': '\x1b[C',
    'LEFT': '\x1b[D',
    'ENTER': '\n',
}

class ClaudeCodeWrapper:
    def __init__(self, timeout=3):
        self.timeout = timeout
        self.process = None
        self.stop_event = Event()
        self.recent_lines = []  # 保存最近几行用于上下文分析
        self.max_context_lines = 10

    def add_to_context(self, line):
        """添加行到上下文缓冲区"""
        self.recent_lines.append(line)
        if len(self.recent_lines) > self.max_context_lines:
            self.recent_lines.pop(0)

    def get_context(self):
        """获取上下文（最近几行）"""
        return '\n'.join(self.recent_lines)

    def detect_confirm_prompt(self, line):
        """检测是否是确认提示"""
        for pattern, options in CONFIRM_PATTERNS:
            if re.search(pattern, line, re.IGNORECASE):
                return options
        return None

    def detect_menu(self, context):
        """检测是否是交互式菜单

        返回: (is_menu, menu_items)
        """
        # 检查是否有菜单标记
        has_menu_marker = False
        for pattern, _ in MENU_PATTERNS:
            if re.search(pattern, context):
                has_menu_marker = True
                break

        if not has_menu_marker:
            return False, []

        # 提取菜单项
        lines = context.split('\n')
        menu_items = []

        # Claude Code 特定格式：❯ 1. Yes
        claude_menu_pattern = r'(❯)?\s*(\d+)\.\s+(.+?)(?:\s+\([^)]+\))?$'

        for i, line in enumerate(lines):
            # 清理 ANSI 转义序列
            clean_line = re.sub(r'\x1b\[[0-9;]*m', '', line)
            clean_line = clean_line.strip()

            # 检测 Claude Code 菜单格式
            claude_match = re.search(claude_menu_pattern, clean_line)
            if claude_match:
                is_selected = claude_match.group(1) == '❯'
                number = claude_match.group(2)
                text = claude_match.group(3).strip()

                menu_items.append({
                    'index': i,
                    'number': number,
                    'text': text,
                    'is_selected': is_selected,
                    'format': 'claude_code'
                })
                continue

            # 检测通用箭头标记
            if re.search(r'[>→▶\*●■]', line):
                # 移除箭头标记
                clean_line = re.sub(r'^[>→▶\*●■]\s*', '', clean_line)

                if clean_line:
                    menu_items.append({
                        'index': i,
                        'text': clean_line,
                        'is_selected': '>' in line or '→' in line or '▶' in line or '❯' in line,
                        'format': 'generic'
                    })

        return len(menu_items) > 0, menu_items

    def extract_options_with_descriptions(self, context):
        """从上下文中提取带描述的选项

        示例：
        1) Use recommended settings (default)
        2) Custom configuration
        3) Skip this step

        返回：选项描述字符串
        """
        # 检测编号列表格式
        pattern = r'(\d+)\)\s+(.+?)(?=\n\d+\)|$)'
        matches = re.findall(pattern, context, re.MULTILINE | re.DOTALL)

        if matches:
            descriptions = []
            for num, desc in matches:
                desc = desc.strip()
                descriptions.append(f"{num}: {desc}")
            return ' | '.join(descriptions)

        return None

    def choose_best_menu_item(self, menu_items):
        """使用 AI 选择最佳菜单项

        返回: (选中项的索引, 选择的数字/文本)
        """
        # 构造选项描述
        if menu_items and menu_items[0].get('format') == 'claude_code':
            # Claude Code 格式，使用数字
            options_text = ' | '.join([f"{item.get('number', i+1)}: {item['text']}" for i, item in enumerate(menu_items)])
        else:
            # 通用格式
            options_text = ' | '.join([f"{i+1}: {item['text']}" for i, item in enumerate(menu_items)])

        # 构造 AI prompt
        ai_prompt = f"""这是一个菜单选择界面，请选择最佳选项：

{options_text}

选择原则：
1. 选择最完整、功能最全面的选项
2. 有'推荐'或'默认'标记的优先
3. 避免'跳过'、'取消'等消极选项
4. 选择能让程序继续运行的选项
5. 如果选项描述中包含 'shift+tab' 等快捷键说明，忽略这些提示

只输出选项编号（1、2、3 等），不要任何解释。"""

        try:
            result = subprocess.run(
                [os.path.expanduser('~/.local/bin/izsh'), '-c', f'source ~/.izshrc 2>/dev/null && ai_suggest "{ai_prompt}"'],
                capture_output=True,
                text=True,
                timeout=self.timeout + 3
            )

            output = result.stdout.strip()
            # 提取数字
            match = re.search(r'(\d+)', output)
            if match:
                choice_num = int(match.group(1))

                # 对于 Claude Code 格式，返回实际的数字
                if menu_items and menu_items[0].get('format') == 'claude_code':
                    for i, item in enumerate(menu_items):
                        if item.get('number') == str(choice_num):
                            return i, str(choice_num)

                # 对于通用格式，返回索引
                if 1 <= choice_num <= len(menu_items):
                    return choice_num - 1, str(choice_num)

        except Exception as e:
            print(f"❌ AI 菜单选择失败: {e}", file=sys.stderr)

        # 默认选择第一个（通常是默认选项）
        default_index = 0
        default_number = menu_items[0].get('number', '1') if menu_items else '1'
        return default_index, default_number

    def call_ai_confirm(self, prompt, options, context=None):
        """调用 iZsh 的 ai_confirm 函数"""
        try:
            # 如果有上下文中的选项描述，优先使用
            option_descriptions = None
            if context:
                option_descriptions = self.extract_options_with_descriptions(context)

            # 如果找到了详细的选项描述，用它替换 options
            if option_descriptions:
                display_options = option_descriptions
            else:
                display_options = options

            # 构造调用命令
            # 将完整提示（包括上下文）传递给 AI
            full_prompt = prompt
            if context and not option_descriptions:
                # 如果没有结构化的选项描述，但有上下文，添加上下文
                context_lines = context.split('\n')
                if len(context_lines) > 3:
                    full_prompt = '\n'.join(context_lines[-3:]) + '\n' + prompt

            cmd = f'''
source ~/.izshrc 2>/dev/null
ai_confirm "{full_prompt}" "{display_options}" {self.timeout}
'''

            result = subprocess.run(
                [os.path.expanduser('~/.local/bin/izsh'), '-c', cmd],
                capture_output=True,
                text=True,
                timeout=self.timeout + 5  # 增加超时时间，因为 AI 需要分析
            )

            # 提取 AI 的选择
            output = result.stdout.strip()
            lines = output.split('\n')

            # 查找 AI 的选择（最后一行非空行）
            for line in reversed(lines):
                line = line.strip()
                if line and not line.startswith('⏰') and not line.startswith('✅'):
                    return line

            # 如果没有找到，返回第一个选项
            first_option = options.split('/')[0].strip('[]()')
            # 如果是数字，尝试提取
            match = re.search(r'\d+', first_option)
            if match:
                return match.group()
            return first_option

        except Exception as e:
            print(f"❌ AI 确认失败: {e}", file=sys.stderr)
            # 返回默认值（第一个选项）
            first_option = options.split('/')[0].strip('[]()')
            match = re.search(r'\d+', first_option)
            if match:
                return match.group()
            return first_option

    def run(self, command_args):
        """运行 Claude Code 并处理确认提示"""
        print("🤖 AI 自动确认模式已启用")
        print(f"提示：所有确认将在 {self.timeout} 秒后自动由 AI 选择")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        try:
            # 启动 Claude Code
            self.process = subprocess.Popen(
                command_args,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            current_line = ""
            last_menu_check = time.time()

            # 读取输出
            while True:
                char = self.process.stdout.read(1)
                if not char:
                    break

                # 输出到终端
                sys.stdout.write(char)
                sys.stdout.flush()

                current_line += char

                # 检测换行或特殊字符
                if char in ['\n', '\r']:
                    # 将完整的行添加到上下文
                    if current_line.strip():
                        self.add_to_context(current_line.strip())
                    current_line = ""

                    # 定期检测菜单（每秒检测一次，避免过于频繁）
                    now = time.time()
                    if now - last_menu_check > 1.0:
                        context = self.get_context()
                        is_menu, menu_items = self.detect_menu(context)

                        if is_menu:
                            print("\n🔍 检测到交互式菜单，AI 正在分析...")
                            time.sleep(self.timeout)  # 等待倒计时

                            # 选择最佳项（返回索引和数字）
                            best_index, choice_number = self.choose_best_menu_item(menu_items)
                            selected_item = menu_items[best_index]

                            print(f"✅ AI 选择: {selected_item['text']}")

                            # 对于 Claude Code 数字格式，直接输入数字
                            if menu_items and menu_items[0].get('format') == 'claude_code':
                                # 直接发送数字选择
                                self.process.stdin.write(choice_number + '\n')
                                self.process.stdin.flush()
                            else:
                                # 通用格式：使用箭头键导航
                                # 计算当前选中项的位置
                                current_index = 0
                                for i, item in enumerate(menu_items):
                                    if item.get('is_selected'):
                                        current_index = i
                                        break

                                # 发送箭头键移动到目标位置
                                moves = best_index - current_index
                                if moves > 0:
                                    # 向下移动
                                    for _ in range(moves):
                                        self.process.stdin.write(ARROW_KEYS['DOWN'])
                                        self.process.stdin.flush()
                                        time.sleep(0.1)
                                elif moves < 0:
                                    # 向上移动
                                    for _ in range(abs(moves)):
                                        self.process.stdin.write(ARROW_KEYS['UP'])
                                        self.process.stdin.flush()
                                        time.sleep(0.1)

                                # 发送回车确认
                                time.sleep(0.2)
                                self.process.stdin.write(ARROW_KEYS['ENTER'])
                                self.process.stdin.flush()

                            # 清空上下文
                            self.recent_lines = []
                            last_menu_check = now

                        last_menu_check = now

                    continue

                # 检测确认提示
                options = self.detect_confirm_prompt(current_line)
                if options:
                    # 提取提示文本（去掉选项部分）
                    prompt = re.sub(r'\s*[\[\(].*?[\]\)].*$', '', current_line).strip()

                    # 获取上下文
                    context = self.get_context()

                    # 调用 AI 确认（传递上下文）
                    choice = self.call_ai_confirm(prompt, options, context)

                    # 发送选择到程序
                    self.process.stdin.write(choice + '\n')
                    self.process.stdin.flush()

                    # 清空上下文和当前行
                    self.recent_lines = []
                    current_line = ""

            # 等待进程结束
            return self.process.wait()

        except KeyboardInterrupt:
            print("\n⚠️ 用户中断")
            if self.process:
                self.process.terminate()
            return 130

        except Exception as e:
            print(f"❌ 错误: {e}", file=sys.stderr)
            return 1

def main():
    if len(sys.argv) < 2:
        print("用法: claude_code_wrapper.py <claude-code 命令及参数>")
        print("示例: claude_code_wrapper.py claude-code --version")
        sys.exit(1)

    # 获取超时设置
    timeout = int(os.environ.get('IZSH_AI_CONFIRM_TIMEOUT', 3))

    wrapper = ClaudeCodeWrapper(timeout=timeout)
    exit_code = wrapper.run(sys.argv[1:])
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
