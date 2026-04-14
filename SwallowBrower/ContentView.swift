//
//  ContentView.swift
//  bluePage
//
//  Created by thking on 2026/4/11.
//

import SwiftUI
import SwiftData
import AppKit

// 自定义视图包装器，禁用焦点环
struct NoFocusRingView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSHostingView(rootView: content)
        view.focusRingType = .none
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let hostingView = nsView as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    @State private var selectedMenuItem: MenuItem? = nil
    @State private var showPageManager = true
    @State private var showSettings = false
    @State private var isOverflowPopoverPresented = false
    @State private var isSidebarCollapsed = false
    @StateObject private var colorExtractor = PageColorExtractor()
    @State private var currentViewId: UUID = UUID()
    @State private var openedBookmarkIds: [PersistentIdentifier] = []
    @AppStorage("sidebarOpacity") private var sidebarOpacity: Double = 1.0

    private let maxVisibleIcons = 6
    private let defaultColor = Color.gray.opacity(0.15)

    // MARK: - Computed Properties

    private var sidebarItems: [Bookmark] {
        let pinnedItems = bookmarks.filter { $0.isPinned }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.timestamp < $1.timestamp
            }
        
        let unpinnedItems = openedBookmarkIds.compactMap { id in
            bookmarks.first { $0.id == id && !$0.isPinned }
        }
        
        return pinnedItems + unpinnedItems
    }

    private var visibleItems: [Bookmark] {
        Array(sidebarItems.prefix(maxVisibleIcons))
    }

    private var overflowCount: Int {
        max(0, sidebarItems.count - maxVisibleIcons)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                sidebarView
                noFocusContentView
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            openSettings()
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        ZStack {
            colorExtractor.extractedColor
        }
        .frame(width: isSidebarCollapsed ? 0 : 75)
        .clipped()
        .opacity(isSidebarCollapsed ? 0 : sidebarOpacity)
        
        .overlay(alignment: .top) {
            VStack(spacing: 4) {
                Spacer().frame(height: 30)

                HomeButton(isActive: showPageManager && !showSettings, sidebarColor: colorExtractor.extractedColor) {
                    colorExtractor.stop()
                    colorExtractor.extractedColor = self.defaultColor
                    showPageManager = true
                    showSettings = false
                    selectedMenuItem = nil
                }

                iconListView

                Spacer()
                SettingsButton(isActive: showSettings, sidebarColor: colorExtractor.extractedColor) {
                    colorExtractor.stop()
                    colorExtractor.extractedColor = self.defaultColor
                    showSettings = true
                    showPageManager = false
                    selectedMenuItem = nil
                }
                Spacer().frame(height: 8)
            }
        }
    }

    // MARK: - Icon List

    private var iconListView: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(visibleItems) { bookmark in
                    IconButton(
                        bookmark: bookmark,
                        isSelected: isItemSelected(bookmark),
                        sidebarColor: colorExtractor.extractedColor,
                        onTap: { openItem(bookmark) },
                        onClose: { closeItem(bookmark) },
                        onPin: bookmark.isPinned ? nil : { pinItem(bookmark) },
                        onUnpin: bookmark.isPinned ? { unpinItem(bookmark) } : nil
                    )
                }

                if overflowCount > 0 {
                    OverflowButton(count: overflowCount, isOverflowPopoverPresented: $isOverflowPopoverPresented)
                        .popover(isPresented: $isOverflowPopoverPresented, arrowEdge: .leading) {
                            OverflowPopover(
                                bookmarks: Array(sidebarItems.dropFirst(maxVisibleIcons)),
                                onSelect: { openItem($0) },
                                onClose: { closeItem($0) },
                                onPin: { pinItem($0) }
                            )
                            .frame(width: 200)
                        }
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if showSettings {
            SettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if showPageManager {
            PageManagerView(
                onSelect: { openItem($0) },
                onDelete: { deleteItem($0) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let selectedItem = selectedMenuItem {
            WebPageView(viewId: currentViewId, url: selectedItem.url, colorExtractor: colorExtractor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            emptyStateView
        }
    }
    
    // 禁用焦点环的内容视图
    private var noFocusContentView: some View {
        NoFocusRingView {
            contentView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text("请从左侧选择一个页签")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func openItem(_ bookmark: Bookmark) {
        currentViewId = UUID()
        if !openedBookmarkIds.contains(bookmark.id) {
            openedBookmarkIds.append(bookmark.id)
        }
        selectedMenuItem = MenuItem(from: bookmark)
        showPageManager = false
        showSettings = false
        colorExtractor.start()
    }

    private func closeItem(_ bookmark: Bookmark) {
        if selectedMenuItem?.name == bookmark.name && selectedMenuItem?.url == bookmark.url {
            selectedMenuItem = nil
        }
        if !bookmark.isPinned {
            openedBookmarkIds.removeAll { $0 == bookmark.id }
        }
    }

    private func pinItem(_ bookmark: Bookmark) {
        bookmark.isPinned = true
    }
    
    private func unpinItem(_ bookmark: Bookmark) {
        bookmark.isPinned = false
        if !openedBookmarkIds.contains(bookmark.id) {
            openedBookmarkIds.removeAll { $0 == bookmark.id }
        }
    }

    private func isItemSelected(_ bookmark: Bookmark) -> Bool {
        guard let selected = selectedMenuItem else { return false }
        return selected.name == bookmark.name && selected.url == bookmark.url
    }

    private func deleteItem(_ bookmark: Bookmark) {
        withAnimation {
            modelContext.delete(bookmark)
        }
    }
    
    func openSettings() {
        colorExtractor.stop()
        colorExtractor.extractedColor = Color.gray.opacity(0.15)
        showSettings = true
        showPageManager = false
        selectedMenuItem = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bookmark.self, inMemory: true)
}
