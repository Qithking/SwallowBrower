//
//  Components.swift
//  bluePage
//
//  Created by thking on 2026/4/11.
//

import SwiftUI
import AppKit

// MARK: - Helper Functions

private func isColorDark(_ color: Color) -> Bool {
    guard let nsColor = NSColor(color).usingColorSpace(.deviceRGB) else { return false }
    let r = nsColor.redComponent
    let g = nsColor.greenComponent
    let b = nsColor.blueComponent
    let brightness = (r * 299 + g * 587 + b * 114) / 1000
    return brightness < 0.5
}

// MARK: - NoFocusButtonStyle
struct NoFocusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Sidebar Buttons

struct HomeButton: View {
    let isActive: Bool
    var sidebarColor: Color = .gray.opacity(0.2)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(NoFocusButtonStyle())
    }
}

struct SettingsButton: View {
    let isActive: Bool
    var sidebarColor: Color = .gray.opacity(0.2)
    let action: () -> Void
    
    private var foregroundColor: Color {
        isColorDark(sidebarColor) ? .white : .black
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(isActive ? .accentColor : foregroundColor)
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(NoFocusButtonStyle())
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let bookmark: Bookmark
    let isSelected: Bool
    var sidebarColor: Color = .gray.opacity(0.2)
    let onTap: () -> Void
    let onClose: () -> Void
    let onPin: (() -> Void)?
    let onUnpin: (() -> Void)?

    @State private var isHovered = false

    private var foregroundColor: Color {
        isColorDark(sidebarColor) ? .white : .black
    }

    private var backgroundColor: Color {
        if isSelected {
            return itemBackgroundColor
        } else if isHovered {
            return itemBackgroundColor.opacity(0.7)
        }
        return .clear
    }

    private var itemBackgroundColor: Color {
        let colorMap: [String: Color] = [
            "gray": .gray, "red": .red, "orange": .orange,
            "yellow": .yellow, "green": .green, "cyan": .cyan,
            "blue": .blue, "purple": .purple, "pink": .pink
        ]
        return (colorMap[bookmark.backgroundColor] ?? .gray).opacity(0.15)
    }

    private var dotColor: Color {
        let colorMap: [String: Color] = [
            "gray": .gray, "red": .red, "orange": .orange,
            "yellow": .yellow, "green": .green, "cyan": .cyan,
            "blue": .blue, "purple": .purple, "pink": .pink
        ]
        return colorMap[bookmark.backgroundColor] ?? .gray
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    Image(systemName: bookmark.useSystemIcon ? bookmark.systemIconName : "globe")
                        .font(.system(size: 20))
                        .foregroundColor(foregroundColor)

                    Text(bookmark.name)
                        .font(.system(size: 10))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isSelected || isHovered ? foregroundColor : foregroundColor.opacity(0.6))
                }
                .frame(width: 56)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)
                )

                if bookmark.isPinned {
                    Circle()
                        .stroke(dotColor, lineWidth: 2)
                        .frame(width: 5, height: 5)
                        .offset(x: 5, y: 5)
                } else {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                        .offset(x: 5, y: 5)
                }
            }
        }
        .buttonStyle(NoFocusButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("关闭") { onClose() }
            if bookmark.isPinned {
                if let onUnpin = onUnpin {
                    Button("取消固定") { onUnpin() }
                }
            } else {
                if let onPin = onPin {
                    Button("固定在侧边栏") { onPin() }
                }
            }
        }
    }
}

// MARK: - Overflow

struct OverflowButton: View {
    let count: Int
    @Binding var isOverflowPopoverPresented: Bool

    var body: some View {
        Button { isOverflowPopoverPresented.toggle() } label: {
            Text("+\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
        }
        .buttonStyle(NoFocusButtonStyle())
    }
}

struct OverflowPopover: View {
    let bookmarks: [Bookmark]
    let onSelect: (Bookmark) -> Void
    let onClose: (Bookmark) -> Void
    let onPin: (Bookmark) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("更多页签")
                .font(.headline)
                .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(bookmarks) { bookmark in
                        bookmarkRow(bookmark)
                    }
                }
            }
        }
        .padding()
        .frame(width: 200, height: 250)
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        HStack {
            Image(systemName: bookmark.useSystemIcon ? bookmark.systemIconName : "globe")
                .foregroundColor(.accentColor)
            Text(bookmark.name).lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(bookmark) }
        .contextMenu {
            Button("关闭") { onClose(bookmark) }
            Button(bookmark.isPinned ? "取消固定" : "固定在侧边栏") { onPin(bookmark) }
        }
    }
}

// MARK: - List Row

struct BookmarkListRow: View {
    let bookmark: Bookmark
    let isSelected: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    var body: some View {
        HStack {
            Image(systemName: bookmark.useSystemIcon ? bookmark.systemIconName : "globe")
                .foregroundColor(.accentColor)
            Text(bookmark.name)
            Spacer()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button(bookmark.isPinned ? "取消固定" : "固定在侧边栏") { onPin() }
            Button("编辑", action: onEdit)
            Button(role: .destructive, action: onDelete) { }
        }
    }
}
