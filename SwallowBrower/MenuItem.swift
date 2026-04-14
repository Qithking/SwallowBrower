//
//  MenuItem.swift
//  SwallowBrower
//
//  Created by thking on 2026/4/11.
//

import Foundation

/// 菜单项数据结构，用于侧边栏和WebView显示
struct MenuItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: String
    let iconUrl: String?
    let itemDescription: String?
    let useSystemIcon: Bool
    let systemIconName: String
    let isPinned: Bool

    init(
        name: String,
        url: String,
        iconUrl: String? = nil,
        itemDescription: String? = nil,
        useSystemIcon: Bool = true,
        systemIconName: String = "star",
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.iconUrl = iconUrl
        self.itemDescription = itemDescription
        self.useSystemIcon = useSystemIcon
        self.systemIconName = systemIconName
        self.isPinned = isPinned
    }

    init(from bookmark: Bookmark) {
        self.id = UUID()
        self.name = bookmark.name
        self.url = bookmark.url
        self.iconUrl = bookmark.iconUrl
        self.itemDescription = bookmark.itemDescription
        self.useSystemIcon = bookmark.useSystemIcon
        self.systemIconName = bookmark.systemIconName
        self.isPinned = bookmark.isPinned
    }
}
