import Cocoa
import SwiftTerm

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var terminalView: LocalProcessTerminalView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用
        NSApp.setActivationPolicy(.regular)

        // 创建菜单
        createMenuBar()

        // 创建窗口
        createWindow()

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func createWindow() {
        // 创建窗口
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "iZsh - 智能终端"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // 启动 shell
        let izshPath = NSHomeDirectory() + "/.local/bin/izsh"
        let shellPath = FileManager.default.fileExists(atPath: izshPath) ? izshPath : "/bin/zsh"

        // 创建终端视图并启动进程
        terminalView = LocalProcessTerminalView(frame: window.contentView!.bounds, shell: shellPath)
        terminalView.autoresizingMask = [.width, .height]

        // 设置终端外观
        let bgColor = NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        terminalView.nativeForegroundColor = .white
        terminalView.nativeBackgroundColor = bgColor

        window.contentView = terminalView

        window.makeKeyAndOrderFront(nil)
    }

    private func createMenuBar() {
        let mainMenu = NSMenu()

        // App 菜单
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "关于 iZsh", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "隐藏 iZsh", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")

        let hideOthers = NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)

        appMenu.addItem(withTitle: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 iZsh", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // 编辑菜单
        let editMenu = NSMenu(title: "编辑")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.addItem(editMenuItem)

        // Shell 菜单
        let shellMenu = NSMenu(title: "Shell")
        let shellMenuItem = NSMenuItem()
        shellMenuItem.submenu = shellMenu

        shellMenu.addItem(withTitle: "新建窗口", action: #selector(newWindow), keyEquivalent: "n")
        shellMenu.addItem(withTitle: "新建标签页", action: #selector(newTab), keyEquivalent: "t")
        shellMenu.addItem(NSMenuItem.separator())
        shellMenu.addItem(withTitle: "清除屏幕", action: #selector(clearScreen), keyEquivalent: "k")

        mainMenu.addItem(shellMenuItem)

        // 窗口菜单
        let windowMenu = NSMenu(title: "窗口")
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "缩放", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "前置全部窗口", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        mainMenu.addItem(windowMenuItem)

        // 帮助菜单
        let helpMenu = NSMenu(title: "帮助")
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "iZsh 帮助", action: #selector(showHelp), keyEquivalent: "?")

        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "iZsh - 智能终端"
        alert.informativeText = """
        版本 1.0.0

        基于 Zsh 的 AI 驱动智能终端
        使用 SwiftTerm 终端模拟器

        © 2025 iZsh Project
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc func showPreferences() {
        let alert = NSAlert()
        alert.messageText = "偏好设置"
        alert.informativeText = "配置文件位于: ~/.izshrc"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开配置文件")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            let configPath = NSHomeDirectory() + "/.izshrc"
            NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
        }
    }

    @objc func newWindow() {
        // TODO: 实现新窗口
    }

    @objc func newTab() {
        // TODO: 实现新标签页
    }

    @objc func clearScreen() {
        terminalView.send(txt: "\u{0C}") // Ctrl+L
    }

    @objc func showHelp() {
        let helpPath = NSHomeDirectory() + "/Documents/ClaudeCode/zsh/zsh/iZsh最终版本说明.md"
        NSWorkspace.shared.open(URL(fileURLWithPath: helpPath))
    }
}
