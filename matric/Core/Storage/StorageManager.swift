import Foundation
import SwiftUI
import Observation
import AppKit

@Observable
@MainActor
public final class StorageManager {
    public static let shared = StorageManager()
    
    public var breakdown: StorageBreakdown = StorageBreakdown()
    public var isScanning: Bool = false
    public var selectedCategory: StorageCategory? = nil
    
    public init() {
        startScan()
    }
    
    public func startScan() {
        guard !isScanning else { return }
        isScanning = true
        
        Task.detached(priority: .userInitiated) {
            let diskScanner = DiskSpaceScanner()
            let fda = diskScanner.checkFullDiskAccess()
            let (total, free, used) = diskScanner.queryVolumeCapacity()
            let (categorySizes, topItems) = diskScanner.scanCategorySizes()
            
            var newBreakdown = StorageBreakdown()
            newBreakdown.totalDiskBytes = total
            newBreakdown.freeDiskBytes = free
            newBreakdown.usedDiskBytes = used
            newBreakdown.categorySizes = categorySizes
            newBreakdown.largestItems = topItems
            newBreakdown.hasFullDiskAccess = fda
            newBreakdown.lastScanned = Date()
            
            await StorageManager.shared.applyBreakdown(newBreakdown)
        }
    }
    
    private func applyBreakdown(_ newBreakdown: StorageBreakdown) {
        self.breakdown = newBreakdown
        self.isScanning = false
    }
    
    public func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    
    public func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
