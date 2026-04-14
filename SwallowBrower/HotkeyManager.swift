import AppKit
import Carbon

/// 全局快捷键管理器
class HotkeyManager: NSObject {
    static let shared = HotkeyManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var onHotkey: (() -> Void)?
    
    // 默认快捷键: Command + Up Arrow (⌘↑)
    private(set) var keyCode: Int32 = 126  // Up Arrow
    private(set) var modifiers: NSEvent.ModifierFlags = [.command]
    
    private override init() {
        super.init()
        loadSavedHotkey()
    }
    
    var currentHotkeyDisplay: String {
        return HotkeyManager.hotkeyDescription(keyCode: keyCode, modifiers: modifiers)
    }
    
    func register(onHotkey: @escaping () -> Void) {
        self.onHotkey = onHotkey
        
        // 检查辅助功能权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            print("🪵 [HotkeyManager] Accessibility permission not granted")
            return
        }
        
        // 创建事件tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // 使用闭包而不是直接传selector
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            return hotkeyManager.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("🪵 [HotkeyManager] Global hotkey registered")
        } else {
            print("🪵 [HotkeyManager] Failed to create event tap")
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            // 检查修饰键 (Command + 指定键)
            let hasCommand = flags.contains(.maskCommand)
            let hasShift = flags.contains(.maskShift)
            let hasControl = flags.contains(.maskControl)
            let hasOption = flags.contains(.maskAlternate)
            
            // 检查是否匹配注册的快捷键
            if code == keyCode && hasCommand && !hasShift && !hasControl && !hasOption {
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkey?()
                }
                return nil // 消费事件
            }
        }
        return Unmanaged.passRetained(event)
    }
    
    func unregister() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    // MARK: - 快捷键配置
    
    func setHotkey(keyCode: Int32, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        saveHotkey()
        print("🪵 [HotkeyManager] Hotkey updated: keyCode=\(keyCode), modifiers=\(modifiers)")
    }
    
    private func saveHotkey() {
        UserDefaults.standard.set(keyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "hotkeyModifiers")
    }
    
    private func loadSavedHotkey() {
        let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? Int32
        let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt
        
        if let keyCode = savedKeyCode {
            self.keyCode = keyCode
        }
        if let modifiers = savedModifiers {
            self.modifiers = NSEvent.ModifierFlags(rawValue: modifiers)
        }
    }
    
    // 获取可读的快捷键描述
    static func hotkeyDescription(keyCode: Int32, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        let keyName = keyCodeToString(keyCode)
        parts.append(keyName)
        
        return parts.joined()
    }
    
    private static func keyCodeToString(_ keyCode: Int32) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "↩"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "Esc"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 107: return "F14"
        case 109: return "F10"
        case 111: return "F12"
        case 113: return "F15"
        case 118: return "F4"
        case 119: return "F2"
        case 120: return "F1"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key\(keyCode)"
        }
    }
}
