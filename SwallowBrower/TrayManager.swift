import AppKit
import SwiftUI

class TrayManager: NSObject {
    private var statusItem: NSStatusItem?
    private var pinMenuItem: NSMenuItem?
    private var menu: NSMenu?
    private let onShowWindow: () -> Void
    private let onTogglePin: () -> Void
    private let onQuit: () -> Void

    init(onShowWindow: @escaping () -> Void, onTogglePin: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onShowWindow = onShowWindow
        self.onTogglePin = onTogglePin
        self.onQuit = onQuit
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let iconImage = NSImage(named: NSImage.Name("AppIcon")) {
                let smallIcon = NSImage(size: NSSize(width: 18, height: 18))
                smallIcon.lockFocus()
                iconImage.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18),
                              from: NSRect(x: 0, y: 0, width: iconImage.size.width, height: iconImage.size.height),
                              operation: .copy,
                              fraction: 1.0)
                smallIcon.unlockFocus()
                button.image = smallIcon
            } else {
                button.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "BluePage")
            }
            
            // 设置点击事件
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }

        let menu = NSMenu()

        let showWindowItem = NSMenuItem(title: "显示窗口", action: #selector(showWindow), keyEquivalent: "w")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        pinMenuItem = NSMenuItem(title: "置顶", action: #selector(togglePin), keyEquivalent: "p")
        pinMenuItem?.target = self
        menu.addItem(pinMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.menu = menu
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // 右键显示菜单
            if let menu = menu {
                statusItem?.menu = menu
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
            }
        } else {
            // 左键显示窗口
            statusItem?.menu = nil
            onShowWindow()
        }
    }

    func updatePinState(isPinned: Bool) {
        pinMenuItem?.title = isPinned ? "取消置顶" : "置顶"
    }

    @objc private func showWindow() {
        onShowWindow()
    }

    @objc private func togglePin() {
        onTogglePin()
    }

    @objc private func quitApp() {
        onQuit()
    }
}