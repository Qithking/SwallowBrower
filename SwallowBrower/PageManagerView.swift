//
//  PageManagerView.swift
//  SwallowBrower
//
//  Created by thking on 2026/4/11.
//

import SwiftUI
import SwiftData

struct PageManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.timestamp, order: .forward) private var bookmarks: [Bookmark]
    let onSelect: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void

    @State private var selectedItems: Set<Bookmark> = []
    @State private var isEditingItem: Bookmark? = nil
    @State private var isAddingItem = false
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var iconUrl: String = ""
    @State private var itemDescription: String = ""
    @State private var useSystemIcon: Bool = true
    @State private var systemIconName: String = "star"
    @State private var isPinned: Bool = false
    @State private var backgroundColor: String = "gray"
    @State private var sortOrder: Int = 0
    @State private var isIconPickerPresented = false
    @State private var isDraggingEnabled = false

    let systemIcons = ["star", "heart", "circle", "square", "triangle", "diamond", "star.fill", "heart.fill", "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "globe", "house", "bookmark", "folder", "doc", "photo", "music.note", "video", "link", "cloud", "envelope", "cart", "creditcard", "person", "gear", "wrench", "hammer", "paintbrush", "pencil", "paperclip", "tray", "archive", "lock", "key", "bell", "calendar", "clock", "flag", "tag", "book", "newspaper", "magnifyingglass"]

    let backgroundColors: [(name: String, color: Color)] = [
        ("gray", Color.gray),
        ("red", Color.red),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("green", Color.green),
        ("cyan", Color.cyan),
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("pink", Color.pink)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 拖拽排序开关
            HStack {
                Text("页签管理")
                    .font(.headline)
                Spacer()
                Button(action: { isDraggingEnabled.toggle() }) {
                    Label(isDraggingEnabled ? "完成排序" : "拖拽排序", systemImage: isDraggingEnabled ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            if isDraggingEnabled {
                // 拖拽排序模式
                List {
                    ForEach(bookmarks) { bookmark in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                            if bookmark.useSystemIcon {
                                Image(systemName: bookmark.systemIconName)
                                    .foregroundColor(.accentColor)
                            }
                            Text(bookmark.name)
                            Spacer()
                            if bookmark.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            Text("排序: \(bookmark.sortOrder)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveBookmarks)
                }
                .listStyle(.plain)
            } else {
                // 网格显示模式
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                        ForEach(bookmarks) { bookmark in
                            PageGridItem(
                                bookmark: bookmark,
                                isSelected: selectedItems.contains(bookmark),
                                onTap: { onSelect(bookmark) },
                                onEdit: { prepareEdit(bookmark) },
                                onDelete: { deleteItem(bookmark) },
                                onPin: { togglePin(bookmark) }
                            )
                        }
                        
                        AddCustomButton {
                            isAddingItem = true
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $isAddingItem) {
            AddEditSheet(
                title: "添加页签",
                name: $name,
                url: $url,
                iconUrl: $iconUrl,
                itemDescription: $itemDescription,
                useSystemIcon: $useSystemIcon,
                systemIconName: $systemIconName,
                isPinned: $isPinned,
                backgroundColor: $backgroundColor,
                sortOrder: $sortOrder,
                maxSortOrder: bookmarks.count,
                systemIcons: systemIcons,
                backgroundColors: backgroundColors,
                isIconPickerPresented: $isIconPickerPresented,
                onCancel: { isAddingItem = false },
                onSave: {
                    addItem()
                    isAddingItem = false
                }
            )
        }
        .sheet(item: $isEditingItem) { item in
            AddEditSheet(
                title: "编辑页签",
                name: $name,
                url: $url,
                iconUrl: $iconUrl,
                itemDescription: $itemDescription,
                useSystemIcon: $useSystemIcon,
                systemIconName: $systemIconName,
                isPinned: $isPinned,
                backgroundColor: $backgroundColor,
                sortOrder: $sortOrder,
                maxSortOrder: bookmarks.count,
                systemIcons: systemIcons,
                backgroundColors: backgroundColors,
                isIconPickerPresented: $isIconPickerPresented,
                onCancel: { isEditingItem = nil },
                onSave: {
                    updateItem(item)
                    isEditingItem = nil
                }
            )
        }
    }
    
    private func moveBookmarks(from source: IndexSet, to destination: Int) {
        var bookmarkList = bookmarks
        bookmarkList.move(fromOffsets: source, toOffset: destination)
        for (index, bookmark) in bookmarkList.enumerated() {
            bookmark.sortOrder = index
        }
    }

    private func prepareEdit(_ bookmark: Bookmark) {
        name = bookmark.name
        url = bookmark.url
        iconUrl = bookmark.iconUrl ?? ""
        itemDescription = bookmark.itemDescription ?? ""
        useSystemIcon = bookmark.useSystemIcon
        systemIconName = bookmark.systemIconName
        isPinned = bookmark.isPinned
        backgroundColor = bookmark.backgroundColor
        sortOrder = bookmark.sortOrder
        isEditingItem = bookmark
    }

    private func deleteItem(_ bookmark: Bookmark) {
        onDelete(bookmark)
    }
    
    private func togglePin(_ bookmark: Bookmark) {
        bookmark.isPinned.toggle()
    }

    private func resetForm() {
        name = ""
        url = ""
        iconUrl = ""
        itemDescription = ""
        useSystemIcon = true
        systemIconName = "star"
        isPinned = false
        backgroundColor = "gray"
        sortOrder = bookmarks.count
    }

    private func addItem() {
        let newBookmark = Bookmark(
            name: name,
            url: url,
            iconUrl: useSystemIcon ? nil : iconUrl,
            itemDescription: itemDescription,
            useSystemIcon: useSystemIcon,
            systemIconName: systemIconName,
            isPinned: isPinned,
            backgroundColor: backgroundColor,
            sortOrder: sortOrder
        )
        modelContext.insert(newBookmark)
        resetForm()
    }

    private func updateItem(_ bookmark: Bookmark) {
        bookmark.name = name
        bookmark.url = url
        bookmark.iconUrl = useSystemIcon ? nil : iconUrl
        bookmark.itemDescription = itemDescription
        bookmark.useSystemIcon = useSystemIcon
        bookmark.systemIconName = systemIconName
        bookmark.isPinned = isPinned
        bookmark.backgroundColor = backgroundColor
        bookmark.sortOrder = sortOrder
    }
}

struct PageGridItem: View {
    let bookmark: Bookmark
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    @State private var isHovered = false

    private var itemBackgroundColor: Color {
        let colorMap: [String: Color] = [
            "gray": .gray, "red": .red, "orange": .orange,
            "yellow": .yellow, "green": .green, "cyan": .cyan,
            "blue": .blue, "purple": .purple, "pink": .pink
        ]
        return (colorMap[bookmark.backgroundColor] ?? .gray).opacity(0.15)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(itemBackgroundColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: bookmark.useSystemIcon ? bookmark.systemIconName : "globe")
                        .font(.system(size: 26))
                        .foregroundColor(.primary)

                    if bookmark.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .offset(x: 18, y: -15)
                    }
                }

                Text(bookmark.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .frame(maxWidth: 70)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(action: onTap) {
                Label("打开", systemImage: "arrow.right.circle")
            }
            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            Divider()
            Button(action: onPin) {
                Label(bookmark.isPinned ? "取消固定" : "固定在侧边栏", systemImage: bookmark.isPinned ? "pin.slash" : "pin")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

struct AddCustomButton: View {
    let action: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                
                Text("自定义")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 70)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AddEditSheet: View {
    let title: String
    @Binding var name: String
    @Binding var url: String
    @Binding var iconUrl: String
    @Binding var itemDescription: String
    @Binding var useSystemIcon: Bool
    @Binding var systemIconName: String
    @Binding var isPinned: Bool
    @Binding var backgroundColor: String
    @Binding var sortOrder: Int
    let maxSortOrder: Int
    let systemIcons: [String]
    let backgroundColors: [(name: String, color: Color)]
    @Binding var isIconPickerPresented: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, url, description, iconUrl
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称", text: $name)
                        .focused($focusedField, equals: .name)
                    TextField("URL", text: $url)
                        .focused($focusedField, equals: .url)
                    TextField("描述", text: $itemDescription)
                        .focused($focusedField, equals: .description)
                }
                
                Section {
                    Toggle("固定到侧边栏", isOn: $isPinned)
                        .toggleStyle(.switch)
                    Stepper("排序位置: \(sortOrder)", value: $sortOrder, in: 0...maxSortOrder)
                        .help("数值越小排序越靠前")
                }
                
                Section("颜色") {
                    HStack(spacing: 8) {
                        ForEach(backgroundColors, id: \.name) { colorOption in
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: backgroundColor == colorOption.name ? 2 : 0)
                                )
                                .onTapGesture {
                                    backgroundColor = colorOption.name
                                }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Toggle("使用系统图标", isOn: $useSystemIcon)
                            .toggleStyle(.switch)
                        Spacer()
                        if useSystemIcon {
                            Button(action: {
                                isIconPickerPresented = true
                            }) {
                                HStack {
                                    Image(systemName: systemIconName)
                                        .font(.title2)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                        }
                    }
                    
                    if !useSystemIcon {
                        TextField("图标URL", text: $iconUrl)
                            .focused($focusedField, equals: .iconUrl)
                    }
                }
            }
            .formStyle(.grouped)
            .onAppear {
                focusedField = .name
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("存储", action: onSave)
                        .disabled(name.isEmpty || url.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isIconPickerPresented) {
                IconPicker(selectedIcon: $systemIconName, icons: systemIcons)
            }
        }
        .frame(width: 400, height: 450)
    }
}

struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if !label.isEmpty {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .leading)
            }
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconPicker: View {
    @Binding var selectedIcon: String
    let icons: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundColor(.primary)
                                
                                if selectedIcon == icon {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                        .offset(x: 22, y: -22)
                                }
                            }
                            Text(icon)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            selectedIcon = icon
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
