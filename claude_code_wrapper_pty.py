#!/usr/bin/env python3
"""
Claude Code AI 自动确认包装器（PTY 版本）

使用伪终端（PTY）确保 Claude Code 的输出正常显示
自动检测确认提示，并使用 iZsh 的 AI 功能自动选择最佳选项
"""

import sys
import os
import pty
import select
import subprocess
import re
import signal
import time
import termios
import tty
import fcntl
import struct

# Claude Code 特定的确认提示模式
CLAUDE_CODE_PATTERNS = [
    (r'Do you want to.*\?', 'permission_request'),
    (r'Can I.*\?', 'permission_request'),
    (r'Should I.*\?', 'permission_request'),
    (r'May I.*\?', 'permission_request'),
    (r'Allow.*\?', 'permission_request'),
    (r'create.*\?', 'file_operation'),
    (r'edit.*\?', 'file_operation'),
    (r'delete.*\?', 'file_operation'),
    (r'overwrite.*\?', 'file_operation'),
    (r'Run.*command.*\?', 'command_execution'),
    (r'Execute.*\?', 'command_execution'),
]

# 通用确认提示模式
CONFIRM_PATTERNS = [
    (r'\[Y/n\]|\[y/N\]', 'Y/n'),
    (r'\[yes/no\]', 'yes/no'),
    (r'\(Y/n\)|\(y/N\)', 'Y/n'),
    (r'\(yes/no\)', 'yes/no'),
    (r'\[1/2/3/4/5\]', '1/2/3/4/5'),
    (r'\[1/2/3/4\]', '1/2/3/4'),
    (r'\[1/2/3\]', '1/2/3'),
    (r'\[1/2\]', '1/2'),
    (r'❯\s*\d+\.', 'numbered_menu'),
    (r'\d+\)\s+\w+.*?\d+\)\s+\w+', 'numbered_options'),
]

# 箭头键的 ANSI 转义序列
ARROW_KEYS = {
    'UP': '\x1b[A',
    'DOWN': '\x1b[B',
    'ENTER': '\n',
}

class ClaudeCodeWrapperPTY:
    def __init__(self, timeout=3):
        self.timeout = timeout
        self.master_fd = None
        self.pid = None
        self.recent_lines = []
        self.max_context_lines = 10
        self.current_line = ""
        self.last_check_time = time.time()

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
        """检测是否是交互式菜单"""
        # 检测 Claude Code 菜单格式：❯ 1. Yes
        claude_menu_pattern = r'❯\s*\d+\.'
        if re.search(claude_menu_pattern, context):
            lines = context.split('\n')
            menu_items = []

            for line in lines:
                match = re.search(r'(❯)?\s*(\d+)\.\s+(.+?)$', line)
                if match:
                    menu_items.append({
                        'number': match.group(2),
                        'text': match.group(3).strip(),
                        'format': 'claude_code'
                    })

            if menu_items:
                return True, menu_items

        return False, []

    def call_ai_suggest(self, prompt):
        """调用 AI 获取建议"""
        try:
            result = subprocess.run(
                [os.path.expanduser('~/.local/bin/izsh'), '-c',
                 f'source ~/.izshrc 2>/dev/null && ai_suggest "{prompt}"'],
                capture_output=True,
                text=True,
                timeout=self.timeout + 3,
                env={**os.environ,
                     'DYLD_LIBRARY_PATH': '/Users/zhangzhen/anaconda3/lib',
                     'OBJC_DISABLE_INITIALIZE_FORK_SAFETY': 'YES'}
            )

            output = result.stdout.strip()
            # 提取数字或文本
            match = re.search(r'(\d+|[YyNn]|yes|no)', output)
            if match:
                return match.group(1)

        except Exception as e:
            print(f"\n❌ AI 决策失败: {e}", file=sys.stderr)

        return None

    def handle_menu(self, menu_items):
        """处理菜单选择"""
        # 构造 AI prompt
        options_text = ' | '.join([f"{item['number']}: {item['text']}" for item in menu_items])
        ai_prompt = f"""这是一个菜单选择界面，请选择最佳选项：

{options_text}

选择原则：
1. 选择最完整、功能最全面的选项
2. 有'推荐'或'默认'标记的优先
3. 避免'跳过'、'取消'等消极选项
4. 选择能让程序继续运行的选项

只输出选项编号（1、2、3 等），不要任何解释。"""

        choice = self.call_ai_suggest(ai_prompt)
        if choice and choice.isdigit():
            return choice

        # 默认选择第一个
        return menu_items[0]['number'] if menu_items else '1'

    def handle_confirm(self, prompt, options):
        """处理确认提示"""
        ai_prompt = f"""这是一个确认提示：'{prompt}'
可选项：'{options}'

请选择最佳选项。选择原则：
1. 如果是 Y/n 类型，通常选择 Y（继续）
2. 如果是数字选项，分析后选择最佳
3. 选择能让程序继续执行的选项

只输出选项字符（如 Y、n、1、2 等），不要任何解释。"""

        choice = self.call_ai_suggest(ai_prompt)
        if choice:
            return choice

        # 默认选择第一个选项
        first_option = options.split('/')[0].strip('[]()')
        match = re.search(r'\d+|[Yy]', first_option)
        return match.group() if match else 'Y'

    def process_output(self, data):
        """处理输出数据"""
        # 显示输出
        sys.stdout.write(data)
        sys.stdout.flush()

        # 更新当前行
        self.current_line += data

        # 检测换行
        if '\n' in data or '\r' in data:
            lines = self.current_line.split('\n')
            for line in lines[:-1]:
                if line.strip():
                    self.add_to_context(line.strip())
            self.current_line = lines[-1]

        # 定期检测（避免过于频繁）
        now = time.time()
        if now - self.last_check_time > 0.5:
            self.last_check_time = now

            # 检测菜单
            context = self.get_context()
            is_menu, menu_items = self.detect_menu(context)

            if is_menu:
                print("\n🔍 检测到交互式菜单，AI 正在分析...")
                time.sleep(self.timeout)

                choice = self.handle_menu(menu_items)
                print(f"✅ AI 选择: {choice}")

                # 发送选择
                return choice + '\n'

            # 检测确认提示
            if self.current_line.strip():
                options = self.detect_confirm_prompt(self.current_line)
                if options:
                    prompt = re.sub(r'\s*[\[\(].*?[\]\)].*$', '', self.current_line).strip()
                    print(f"\n⏰ 检测到确认提示，倒计时 {self.timeout} 秒...")
                    time.sleep(self.timeout)

                    choice = self.handle_confirm(prompt, options)
                    print(f"✅ AI 自动选择: {choice}")

                    # 发送选择
                    self.current_line = ""
                    return choice + '\n'

        return None

    def run(self, command_args):
        """运行 Claude Code 并处理交互"""
        print("🤖 AI 自动确认模式已启用")
        print(f"提示：所有确认将在 {self.timeout} 秒后自动由 AI 选择")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        # 设置终端为 raw 模式
        old_tty = termios.tcgetattr(sys.stdin)

        try:
            # 创建伪终端
            self.pid, self.master_fd = pty.fork()

            if self.pid == 0:  # 子进程
                # 在子进程中执行 Claude Code
                os.execvp(command_args[0], command_args)

            # 父进程：处理输入输出
            tty.setraw(sys.stdin.fileno())

            while True:
                # 使用 select 监听输入和输出
                r, w, e = select.select([sys.stdin, self.master_fd], [], [], 0.1)

                # 处理用户输入
                if sys.stdin in r:
                    data = os.read(sys.stdin.fileno(), 1024)
                    if data:
                        os.write(self.master_fd, data)

                # 处理程序输出
                if self.master_fd in r:
                    try:
                        data = os.read(self.master_fd, 1024)
                        if not data:
                            break

                        # 处理输出并检测提示
                        text = data.decode('utf-8', errors='replace')
                        ai_response = self.process_output(text)

                        # 如果 AI 有响应，发送给程序
                        if ai_response:
                            time.sleep(0.2)
                            os.write(self.master_fd, ai_response.encode('utf-8'))
                            self.recent_lines = []

                    except OSError:
                        break

            # 等待子进程结束
            pid, status = os.waitpid(self.pid, 0)
            return os.WEXITSTATUS(status)

        except KeyboardInterrupt:
            print("\n⚠️ 用户中断")
            if self.pid:
                os.kill(self.pid, signal.SIGTERM)
            return 130

        finally:
            # 恢复终端设置
            termios.tcsetattr(sys.stdin, termios.TCSAFLUSH, old_tty)

def main():
    if len(sys.argv) < 2:
        print("用法: claude_code_wrapper_pty.py <claude 命令及参数>")
        sys.exit(1)

    timeout = int(os.environ.get('IZSH_AI_CONFIRM_TIMEOUT', 3))
    wrapper = ClaudeCodeWrapperPTY(timeout=timeout)
    exit_code = wrapper.run(sys.argv[1:])
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
