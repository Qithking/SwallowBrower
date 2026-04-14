import AppKit
import SwiftUI
import SwiftData

// MARK: - 快捷键测试响应者
class KeyboardTestResponder: NSView {
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        print("🪵 [KeyboardTestResponder] keyDown: \(event.keyCode) - \(event.characters ?? "nil") modifiers: \(event.modifierFlags.rawValue)")
        super.keyDown(with: event)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        print("🪵 [KeyboardTestResponder] performKeyEquivalent: \(event.keyCode) modifiers: \(event.modifierFlags.rawValue)")
        return super.performKeyEquivalent(with: event)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private nonisolated(unsafe) var window: NSWindow?
    private var trayManager: TrayManager?
    private var sharedModelContainer: ModelContainer?
    private var shouldRestoreWindow = false
    private var keyMonitor: Any?
    private let testResponder = KeyboardTestResponder()
    
    private func setupModelContainer() {
        do {
            let schema = Schema([Bookmark.self])
            // 尝试使用应用支持目录存储
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("com.thking.SwallowBrower")
            
            var config: ModelConfiguration
            if let storeURL = storeURL {
                // 确保目录存在
                try? FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)
                config = ModelConfiguration("FetchGithub", schema: schema, url: storeURL.appendingPathComponent("Store.sqlite"))
            } else {
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            }
            
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
            print("SwiftData ModelContainer initialized successfully")
        } catch {
            print("Failed to create ModelContainer: \(error)")
            // 尝试使用内存存储作为备选
            let config = ModelConfiguration(schema: Schema([Bookmark.self]), isStoredInMemoryOnly: true)
            sharedModelContainer = try? ModelContainer(for: Schema([Bookmark.self]), configurations: [config])
        }
    }

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.setupModelContainer()
            self?.setupTheme()
            self?.setupMenu()
            self?.setupWindow()
            self?.setupTray()
            self?.setupKeyboardMonitor()
            self?.setupGlobalHotkey()
        }
    }
    
    @MainActor
    private func setupTheme() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        applyTheme(savedTheme)
    }
    
    @MainActor
    private func applyTheme(_ theme: String) {
        switch theme {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
    
    @MainActor
    private func setupMenu() {
        let mainMenu = NSMenu()
        
        // App 菜单
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 SwallowBrower", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "隐藏 SwallowBrower", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        appMenu.items.last?.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 SwallowBrower", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Edit 菜单 - 关键！让 Cmd+C/V 正常工作
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "删除", action: #selector(NSText.delete(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // Window 菜单
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "缩放", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "关闭", action: #selector(NSWindow.close), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
        
        print("🪵 [AppDelegate] Menu setup complete")
    }
    
    @objc private func showPreferences() {
        guard let window = window else { return }
        
        // 显示主窗口
        window.makeKeyAndOrderFront(nil)
        if NSApp.isHidden {
            NSApp.unhide(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        
        // 触发 ContentView 显示设置页面
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let showWindow = Notification.Name("showWindow")
    static let hotkeyRecorded = Notification.Name("hotkeyRecorded")
}

extension AppDelegate {
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return UserDefaults.standard.bool(forKey: "quitOnClose")
    }

    @MainActor
    private func setupWindow() {
        // 创建并配置窗口
        let savedWidth = UserDefaults.standard.double(forKey: "windowWidth")
        let savedHeight = UserDefaults.standard.double(forKey: "windowHeight")
        let width = savedWidth > 0 ? savedWidth : 800
        let height = savedHeight > 0 ? savedHeight : 600
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.styleMask.insert(.fullSizeContentView)
        window?.isMovableByWindowBackground = true
        window?.delegate = self
        
        // 根据是否有 ModelContainer 创建对应的视图
        if let container = sharedModelContainer {
            window?.contentView = NSHostingView(rootView: ContentView().modelContainer(container))
        } else {
            window?.contentView = NSHostingView(rootView: ContentView())
        }
        
        // 恢复窗口位置（如果之前有保存）
        if let savedX = UserDefaults.standard.object(forKey: "windowX") as? Double,
           let savedY = UserDefaults.standard.object(forKey: "windowY") as? Double {
            window?.setFrameOrigin(NSPoint(x: savedX, y: savedY))
        } else {
            window?.center()
        }
        
        window?.makeKeyAndOrderFront(nil)
        
        // 设置 initialFirstResponder 到 contentView
        // 这是确保响应者链正确工作的关键
        window?.initialFirstResponder = window?.contentView
        window?.makeFirstResponder(window?.contentView)
        
        // 打印当前第一响应者
        print("🔍 [AppDelegate] Window firstResponder: \(window?.firstResponder?.className ?? "nil")")
        print("🔍 [AppDelegate] initialFirstResponder: \(window?.initialFirstResponder?.className ?? "nil")")
    }

    @MainActor
    private func setupKeyboardMonitor() {
        // 全局键盘事件监听器
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return event
        }
    }
    
    @MainActor
    private func setupGlobalHotkey() {
        // 设置默认值
        if UserDefaults.standard.object(forKey: "hotkeyEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hotkeyEnabled")
        }
        
        // 检查快捷键是否启用
        let hotkeyEnabled = UserDefaults.standard.bool(forKey: "hotkeyEnabled")
        guard hotkeyEnabled else {
            print("🪵 [AppDelegate] Global hotkey disabled")
            return
        }
        
        HotkeyManager.shared.register { [weak self] in
            self?.showMainWindow()
        }
    }

    @MainActor
    private func setupTray() {
        if trayManager == nil {
            trayManager = TrayManager(
                onShowWindow: { [weak self] in
                    DispatchQueue.main.async {
                        self?.showMainWindow()
                    }
                },
                onTogglePin: { [weak self] in
                    DispatchQueue.main.async {
                        self?.toggleWindowPin()
                    }
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )
            trayManager?.setup()
        }
    }

    @MainActor
    private func toggleWindowPin() {
        guard let window = window else { return }
        
        if window.level == .floating {
            window.level = .normal
            trayManager?.updatePinState(isPinned: false)
        } else {
            window.level = .floating
            trayManager?.updatePinState(isPinned: true)
        }
    }

    @MainActor
    private func showMainWindow() {
        guard let window = window else { return }
        // 1. 如果应用被隐藏，先恢复显示
        if NSApp.isHidden {
            NSApp.unhide(nil)
        }
        // 2. 激活应用（忽略其他应用）
        NSApp.activate(ignoringOtherApps: true)
        // 3. 如果窗口被最小化，恢复
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        // 4. 将窗口移到最前面
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // 清理键盘监听器
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        // 清理全局快捷键
        HotkeyManager.shared.unregister()
    }
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == self.window else { return }
        
        // 保存窗口大小和位置（在主线程执行）
        DispatchQueue.main.async { [window] in
            let frame = window.frame
            UserDefaults.standard.set(frame.width, forKey: "windowWidth")
            UserDefaults.standard.set(frame.height, forKey: "windowHeight")
            UserDefaults.standard.set(frame.origin.x, forKey: "windowX")
            UserDefaults.standard.set(frame.origin.y, forKey: "windowY")
        }
        
        let quitOnClose = UserDefaults.standard.bool(forKey: "quitOnClose")
        if !quitOnClose {
            // 不退出应用，隐藏整个应用
            DispatchQueue.main.async {
                NSApp.hide(nil)
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let quitOnClose = UserDefaults.standard.bool(forKey: "quitOnClose")
        if quitOnClose {
            return true // 允许关闭，应用会退出
        } else {
            // 不退出，只隐藏应用
            // 阻止窗口关闭，但隐藏整个应用
            DispatchQueue.main.async {
                NSApp.hide(nil)
            }
            return false
        }
    }
}
