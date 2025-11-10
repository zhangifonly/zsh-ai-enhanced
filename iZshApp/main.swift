#!/usr/bin/env swift

import Cocoa
import Foundation

// MARK: - 终端视图
class TerminalView: NSTextView {
    private var masterFd: Int32 = -1
    private var slaveFd: Int32 = -1
    private var childPid: pid_t = -1
    private var readSource: DispatchSourceRead?

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupView()
        startShell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        startShell()
    }

    private func setupView() {
        // 设置外观
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        self.textColor = NSColor.white
        self.insertionPointColor = NSColor.green
        self.font = NSFont(name: "Monaco", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        self.isEditable = true
        self.isSelectable = true
        self.isRichText = false
        self.allowsUndo = true
    }

    private func startShell() {
        // 创建伪终端
        var master: Int32 = -1
        var slave: Int32 = -1

        var term = winsize()
        term.ws_row = 24
        term.ws_col = 80

        guard openpty(&master, &slave, nil, nil, &term) == 0 else {
            appendOutput("❌ 无法创建伪终端\n")
            return
        }

        self.masterFd = master
        self.slaveFd = slave

        // Fork 子进程
        let pid = fork()

        if pid < 0 {
            appendOutput("❌ 无法创建子进程\n")
            return
        }

        if pid == 0 {
            // 子进程
            close(master)

            // 设置为会话领导者
            setsid()

            // 将 slave 设为控制终端
            if ioctl(slave, TIOCSCTTY, nil) < 0 {
                exit(1)
            }

            // 重定向标准输入输出
            dup2(slave, STDIN_FILENO)
            dup2(slave, STDOUT_FILENO)
            dup2(slave, STDERR_FILENO)

            close(slave)

            // 设置环境变量
            setenv("TERM", "xterm-256color", 1)
            setenv("DYLD_LIBRARY_PATH", "/Users/zhangzhen/anaconda3/lib", 1)
            setenv("OBJC_DISABLE_INITIALIZE_FORK_SAFETY", "YES", 1)
            setenv("HOME", NSHomeDirectory(), 1)

            // 启动 iZsh
            let izshPath = NSHomeDirectory() + "/.local/bin/izsh"
            execl(izshPath, "izsh", "-i", nil)

            // 如果 execl 失败，尝试使用 zsh
            execl("/bin/zsh", "zsh", "-i", nil)
            exit(1)
        }

        // 父进程
        close(slave)
        self.childPid = pid

        // 设置非阻塞
        fcntl(master, F_SETFL, O_NONBLOCK)

        // 开始读取输出
        startReading()
    }

    private func startReading() {
        let queue = DispatchQueue(label: "com.izsh.terminal.read")
        readSource = DispatchSource.makeReadSource(fileDescriptor: masterFd, queue: queue)

        readSource?.setEventHandler { [weak self] in
            guard let self = self else { return }

            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(self.masterFd, &buffer, buffer.count)

            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                if let string = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.appendOutput(string)
                    }
                }
            }
        }

        readSource?.resume()
    }

    private func appendOutput(_ text: String) {
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: NSColor.white,
                .font: self.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            ]
        )

        self.textStorage?.append(attributedString)
        self.scrollToEndOfDocument(nil)
    }

    override func keyDown(with event: NSEvent) {
        guard masterFd >= 0 else {
            super.keyDown(with: event)
            return
        }

        if let characters = event.characters {
            var data = characters.data(using: .utf8) ?? Data()

            // 处理特殊键
            if event.keyCode == 36 { // Return
                data = "\n".data(using: .utf8)!
            } else if event.keyCode == 51 { // Delete
                data = "\u{7f}".data(using: .utf8)!
            } else if event.keyCode == 48 { // Tab
                data = "\t".data(using: .utf8)!
            } else if event.modifierFlags.contains(.control) {
                // Ctrl+C, Ctrl+D 等
                if let char = characters.first, char.isASCII {
                    let ctrlChar = Character(UnicodeScalar(char.asciiValue! & 0x1F))
                    data = String(ctrlChar).data(using: .utf8)!
                }
            }

            data.withUnsafeBytes { ptr in
                write(masterFd, ptr.baseAddress, data.count)
            }
        }
    }

    deinit {
        readSource?.cancel()
        if masterFd >= 0 {
            close(masterFd)
        }
        if childPid > 0 {
            kill(childPid, SIGTERM)
        }
    }
}

// MARK: - 窗口控制器
class TerminalWindowController: NSWindowController, NSWindowDelegate {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "iZsh - 智能终端"
        window.titlebarAppearsTransparent = false

        // 创建终端视图
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let terminalView = TerminalView(frame: scrollView.bounds, textContainer: textContainer)
        terminalView.autoresizingMask = [.width, .height]

        scrollView.documentView = terminalView
        window.contentView = scrollView

        self.init(window: window)
        window.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: TerminalWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建菜单栏
        setupMenuBar()

        // 创建窗口
        windowController = TerminalWindowController()
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // iZsh 菜单
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "关于 iZsh", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "隐藏 iZsh", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")

        let hideOthersItem = NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        appMenu.addItem(withTitle: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 iZsh", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // 编辑菜单
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: "编辑")
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        // 窗口菜单
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)

        let windowMenu = NSMenu(title: "窗口")
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "缩放", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "前置全部窗口", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        // 帮助菜单
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)

        let helpMenu = NSMenu(title: "帮助")
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "iZsh 帮助", action: #selector(showHelp), keyEquivalent: "?")

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
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

    @objc private func showPreferences() {
        let alert = NSAlert()
        alert.messageText = "偏好设置"
        alert.informativeText = "配置文件位于: ~/.izshrc"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc private func showHelp() {
        if let url = URL(string: "https://github.com/izsh/izsh") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 主入口
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
