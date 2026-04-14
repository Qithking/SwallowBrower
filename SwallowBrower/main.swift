import AppKit

// 单实例检查
let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications

// 获取当前应用的 bundle identifier
guard let bundleId = Bundle.main.bundleIdentifier else {
    print("Failed to get bundle identifier")
    exit(1)
}

// 查找其他运行中的相同应用
for app in runningApps {
    if app.bundleIdentifier == bundleId && app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
        // 已有实例运行，激活它并退出
        app.activate()
        exit(0)
    }
}

// 没有其他实例，正常启动
let app = NSApplication.shared
app.setActivationPolicy(.regular)  // 保持 Dock 图标显示

Task { @MainActor in
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
