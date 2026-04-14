# SwallowBrower

一款优雅的 macOS 书签管理工具，通过网页视图展示和管理你的书签，支持全局快捷键呼出、侧边栏颜色跟随页面主题、自定义主题色等特性。

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green)

## 功能特性

### 📌 书签管理
- 创建、编辑、删除书签
- 支持自定义 User Agent
- 导入/导出书签数据（JSON 格式）

### 🎨 外观定制
- 支持浅色/深色/系统主题切换
- 自定义侧边栏背景颜色
- 侧边栏背景色跟随页面主题
- 自定义主题色（选中状态）
- 侧边栏透明度调节

### ⌨️ 快捷键
- 全局快捷键呼出应用（默认：⌘⇧B）
- 可自定义快捷键组合

### 🖥️ 系统集成
- 菜单栏图标
- 支持开机自启动
- 支持最小化到系统托盘
- 窗口位置和大小记忆

### 📡 数据管理
- 本地 SQLite 数据存储
- 支持导入/导出全部或部分数据
- 支持重置所有数据

## 系统要求

- macOS 12.0 (Monterey) 或更高版本
- Apple Silicon 或 Intel 处理器

## 安装

### 从源码编译

1. 克隆仓库
```bash
git clone https://github.com/thking/SwallowBrower.git
cd SwallowBrower
```

2. 使用 Xcode 打开项目
```bash
open SwallowBrower.xcodeproj
```

3. 在 Xcode 中选择 `Product → Build` (⌘B) 编译项目

4. 运行应用：`Product → Run` (⌘R)

## 使用指南

### 添加书签
1. 点击侧边栏的 "添加" 按钮
2. 输入页面名称和 URL
3. 点击保存

### 编辑书签
1. 鼠标悬停在书签上
2. 点击编辑图标
3. 修改内容后保存

### 删除书签
1. 鼠标悬停在书签上
2. 点击删除图标
3. 确认删除

### 全局快捷键
- 默认快捷键：**⌘⇧B**（Command + Shift + B）
- 可在设置中修改

### 数据导入/导出
- 导出：设置 → 数据管理 → 选择导出范围 → 导出
- 导入：设置 → 数据管理 → 导入数据 → 选择 JSON 文件

## 快捷键

| 功能 | 快捷键 |
|------|--------|
| 全局呼出 | ⌘⇧B (默认) |
| 新建书签 | ⌘N |
| 关闭窗口 | ⌘W |

## 数据存储

- 书签数据存储在：`~/Library/Application Support/com.thking.SwallowBrower/`
- 应用设置存储在：UserDefaults

## 项目结构

```
SwallowBrower/
├── SwallowBrower/
│   ├── AppDelegate.swift      # 应用代理
│   ├── main.swift             # 应用入口
│   ├── ContentView.swift      # 主视图
│   ├── SettingsView.swift     # 设置页面
│   ├── SidebarViews.swift     # 侧边栏组件
│   ├── WebPageView.swift      # 网页视图
│   ├── Bookmark.swift         # 书签数据模型
│   ├── DataManager.swift      # 数据管理
│   ├── HotkeyManager.swift    # 快捷键管理
│   └── TrayManager.swift      # 托盘管理
├── Assets.xcassets/           # 应用资源
└── SwallowBrower.xcodeproj/        # Xcode 项目文件
```

## 依赖

- Swift 5.9+
- SwiftUI 4.0+
- SwiftData
- HotKey (SPM) - 快捷键管理

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 致谢

- [HotKey](https://github.com/soffes/HotKey) - macOS 全局快捷键库
