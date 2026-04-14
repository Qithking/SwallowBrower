//
//  SettingsView.swift
//  bluePage
//
//  Created by thking on 2026/4/11.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("quitOnClose") private var quitOnClose = true
    @AppStorage("customUserAgent") private var customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("sidebarOpacity") private var sidebarOpacity: Double = 1.0
    @AppStorage("hotkeyEnabled") private var hotkeyEnabled = true
    
    @State private var isRecordingHotkey = false
    @State private var hotkeyDisplay = ""
    @State private var recordingMonitor: Any?
    
    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $appTheme) {
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                    Text("系统").tag("system")
                }
                .pickerStyle(.segmented)
                .onChange(of: appTheme) { _, newValue in
                    applyTheme(newValue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("侧边栏透明度")
                        Spacer()
                        Text("\(Int(sidebarOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $sidebarOpacity, in: 0.3...1.0, step: 0.1)
                }
            }
            
            Section("快捷键") {
                Toggle("启用快捷键", isOn: $hotkeyEnabled)
                    .toggleStyle(.switch)
                
                HStack {
                    Text("显示窗口")
                    Spacer()
                    
                    if isRecordingHotkey {
                        Text("按下快捷键...")
                            .foregroundColor(.secondary)
                    } else {
                        Text(hotkeyDisplay)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Button(isRecordingHotkey ? "完成" : "设置") {
                        toggleRecording()
                    }
                }
                
                Text("使用此快捷键可在任何应用中快速显示窗口（需要开启辅助功能权限）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("通用") {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
                
                Toggle("关闭退出应用", isOn: $quitOnClose)
                    .toggleStyle(.switch)
            }
            
            Section("浏览器") {
                TextField("User-Agent", text: $customUserAgent)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .onAppear {
            applyTheme(appTheme)
            updateHotkeyDisplay()
        }
        .onDisappear {
            stopRecording()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hotkeyRecorded)) { _ in
            updateHotkeyDisplay()
            isRecordingHotkey = false
            stopRecording()
        }
        .onChange(of: hotkeyEnabled) { _, enabled in
            if enabled {
                HotkeyManager.shared.register {
                    NotificationCenter.default.post(name: .showWindow, object: nil)
                }
            } else {
                HotkeyManager.shared.unregister()
            }
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
    
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
    
    private func updateHotkeyDisplay() {
        hotkeyDisplay = HotkeyManager.shared.currentHotkeyDisplay
    }
    
    private func toggleRecording() {
        if isRecordingHotkey {
            // 停止录制
            isRecordingHotkey = false
            stopRecording()
        } else {
            // 开始录制
            isRecordingHotkey = true
            startRecording()
        }
    }
    
    private func startRecording() {
        print("🪵 [SettingsView] startRecording called")
        stopRecording()
        
        // 使用 NSEvent 全局监听
        recordingMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // 忽略单独按下的修饰键
            if event.keyCode >= 54 && event.keyCode <= 57 {
                return
            }
            
            let hasCommand = event.modifierFlags.contains(.command)
            let hasControl = event.modifierFlags.contains(.control)
            let hasOption = event.modifierFlags.contains(.option)
            
            // 必须有修饰键
            if hasCommand || hasControl || hasOption {
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                HotkeyManager.shared.setHotkey(keyCode: Int32(event.keyCode), modifiers: modifiers)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .hotkeyRecorded, object: nil)
                }
            }
        }
        
        print("🪵 [SettingsView] Global monitor registered")
    }
    
    private func stopRecording() {
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
            print("🪵 [SettingsView] Recording stopped")
        }
    }
}

#Preview {
    SettingsView()
}
