//
//  Bookmark.swift
//  SwallowBrower
//
//  Created by thking on 2026/4/11.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Bookmark {
    var name: String
    var url: String
    var iconUrl: String?
    var itemDescription: String?
    var useSystemIcon: Bool
    var systemIconName: String
    var isPinned: Bool
    @Transient var hasBeenOpened: Bool = false
    var backgroundColor: String
    var timestamp: Date
    var sortOrder: Int

    init(
        name: String,
        url: String,
        iconUrl: String? = nil,
        itemDescription: String? = nil,
        useSystemIcon: Bool = true,
        systemIconName: String = "star",
        isPinned: Bool = false,
        hasBeenOpened: Bool = false,
        backgroundColor: String = "gray",
        sortOrder: Int = 0
    ) {
        self.name = name
        self.url = url
        self.iconUrl = iconUrl
        self.itemDescription = itemDescription
        self.useSystemIcon = useSystemIcon
        self.systemIconName = systemIconName
        self.isPinned = isPinned
        self.hasBeenOpened = hasBeenOpened
        self.backgroundColor = backgroundColor
        self.timestamp = Date()
        self.sortOrder = sortOrder
    }
}
