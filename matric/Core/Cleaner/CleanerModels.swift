import Foundation
import SwiftUI

public enum CleanTargetCategory: String, CaseIterable, Identifiable, Sendable {
    case xcode = "Xcode & Developer"
    case packageManagers = "Package Managers"
    case systemCaches = "System & User Caches"
    case systemLogs = "Application Logs"
    case trash = "System Trash"
    case docker = "Docker Artifacts"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .xcode: return "hammer.fill"
        case .packageManagers: return "cube.box.fill"
        case .systemCaches: return "bolt.horizontal.fill"
        case .systemLogs: return "doc.plaintext.fill"
        case .trash: return "trash.fill"
        case .docker: return "shippingbox.fill"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .xcode: return Color.purple
        case .packageManagers: return Color.orange
        case .systemCaches: return Color.yellow
        case .systemLogs: return Color.teal
        case .trash: return Color.red
        case .docker: return Color.blue
        }
    }
}

public struct CleanTargetItem: Identifiable, Sendable {
    public let id: String
    public let category: CleanTargetCategory
    public let title: String
    public let descriptionText: String
    public let paths: [String]
    public var sizeBytes: UInt64
    public var isSelected: Bool
    public let isSafe: Bool
    
    public nonisolated init(
        id: String,
        category: CleanTargetCategory,
        title: String,
        descriptionText: String,
        paths: [String],
        sizeBytes: UInt64 = 0,
        isSelected: Bool = true,
        isSafe: Bool = true
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.descriptionText = descriptionText
        self.paths = paths
        self.sizeBytes = sizeBytes
        self.isSelected = isSelected
        self.isSafe = isSafe
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(sizeBytes))
    }
}
