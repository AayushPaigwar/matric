import Foundation
import SwiftUI
import Observation
import AppKit

public final class DiskSpaceScanner: Sendable {
    public nonisolated init() {}
    
    public nonisolated func checkFullDiskAccess() -> Bool {
        let home = NSHomeDirectory()
        let safariDir = "\(home)/Library/Safari"
        let fileManager = FileManager.default
        
        do {
            _ = try fileManager.contentsOfDirectory(atPath: safariDir)
            return true
        } catch {
            return false
        }
    }
    
    public nonisolated func queryVolumeCapacity() -> (total: UInt64, free: UInt64, used: UInt64) {
        let rootURL = URL(fileURLWithPath: "/")
        do {
            let values = try rootURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = UInt64(values.volumeTotalCapacity ?? 0)
            let free = UInt64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let used = total > free ? (total - free) : 0
            return (total, free, used)
        } catch {
            return (0, 0, 0)
        }
    }
    
    public nonisolated func scanCategorySizes() -> (sizes: [StorageCategory: UInt64], topItems: [StorageItem]) {
        let (_, _, used) = queryVolumeCapacity()
        var sizes: [StorageCategory: UInt64] = [:]
        var allDiscoveredItems: [StorageItem] = []
        let fileManager = FileManager.default
        
        for category in StorageCategory.allCases {
            // macOS and system data is dynamically allocated from the remaining volume space
            if category == .macOSAndSystem { continue }
            
            var categoryTotal: UInt64 = 0
            
            for basePath in category.defaultPaths {
                guard fileManager.fileExists(atPath: basePath) else { continue }
                let baseFolderURL = URL(fileURLWithPath: basePath)
                
                // For Applications and top-level directories, inspect children
                if let contents = try? fileManager.contentsOfDirectory(
                    at: baseFolderURL,
                    includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey, .isDirectoryKey, .isPackageKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for itemURL in contents {
                        let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                        let isPackage = (try? itemURL.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
                        
                        let itemSize = calculateItemSize(url: itemURL, isDirectory: isDir, maxFiles: 5000)
                        categoryTotal += itemSize
                        
                        // Collect large items (> 80 MB)
                        if itemSize > 80 * 1024 * 1024 {
                            allDiscoveredItems.append(StorageItem(
                                name: itemURL.lastPathComponent,
                                path: itemURL.path,
                                sizeBytes: itemSize,
                                category: category,
                                isDirectory: isDir && !isPackage
                            ))
                        }
                    }
                } else {
                    let isDir = (try? baseFolderURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    let singleSize = calculateItemSize(url: baseFolderURL, isDirectory: isDir, maxFiles: 5000)
                    categoryTotal += singleSize
                }
            }
            
            sizes[category] = categoryTotal
        }
        
        // Dynamically compute remaining APFS used container space for macOS and system data
        let scannedTotal = sizes.values.reduce(0, +)
        if used > scannedTotal {
            sizes[.macOSAndSystem] = used - scannedTotal
        } else {
            sizes[.macOSAndSystem] = 0
        }
        
        let sortedItems = Array(allDiscoveredItems.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(20))
        return (sizes, sortedItems)
    }
    
    private nonisolated func calculateItemSize(url: URL, isDirectory: Bool, maxFiles: Int = 5000) -> UInt64 {
        let fileManager = FileManager.default
        
        if !isDirectory {
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? UInt64 {
                return size
            }
            return 0
        }
        
        var totalSize: UInt64 = 0
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            count += 1
            if count > maxFiles {
                break
            }
            if let res = try? fileURL.resourceValues(forKeys: keys), res.isRegularFile == true {
                totalSize += UInt64(res.totalFileAllocatedSize ?? res.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
}
