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
    # 状态定义 - 完整版
    # 1. 启动和初始化
    STATE_STARTING = "starting"           # 🚀 启动中
    STATE_INITIALIZING = "initializing"   # 🔄 初始化

    # 2. 正常工作状态
    STATE_THINKING = "thinking"           # 🤔 思考中
    STATE_READING = "reading"             # 📖 读取文件
    STATE_WRITING = "writing"             # ✏️ 编写代码
    STATE_EXECUTING = "executing"         # ⚙️ 执行命令
    STATE_SEARCHING = "searching"         # 🔍 搜索分析
    STATE_MONITORING = "monitoring"       # 🟢 监控中

    # 3. 交互和等待状态
    STATE_WAITING_TASK = "waiting_task"   # 🔵 等待任务
    STATE_WAITING_CONFIRM = "waiting_confirm"  # 🟡 等待确认
    STATE_WAITING_CHOICE = "waiting_choice"    # 🟠 等待选择
    STATE_COUNTDOWN = "countdown"         # ⏱️ 倒计时 Ns

    # 4. AI 决策状态
    STATE_AI_ANALYZING = "ai_analyzing"   # 🧠 AI分析中
    STATE_AI_SELECTED = "ai_selected"     # ✅ AI已选择
    STATE_AI_EXECUTING = "ai_executing"   # 🎯 AI执行中

    # 5. 特殊和异常状态
    STATE_WARNING = "warning"             # ⚠️ 需要注意
    STATE_ERROR = "error"                 # ❌ 错误发生
    STATE_PAUSED = "paused"               # ⏸️ 用户暂停
    STATE_INTERRUPTED = "interrupted"     # 🛑 用户中断
    STATE_DEBUG = "debug"                 # 🔧 调试模式

    # 6. 完成和结束状态
    STATE_TASK_DONE = "task_done"         # ✨ 任务完成
    STATE_ALL_DONE = "all_done"           # 🎉 全部完成
    STATE_EXITED = "exited"               # 👋 已退出

    def __init__(self, timeout=3):
        self.timeout = timeout
        self.master_fd = None
        self.pid = None
        self.recent_lines = []
        self.max_context_lines = 10
        self.current_line = ""
        self.last_check_time = time.time()
        self.current_state = self.STATE_STARTING
        self.countdown_value = 0
        self.terminal_width = 80  # 默认终端宽度
        self.last_state_update = time.time()
        self.state_duration = 0  # 当前状态持续时间
        # 调试模式
        self.debug_mode = os.environ.get('IZSH_DEBUG_MODE', '0') == '1'
        # 状态指示器默认启用，显示在终端标题栏（不干扰屏幕内容）
        self.show_indicator = os.environ.get('IZSH_SHOW_INDICATOR', '1') == '1'

    def get_terminal_size(self):
        """获取终端大小"""
        try:
            size = struct.unpack('hh', fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, '1234'))
            return size[1], size[0]  # 宽度, 高度
        except:
            return 80, 24

    def show_status_indicator(self):
        """在终端标题栏显示状态指示器（不干扰屏幕内容）"""
        # 如果禁用状态指示器，直接返回
        if not self.show_indicator:
            return

        # 状态映射表
        state_indicators = {
            # 1. 启动和初始化
            self.STATE_STARTING: "🚀 启动中",
            self.STATE_INITIALIZING: "🔄 初始化",

            # 2. 正常工作状态
            self.STATE_THINKING: "🤔 思考中",
            self.STATE_READING: "📖 读取文件",
            self.STATE_WRITING: "✏️ 编写代码",
            self.STATE_EXECUTING: "⚙️ 执行命令",
            self.STATE_SEARCHING: "🔍 搜索分析",
            self.STATE_MONITORING: "🟢 监控中",

            # 3. 交互和等待状态
            self.STATE_WAITING_TASK: "🔵 等待任务",
            self.STATE_WAITING_CONFIRM: "🟡 等待确认",
            self.STATE_WAITING_CHOICE: "🟠 等待选择",

            # 4. AI 决策状态
            self.STATE_AI_ANALYZING: "🧠 AI分析中",
            self.STATE_AI_SELECTED: "✅ AI已选择",
            self.STATE_AI_EXECUTING: "🎯 AI执行中",

            # 5. 特殊和异常状态
            self.STATE_WARNING: "⚠️ 需要注意",
            self.STATE_ERROR: "❌ 错误发生",
            self.STATE_PAUSED: "⏸️ 用户暂停",
            self.STATE_INTERRUPTED: "🛑 用户中断",
            self.STATE_DEBUG: "🔧 调试模式",

            # 6. 完成和结束状态
            self.STATE_TASK_DONE: "✨ 任务完成",
            self.STATE_ALL_DONE: "🎉 全部完成",
            self.STATE_EXITED: "👋 已退出",
        }

        # 特殊处理倒计时状态
        if self.current_state == self.STATE_COUNTDOWN:
            indicator = f"⏱️ 倒计时 {self.countdown_value}s"
        else:
            indicator = state_indicators.get(self.current_state, "🟢 监控中")

        # 使用终端标题栏显示状态（完全不占用屏幕空间）
        # \033]0; 设置终端标题
        # \007 结束标题设置
        title = f"Claude Code - {indicator}"
        sys.stderr.write(f"\033]0;{title}\007")
        sys.stderr.flush()

    def update_state(self, new_state, countdown=0):
        """更新状态并显示"""
        self.current_state = new_state
        self.countdown_value = countdown
        self.show_status_indicator()

    def strip_ansi(self, text):
        """移除 ANSI 转义序列"""
        # 移除 ANSI 颜色和控制序列
        ansi_escape = re.compile(r'\x1b\[[0-9;]*[A-Za-z]|\x1b\][^\x07]*\x07|\x1b[=>]|[\x00-\x1f]', re.UNICODE)
        return ansi_escape.sub('', text)

    def add_to_context(self, line):
        """添加行到上下文缓冲区"""
        self.recent_lines.append(line)
        if len(self.recent_lines) > self.max_context_lines:
            self.recent_lines.pop(0)

    def get_context(self):
        """获取上下文（最近几行）"""
        return '\n'.join(self.recent_lines)

    def detect_waiting_for_input(self, text):
        """检测是否在等待用户输入新任务"""
        # Claude Code 等待输入的常见模式
        waiting_patterns = [
            r'How can I help you\?',
            r'What would you like me to do\?',
            r'What can I help you with\?',
            r'>\s*$',  # 单独的 > 提示符
            r'What\'s next\?',
            # Claude Code 2.0 的提示格式
            r'>\s+Try\s+"write',  # > Try "write a test for <filepath>"
            r'>\s+.*for shortcuts',  # Claude Code 的输入提示行
            r'Claude Code.*v\d+\.\d+',  # Claude Code 欢迎界面
        ]

        for pattern in waiting_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return True

        return False

    def detect_state_from_output(self, text):
        """从输出文本智能检测当前状态"""
        text_lower = text.lower()

        # 思考和规划
        thinking_keywords = ['analyzing', 'planning', 'considering', 'let me', 'i\'ll', 'i will',
                            '分析', '规划', '让我', '我将', '我会']
        if any(kw in text_lower for kw in thinking_keywords):
            return self.STATE_THINKING

        # 读取文件
        reading_keywords = ['reading', 'read', 'looking at', 'checking', 'reviewing',
                          '读取', '查看', '检查', '审查']
        if any(kw in text_lower for kw in reading_keywords):
            if 'file' in text_lower or 'code' in text_lower or '文件' in text:
                return self.STATE_READING

        # 编写代码
        writing_keywords = ['writing', 'creating', 'modifying', 'editing', 'updating',
                          '编写', '创建', '修改', '更新']
        if any(kw in text_lower for kw in writing_keywords):
            if any(w in text_lower for w in ['file', 'code', 'function', '文件', '代码', '函数']):
                return self.STATE_WRITING

        # 执行命令
        executing_keywords = ['running', 'executing', 'command', 'bash', 'git', 'npm',
                            '运行', '执行', '命令']
        if any(kw in text_lower for kw in executing_keywords):
            return self.STATE_EXECUTING

        # 搜索分析
        searching_keywords = ['searching', 'finding', 'looking for', 'grep', 'search',
                            '搜索', '查找', '寻找']
        if any(kw in text_lower for kw in searching_keywords):
            return self.STATE_SEARCHING

        # 错误检测（更严格，避免误报）
        # 只检测真正的错误消息格式，而非包含关键词的普通文本
        error_patterns = [
            r'(?:^|\s)error:',           # "Error:" 开头的消息
            r'(?:^|\s)fatal:',           # "Fatal:" 开头的消息
            r'failed with.*error',       # "failed with error" 格式
            r'exception.*occurred',      # "exception occurred" 格式
            r'traceback',                # Python traceback
            r'错误：',                    # 中文错误消息
            r'失败：',                    # 中文失败消息
            r'异常：',                    # 中文异常消息
        ]
        if any(re.search(pattern, text_lower) for pattern in error_patterns):
            return self.STATE_ERROR

        # 警告检测
        warning_keywords = ['warning', 'caution', 'notice', 'important',
                          '警告', '注意', '重要']
        if any(kw in text_lower for kw in warning_keywords):
            return self.STATE_WARNING

        # 任务完成
        done_keywords = ['done', 'completed', 'finished', 'success',
                       '完成', '成功']
        if any(kw in text_lower for kw in done_keywords):
            return self.STATE_TASK_DONE

        return None  # 未检测到特定状态

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

                    # 清理 ANSI 转义序列后再检测
                    clean_line = self.strip_ansi(line)

                    if self.debug_mode and clean_line.strip():
                        # 只在前几行显示清理后的文本
                        if len(self.recent_lines) <= 10:
                            print(f"[DEBUG] Clean line: {repr(clean_line[:80])}")

                    # 检测是否在等待用户输入新任务
                    if self.detect_waiting_for_input(clean_line):
                        if self.debug_mode:
                            print(f"[DEBUG] Detected waiting for input")
                        self.update_state(self.STATE_WAITING_TASK)
                        continue

                    # 智能检测状态（在等待确认、等待选择、倒计时时不检测）
                    if self.current_state not in [self.STATE_WAITING_CONFIRM,
                                                   self.STATE_WAITING_CHOICE,
                                                   self.STATE_COUNTDOWN]:
                        detected_state = self.detect_state_from_output(clean_line)
                        if detected_state:
                            if self.debug_mode:
                                print(f"[DEBUG] State changed to: {detected_state}")
                            self.update_state(detected_state)

            self.current_line = lines[-1]

        # 定期检测（避免过于频繁）
        now = time.time()
        if now - self.last_check_time > 0.5:
            self.last_check_time = now

            # 检测菜单
            context = self.get_context()
            is_menu, menu_items = self.detect_menu(context)

            if is_menu:
                self.update_state(self.STATE_WAITING_CHOICE)
                print("\n🔍 检测到交互式菜单，AI 正在分析...")

                # AI 分析状态
                self.update_state(self.STATE_AI_ANALYZING)
                time.sleep(0.5)

                # 倒计时
                for i in range(self.timeout, 0, -1):
                    self.update_state(self.STATE_COUNTDOWN, i)
                    time.sleep(1)

                # AI 执行
                self.update_state(self.STATE_AI_EXECUTING)
                choice = self.handle_menu(menu_items)

                # AI 已选择
                self.update_state(self.STATE_AI_SELECTED)
                print(f"✅ AI 选择: {choice}")
                time.sleep(1)

                # 恢复监控
                self.update_state(self.STATE_MONITORING)

                # 发送选择
                return choice + '\n'

            # 检测确认提示
            if self.current_line.strip():
                options = self.detect_confirm_prompt(self.current_line)
                if options:
                    self.update_state(self.STATE_WAITING_CONFIRM)
                    prompt = re.sub(r'\s*[\[\(].*?[\]\)].*$', '', self.current_line).strip()
                    print(f"\n⏰ 检测到确认提示，倒计时 {self.timeout} 秒...")

                    # AI 分析状态
                    self.update_state(self.STATE_AI_ANALYZING)
                    time.sleep(0.5)

                    # 倒计时
                    for i in range(self.timeout, 0, -1):
                        self.update_state(self.STATE_COUNTDOWN, i)
                        time.sleep(1)

                    # AI 执行
                    self.update_state(self.STATE_AI_EXECUTING)
                    choice = self.handle_confirm(prompt, options)

                    # AI 已选择
                    self.update_state(self.STATE_AI_SELECTED)
                    print(f"✅ AI 自动选择: {choice}")
                    time.sleep(1)

                    # 恢复监控
                    self.update_state(self.STATE_MONITORING)

                    # 发送选择
                    self.current_line = ""
                    return choice + '\n'

        return None

    def run(self, command_args):
        """运行 Claude Code 并处理交互"""
        # 清屏：清除之前的文字残留
        print("\033[2J\033[H", end="", flush=True)

        # 不再显示启动提示，让 Claude Code 的信息完整呈现

        # 检查 stdin 是否是 TTY
        is_tty = sys.stdin.isatty()
        old_tty = None

        if self.debug_mode:
            print(f"[DEBUG] stdin is TTY: {is_tty}")
            print(f"[DEBUG] Command: {' '.join(command_args)}")

        # 设置终端为 raw 模式（仅在 TTY 时）
        if is_tty:
            try:
                old_tty = termios.tcgetattr(sys.stdin)
                if self.debug_mode:
                    print(f"[DEBUG] Terminal settings saved")
            except termios.error as e:
                is_tty = False
                if self.debug_mode:
                    print(f"[DEBUG] Failed to get terminal settings: {e}")

        try:
            # 创建伪终端
            if self.debug_mode:
                print(f"[DEBUG] Creating PTY...")

            self.pid, self.master_fd = pty.fork()

            if self.pid == 0:  # 子进程
                # 在子进程中执行 Claude Code
                if self.debug_mode:
                    sys.stderr.write(f"[DEBUG] Child process starting: {command_args[0]}\n")
                    sys.stderr.flush()
                os.execvp(command_args[0], command_args)

            # 父进程：处理输入输出
            if self.debug_mode:
                print(f"[DEBUG] Parent process, child PID: {self.pid}")
                print(f"[DEBUG] Master FD: {self.master_fd}")

            # 设置 PTY 窗口大小
            try:
                width, height = self.get_terminal_size()
                winsize = struct.pack('HHHH', height, width, 0, 0)
                fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, winsize)
                if self.debug_mode:
                    print(f"[DEBUG] Set PTY window size: {width}x{height}")
            except Exception as e:
                if self.debug_mode:
                    print(f"[DEBUG] Failed to set window size: {e}")

            # 设置 master_fd 为非阻塞模式
            flags = fcntl.fcntl(self.master_fd, fcntl.F_GETFL)
            fcntl.fcntl(self.master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)
            if self.debug_mode:
                print(f"[DEBUG] Set master_fd to non-blocking mode")

            if is_tty:
                tty.setraw(sys.stdin.fileno())
                if self.debug_mode:
                    print(f"[DEBUG] Set stdin to raw mode")

            # 显示初始状态（初始化中）
            self.update_state(self.STATE_INITIALIZING)
            time.sleep(0.5)

            # 切换到监控状态
            self.update_state(self.STATE_MONITORING)

            if self.debug_mode:
                print(f"[DEBUG] Entering main loop...")

            loop_count = 0
            while True:
                # 使用 select 监听输入和输出
                # 只在 TTY 时监听 stdin
                watch_fds = [self.master_fd]
                if is_tty:
                    watch_fds.append(sys.stdin)

                if self.debug_mode and loop_count < 5:
                    print(f"[DEBUG] Loop {loop_count}: Waiting for I/O (watching {len(watch_fds)} fds)...")
                    loop_count += 1

                r, w, e = select.select(watch_fds, [], [], 0.1)

                if self.debug_mode and r:
                    print(f"[DEBUG] Ready fds: {len(r)}")

                # 处理用户输入（仅在 TTY 时）
                if is_tty and sys.stdin in r:
                    data = os.read(sys.stdin.fileno(), 1024)
                    if data:
                        if self.debug_mode:
                            print(f"[DEBUG] User input: {len(data)} bytes")
                        # 用户开始输入，更新状态
                        if self.current_state == self.STATE_WAITING_TASK:
                            self.update_state(self.STATE_THINKING)
                        os.write(self.master_fd, data)

                # 处理程序输出
                if self.master_fd in r:
                    try:
                        data = os.read(self.master_fd, 1024)
                        if not data:
                            if self.debug_mode:
                                print(f"[DEBUG] No data from master_fd, child process may have exited")
                            break

                        if self.debug_mode:
                            print(f"[DEBUG] Received {len(data)} bytes from child")

                        # 服务器开始返回数据，更新状态
                        if self.current_state == self.STATE_WAITING_TASK:
                            # 有数据返回说明服务器正在思考/生成回复
                            self.update_state(self.STATE_THINKING)

                        # 处理输出并检测提示
                        text = data.decode('utf-8', errors='replace')
                        ai_response = self.process_output(text)

                        # 如果 AI 有响应，发送给程序
                        if ai_response:
                            if self.debug_mode:
                                print(f"[DEBUG] Sending AI response: {repr(ai_response)}")
                            time.sleep(0.2)
                            os.write(self.master_fd, ai_response.encode('utf-8'))
                            self.recent_lines = []

                    except OSError as e:
                        if self.debug_mode:
                            print(f"[DEBUG] OSError in read loop: {e}")
                        break

            # 等待子进程结束
            self.update_state(self.STATE_EXITED)
            pid, status = os.waitpid(self.pid, 0)
            return os.WEXITSTATUS(status)

        except KeyboardInterrupt:
            self.update_state(self.STATE_INTERRUPTED)
            print("\n⚠️ 用户中断")
            if self.pid:
                os.kill(self.pid, signal.SIGTERM)
            return 130

        finally:
            # 恢复终端设置（仅在之前保存了设置时）
            if old_tty is not None:
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
