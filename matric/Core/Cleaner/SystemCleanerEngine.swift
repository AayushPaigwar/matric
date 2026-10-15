import Foundation

public final class SystemCleanerEngine: Sendable {
    public nonisolated init() {}
    
    public nonisolated func defaultTargets() -> [CleanTargetItem] {
        let home = NSHomeDirectory()
        
        return [
            CleanTargetItem(
                id: "xcode_derived_data",
                category: .xcode,
                title: "Xcode DerivedData",
                descriptionText: "Intermediate build files, module caches, and index data generated during builds. Xcode recreates these automatically.",
                paths: ["\(home)/Library/Developer/Xcode/DerivedData"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "xcode_simulator_caches",
                category: .xcode,
                title: "iOS Simulator Caches",
                descriptionText: "Temporary runtime caches from CoreSimulator devices.",
                paths: ["\(home)/Library/Developer/CoreSimulator/Caches"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "npm_cache",
                category: .packageManagers,
                title: "npm & Node Caches",
                descriptionText: "Downloaded tarballs and metadata cached by npm.",
                paths: ["\(home)/.npm"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "yarn_cache",
                category: .packageManagers,
                title: "Yarn Cache",
                descriptionText: "Cached package archives from Yarn package manager.",
                paths: [
                    "\(home)/Library/Caches/Yarn",
                    "\(home)/.yarn/berry/cache"
                ],
                isSelected: true
            ),
            CleanTargetItem(
                id: "pnpm_cache",
                category: .packageManagers,
                title: "pnpm Store",
                descriptionText: "Hard-linked package store and temporary staging directories.",
                paths: [
                    "\(home)/Library/pnpm/store",
                    "\(home)/.local/share/pnpm/store"
                ],
                isSelected: false // false by default since hardlinks are shared
            ),
            CleanTargetItem(
                id: "cargo_cache",
                category: .packageManagers,
                title: "Rust Cargo Package Cache",
                descriptionText: "Downloaded crate archives and unpacked git sources in ~/.cargo.",
                paths: ["\(home)/.cargo/registry/cache"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "gradle_cache",
                category: .packageManagers,
                title: "Gradle Build Cache",
                descriptionText: "Cached dependency jars and distribution archives.",
                paths: ["\(home)/.gradle/caches"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "pip_cache",
                category: .packageManagers,
                title: "Python Pip Cache",
                descriptionText: "Wheel archives and HTTP response caches from pip install commands.",
                paths: ["\(home)/Library/Caches/pip"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "homebrew_cache",
                category: .packageManagers,
                title: "Homebrew Formula Caches",
                descriptionText: "Downloaded bottles, source tarballs, and git clone caches.",
                paths: ["\(home)/Library/Caches/Homebrew"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "app_logs",
                category: .systemLogs,
                title: "User Application Logs",
                descriptionText: "Historical diagnostic and crash log files in ~/Library/Logs.",
                paths: ["\(home)/Library/Logs"],
                isSelected: true
            ),
            CleanTargetItem(
                id: "system_trash",
                category: .trash,
                title: "System Trash Bin",
                descriptionText: "Items currently in the macOS Trash waiting to be permanently emptied.",
                paths: ["\(home)/.Trash"],
                isSelected: true
            )
        ]
    }
    
    public nonisolated func scanItemSize(_ item: CleanTargetItem) -> UInt64 {
        let fileManager = FileManager.default
        var totalBytes: UInt64 = 0
        
        for path in item.paths {
            guard fileManager.fileExists(atPath: path) else { continue }
            let url = URL(fileURLWithPath: path)
            
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
                if isDir.boolValue {
                    totalBytes += calculateDirectorySize(at: url)
                } else {
                    if let attrs = try? fileManager.attributesOfItem(atPath: path),
                       let size = attrs[.size] as? UInt64 {
                        totalBytes += size
                    }
                }
            }
        }
        
        return totalBytes
    }
    
    private nonisolated func calculateDirectorySize(at directoryURL: URL) -> UInt64 {
        let fileManager = FileManager.default
        var total: UInt64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey],
            options: []
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let resources = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) {
                total += UInt64(resources.totalFileAllocatedSize ?? resources.fileSize ?? 0)
            }
        }
        
        return total
    }
    
    public nonisolated func cleanTarget(_ item: CleanTargetItem) -> UInt64 {
        let fileManager = FileManager.default
        var freedBytes: UInt64 = 0
        
        for path in item.paths {
            guard fileManager.fileExists(atPath: path) else { continue }
            let dirURL = URL(fileURLWithPath: path)
            
            // Delete contents of directory to keep directory shell intact
            if let contents = try? fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for childURL in contents {
                    let size = (try? childURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    do {
                        try fileManager.removeItem(at: childURL)
                        freedBytes += UInt64(size)
                    } catch {
                        // Some files might be in use or locked
                    }
                }
            }
        }
        
        return freedBytes
    }
}
