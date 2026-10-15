import Foundation
import SwiftUI

public enum StorageCategory: String, CaseIterable, Identifiable, Sendable {
    case applications = "Applications"
    case developer = "Developer Tools"
    case documents = "Documents & Files"
    case downloads = "Downloads"
    case appSupport = "Application Support"
    case containers = "Sandboxes & Containers"
    case caches = "User Caches"
    case trash = "Trash Bin"
    case macOSAndSystem = "macOS & System Data"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .applications: return "app.badge.checkmark.fill"
        case .developer: return "hammer.fill"
        case .documents: return "doc.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .appSupport: return "gearshape.2.fill"
        case .containers: return "shippingbox.fill"
        case .caches: return "bolt.horizontal.fill"
        case .trash: return "trash.fill"
        case .macOSAndSystem: return "apple.logo"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .applications: return Color.blue
        case .developer: return Color.purple
        case .documents: return Color.indigo
        case .downloads: return Color.orange
        case .appSupport: return Color.teal
        case .containers: return Color.mint
        case .caches: return Color.yellow
        case .trash: return Color.red
        case .macOSAndSystem: return Color(white: 0.5)
        }
    }
    
    public var defaultPaths: [String] {
        let home = NSHomeDirectory()
        switch self {
        case .applications:
            return ["/Applications", "\(home)/Applications"]
        case .developer:
            return [
                "\(home)/Library/Developer",
                "\(home)/.cargo",
                "\(home)/.npm",
                "\(home)/.gradle"
            ]
        case .documents:
            return ["\(home)/Documents", "\(home)/Desktop", "\(home)/Developer"]
        case .downloads:
            return ["\(home)/Downloads"]
        case .appSupport:
            return ["\(home)/Library/Application Support"]
        case .containers:
            return [
                "\(home)/Library/Containers",
                "\(home)/Library/Group Containers"
            ]
        case .caches:
            return ["\(home)/Library/Caches"]
        case .trash:
            return ["\(home)/.Trash"]
        case .macOSAndSystem:
            return ["/System", "/Library"]
        }
    }
}

public struct StorageItem: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let sizeBytes: UInt64
    public let category: StorageCategory
    public let isDirectory: Bool
    
    public nonisolated init(
        id: UUID = UUID(),
        name: String,
        path: String,
        sizeBytes: UInt64,
        category: StorageCategory,
        isDirectory: Bool
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.category = category
        self.isDirectory = isDirectory
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(sizeBytes))
    }
}

public struct StorageBreakdown: Sendable {
    public var totalDiskBytes: UInt64 = 0
    public var usedDiskBytes: UInt64 = 0
    public var freeDiskBytes: UInt64 = 0
    public var categorySizes: [StorageCategory: UInt64] = [:]
    public var largestItems: [StorageItem] = []
    public var hasFullDiskAccess: Bool = false
    public var lastScanned: Date?
    
    public nonisolated init() {}
    
    public var formattedTotal: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalDiskBytes))
    }
    
    public var formattedUsed: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(usedDiskBytes))
    }
    
    public var formattedFree: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(freeDiskBytes))
    }
    
    public func percentage(for category: StorageCategory) -> Double {
        guard usedDiskBytes > 0 else { return 0 }
        let size = categorySizes[category] ?? 0
        return (Double(size) / Double(usedDiskBytes)) * 100.0
    }
}
