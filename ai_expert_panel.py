#!/usr/bin/env python3
"""
AI 命令专家管理面板

功能：
- 查看所有已配置的专家
- 编辑专家提示词
- 启用/禁用专家
- 测试专家提示词
- 创建自定义专家
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# AI 专家配置目录
EXPERTS_DIR = Path.home() / ".izsh" / "ai_experts"
CONFIG_FILE = EXPERTS_DIR / "experts.json"
TEMPLATES_DIR = EXPERTS_DIR / "templates"
CUSTOM_DIR = EXPERTS_DIR / "custom"

# 颜色定义
COLORS = {
    'reset': '\033[0m',
    'bold': '\033[1m',
    'green': '\033[32m',
    'yellow': '\033[33m',
    'blue': '\033[34m',
    'cyan': '\033[36m',
    'red': '\033[31m',
}

def color_print(text, color='reset', bold=False):
    """彩色打印"""
    prefix = COLORS.get('bold', '') if bold else ''
    color_code = COLORS.get(color, COLORS['reset'])
    print(f"{prefix}{color_code}{text}{COLORS['reset']}")

def load_config():
    """加载配置文件"""
    if not CONFIG_FILE.exists():
        color_print("❌ 配置文件不存在，正在初始化...", 'red')
        init_experts_dir()

    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_config(config):
    """保存配置文件"""
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    color_print("✅ 配置已保存", 'green')

def init_experts_dir():
    """初始化专家目录"""
    EXPERTS_DIR.mkdir(parents=True, exist_ok=True)
    TEMPLATES_DIR.mkdir(exist_ok=True)
    CUSTOM_DIR.mkdir(exist_ok=True)

    # 创建默认配置
    default_config = {
        "version": "1.0.0",
        "experts": {},
        "settings": {
            "auto_detect": True,
            "show_welcome": True,
            "expert_timeout": 3600
        }
    }

    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump(default_config, f, indent=2)

    color_print(f"✅ 已初始化专家目录: {EXPERTS_DIR}", 'green')

def list_experts():
    """列出所有专家"""
    config = load_config()
    experts = config.get('experts', {})

    if not experts:
        color_print("📋 暂无配置的专家", 'yellow')
        return

    color_print("\n" + "="*60, 'cyan', True)
    color_print("  AI 命令专家列表", 'cyan', True)
    color_print("="*60, 'cyan', True)

    for i, (key, expert) in enumerate(experts.items(), 1):
        enabled = "✅" if expert.get('enabled', True) else "❌"
        status = f"{enabled} {'启用' if expert.get('enabled') else '禁用'}"

        color_print(f"\n{i}. {expert['name']}", 'yellow', True)
        print(f"   ID: {key}")
        print(f"   描述: {expert.get('description', 'N/A')}")
        print(f"   状态: {status}")
        print(f"   模板: {expert.get('template', 'N/A')}")
        print(f"   命令: {', '.join(expert.get('commands', []))}")
        print(f"   优先级: {expert.get('priority', 10)}")

    color_print("\n" + "="*60, 'cyan', True)

def view_expert_prompt(expert_id):
    """查看专家提示词"""
    config = load_config()
    experts = config.get('experts', {})

    if expert_id not in experts:
        color_print(f"❌ 未找到专家: {expert_id}", 'red')
        return

    expert = experts[expert_id]
    template_path = EXPERTS_DIR / expert['template']

    if not template_path.exists():
        color_print(f"❌ 模板文件不存在: {template_path}", 'red')
        return

    color_print(f"\n{'='*60}", 'cyan', True)
    color_print(f"  {expert['name']} - 提示词", 'cyan', True)
    color_print(f"{'='*60}", 'cyan', True)
    color_print(f"文件: {template_path}\n", 'blue')

    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 显示内容（限制前 50 行）
    lines = content.split('\n')
    for i, line in enumerate(lines[:50], 1):
        print(f"{i:4d} | {line}")

    if len(lines) > 50:
        color_print(f"\n... (共 {len(lines)} 行，仅显示前 50 行)", 'yellow')

    color_print(f"\n{'='*60}", 'cyan', True)

def edit_expert_prompt(expert_id):
    """编辑专家提示词"""
    config = load_config()
    experts = config.get('experts', {})

    if expert_id not in experts:
        color_print(f"❌ 未找到专家: {expert_id}", 'red')
        return

    expert = experts[expert_id]
    template_path = EXPERTS_DIR / expert['template']

    if not template_path.exists():
        color_print(f"❌ 模板文件不存在: {template_path}", 'red')
        return

    # 获取编辑器
    editor = os.environ.get('EDITOR', 'vim')

    color_print(f"\n正在使用 {editor} 编辑...", 'blue')
    color_print(f"文件: {template_path}", 'blue')

    # 打开编辑器
    subprocess.run([editor, str(template_path)])

    color_print("\n✅ 编辑完成", 'green')

def toggle_expert(expert_id):
    """启用/禁用专家"""
    config = load_config()
    experts = config.get('experts', {})

    if expert_id not in experts:
        color_print(f"❌ 未找到专家: {expert_id}", 'red')
        return

    current_status = experts[expert_id].get('enabled', True)
    experts[expert_id]['enabled'] = not current_status

    save_config(config)

    new_status = "启用" if not current_status else "禁用"
    color_print(f"✅ 已{new_status}专家: {experts[expert_id]['name']}", 'green')

def create_custom_expert():
    """创建自定义专家"""
    color_print("\n" + "="*60, 'cyan', True)
    color_print("  创建自定义专家", 'cyan', True)
    color_print("="*60, 'cyan', True)

    # 获取专家信息
    expert_id = input("\n专家 ID (英文，如 mysql): ").strip()
    if not expert_id:
        color_print("❌ ID 不能为空", 'red')
        return

    name = input("专家名称 (如 MySQL 数据库专家): ").strip()
    if not name:
        color_print("❌ 名称不能为空", 'red')
        return

    description = input("简短描述: ").strip()
    commands = input("触发命令 (逗号分隔，如 mysql,mycli): ").strip().split(',')
    commands = [cmd.strip() for cmd in commands if cmd.strip()]

    # 创建模板文件
    template_filename = f"{expert_id}.prompt"
    template_path = CUSTOM_DIR / template_filename

    # 模板内容
    template_content = f"""# {name}

## 专家身份

你是一位资深的 {name}。

## 核心专长

[在此描述你的专长领域]

## 工作原则

### 1. 原则一

[描述第一个工作原则]

### 2. 原则二

[描述第二个工作原则]

## 常见任务场景

### 场景 1：基础操作

[提供具体的命令示例和说明]

### 场景 2：高级用法

[提供高级用法示例]

## 交互方式

### 响应模板：

```
✅ 理解：[用户任务]

🔧 推荐方案：
[具体步骤]

💡 原理说明：
[解释为什么]

⚠️ 注意事项：
[潜在问题]
```

## 示例对话

**用户**：[示例问题]

**你**：
✅ 理解：[理解用户意图]

[提供具体解决方案]

---

现在，请告诉我您的需求，我会提供专业的帮助！
"""

    # 写入模板
    with open(template_path, 'w', encoding='utf-8') as f:
        f.write(template_content)

    # 更新配置
    config = load_config()
    config['experts'][expert_id] = {
        "name": name,
        "description": description,
        "template": f"custom/{template_filename}",
        "enabled": True,
        "auto_load": True,
        "priority": 10,
        "commands": commands,
        "patterns": [f"^{cmd}\\s+" for cmd in commands]
    }

    save_config(config)

    color_print(f"\n✅ 已创建专家: {name}", 'green')
    color_print(f"📝 模板文件: {template_path}", 'blue')
    color_print("\n💡 下一步：", 'yellow')
    print(f"   1. 编辑提示词: ai-expert edit {expert_id}")
    print(f"   2. 查看提示词: ai-expert view {expert_id}")
    print(f"   3. 测试专家: {commands[0]} (会自动加载该专家)")

def show_help():
    """显示帮助信息"""
    help_text = """
AI 命令专家管理面板

用法:
    ai-expert [命令] [参数]

命令:
    list                列出所有专家
    view <id>          查看专家提示词
    edit <id>          编辑专家提示词
    toggle <id>        启用/禁用专家
    create             创建自定义专家
    help               显示此帮助

示例:
    ai-expert list              # 列出所有专家
    ai-expert view git          # 查看 Git 专家提示词
    ai-expert edit docker       # 编辑 Docker 专家
    ai-expert toggle python     # 启用/禁用 Python 专家
    ai-expert create            # 创建自定义专家

快捷键:
    Ctrl+E              打开专家面板（在 iZsh 中）

提示:
    - 专家提示词位于: ~/.izsh/ai_experts/templates/
    - 自定义专家位于: ~/.izsh/ai_experts/custom/
    - 配置文件位于: ~/.izsh/ai_experts/experts.json
"""
    color_print(help_text, 'cyan')

def main():
    """主函数"""
    if len(sys.argv) < 2:
        list_experts()
        print("\n💡 使用 'ai-expert help' 查看帮助")
        return

    command = sys.argv[1]

    if command == 'list':
        list_experts()
    elif command == 'view':
        if len(sys.argv) < 3:
            color_print("❌ 请指定专家 ID", 'red')
            print("用法: ai-expert view <id>")
            return
        view_expert_prompt(sys.argv[2])
    elif command == 'edit':
        if len(sys.argv) < 3:
            color_print("❌ 请指定专家 ID", 'red')
            print("用法: ai-expert edit <id>")
            return
        edit_expert_prompt(sys.argv[2])
    elif command == 'toggle':
        if len(sys.argv) < 3:
            color_print("❌ 请指定专家 ID", 'red')
            print("用法: ai-expert toggle <id>")
            return
        toggle_expert(sys.argv[2])
    elif command == 'create':
        create_custom_expert()
    elif command == 'help' or command == '-h' or command == '--help':
        show_help()
    else:
        color_print(f"❌ 未知命令: {command}", 'red')
        print("使用 'ai-expert help' 查看帮助")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        color_print("\n\n👋 已退出", 'yellow')
        sys.exit(0)
    except Exception as e:
        color_print(f"\n❌ 错误: {e}", 'red')
        sys.exit(1)
