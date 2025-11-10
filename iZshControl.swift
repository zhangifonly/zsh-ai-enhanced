#!/usr/bin/env swift

import Cocoa
import Foundation

// MARK: - 控制面板窗口
class ControlPanel: NSPanel {
    private var clearButton: NSButton!
    private var newWindowButton: NSButton!
    private var settingsButton: NSButton!
    private var helpButton: NSButton!

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel, .hudWindow], backing: backingStoreType, defer: flag)

        setupPanel()
    }

    private func setupPanel() {
        self.title = "iZsh 控制面板"
        self.level = .floating
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false

        // 设置半透明背景
        self.isOpaque = false
        self.backgroundColor = NSColor(white: 0.1, alpha: 0.95)

        // 创建内容视图
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 80))

        // 创建按钮
        let buttonWidth: CGFloat = 90
        let buttonHeight: CGFloat = 32
        let spacing: CGFloat = 10
        let startX: CGFloat = 10
        let y: CGFloat = 40

        // 新窗口按钮
        newWindowButton = createButton(
            frame: NSRect(x: startX, y: y, width: buttonWidth, height: buttonHeight),
            title: "新窗口 ⌘N",
            action: #selector(newWindow)
        )
        contentView.addSubview(newWindowButton)

        // 清屏按钮
        clearButton = createButton(
            frame: NSRect(x: startX + buttonWidth + spacing, y: y, width: buttonWidth, height: buttonHeight),
            title: "清屏 ⌘K",
            action: #selector(clearScreen)
        )
        contentView.addSubview(clearButton)

        // 设置按钮
        settingsButton = createButton(
            frame: NSRect(x: startX + (buttonWidth + spacing) * 2, y: y, width: buttonWidth, height: buttonHeight),
            title: "设置 ⌘,",
            action: #selector(openSettings)
        )
        contentView.addSubview(settingsButton)

        // 帮助按钮
        helpButton = createButton(
            frame: NSRect(x: startX + (buttonWidth + spacing) * 3, y: y, width: buttonWidth, height: buttonHeight),
            title: "帮助 ⌘?",
            action: #selector(showHelp)
        )
        contentView.addSubview(helpButton)

        // 添加标题标签
        let titleLabel = NSTextField(labelWithString: "iZsh - 智能终端控制面板")
        titleLabel.frame = NSRect(x: 10, y: 10, width: 380, height: 20)
        titleLabel.textColor = NSColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        contentView.addSubview(titleLabel)

        self.contentView = contentView
    }

    private func createButton(frame: NSRect, title: String, action: Selector) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.bezelStyle = .rounded
        button.target = self
        button.action = action

        // 设置按钮样式
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.8).cgColor
        button.layer?.cornerRadius = 6

        if let cell = button.cell as? NSButtonCell {
            cell.font = NSFont.systemFont(ofSize: 11)
        }

        return button
    }

    @objc private func newWindow() {
        let script = """
        tell application "Terminal"
            activate
            set newWindow to do script "export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib; export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES; exec ~/.local/bin/izsh"
            set custom title of newWindow to "iZsh - 智能终端"
        end tell
        """

        runAppleScript(script)
    }

    @objc private func clearScreen() {
        // 发送 Ctrl+L 到当前终端
        let script = """
        tell application "Terminal"
            do script "clear" in front window
        end tell
        """

        runAppleScript(script)
    }

    @objc private func openSettings() {
        let configPath = NSHomeDirectory() + "/.izshrc"
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc private func showHelp() {
        let helpPath = NSHomeDirectory() + "/Documents/ClaudeCode/zsh/zsh/iZsh最终版本说明.md"
        if FileManager.default.fileExists(atPath: helpPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: helpPath))
        } else {
            let alert = NSAlert()
            alert.messageText = "iZsh 帮助"
            alert.informativeText = """
            快捷键：
            • ⌘N - 新建窗口
            • ⌘K - 清屏
            • ⌘, - 打开设置
            • ⌘? - 显示帮助

            AI 功能：
            • 输入自然语言会自动翻译为命令
            • 例如："列目录" → ls

            配置文件：~/.izshrc
            """
            alert.runModal()
        }
    }

    private func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}

// MARK: - 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    var controlPanel: ControlPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建控制面板
        controlPanel = ControlPanel(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 80),
            styleMask: [],
            backing: .buffered,
            defer: false
        )

        // 显示控制面板
        controlPanel.center()
        controlPanel.orderFrontRegardless()

        // 设置应用不在 Dock 中显示
        NSApp.setActivationPolicy(.accessory)

        // 创建状态栏图标
        createStatusBarIcon()
    }

    private func createStatusBarIcon() {
        let statusBar = NSStatusBar.system
        let statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.title = "⚡"
            button.toolTip = "iZsh 控制面板"
        }

        // 创建菜单
        let menu = NSMenu()

        menu.addItem(withTitle: "显示控制面板", action: #selector(showPanel), keyEquivalent: "")
        menu.addItem(withTitle: "新建 iZsh 窗口", action: #selector(newWindow), keyEquivalent: "n")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "偏好设置...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "关于 iZsh", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(withTitle: "退出控制面板", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc func showPanel() {
        controlPanel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func newWindow() {
        let script = """
        tell application "Terminal"
            activate
            set newWindow to do script "export DYLD_LIBRARY_PATH=/Users/zhangzhen/anaconda3/lib; export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES; exec ~/.local/bin/izsh"
            set custom title of newWindow to "iZsh - 智能终端"
        end tell
        """

        runAppleScript(script)
    }

    @objc func openSettings() {
        let configPath = NSHomeDirectory() + "/.izshrc"
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "iZsh - 智能终端"
        alert.informativeText = """
        版本 1.0.0

        基于 Zsh 的 AI 驱动智能终端

        © 2025 iZsh Project
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    private func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}

// MARK: - 主入口
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
