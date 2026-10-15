import Foundation
import SwiftUI
import Observation
import AppKit

@Observable
@MainActor
public final class CleanerManager {
    public static let shared = CleanerManager()
    
    public var items: [CleanTargetItem] = []
    public var isScanning: Bool = false
    public var isCleaning: Bool = false
    public var lastCleanedBytes: UInt64? = nil
    public var showSuccessBanner: Bool = false
    
    public init() {
        self.items = SystemCleanerEngine().defaultTargets()
        startScan()
    }
    
    public var totalReclaimableBytes: UInt64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var selectedReclaimableBytes: UInt64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var formattedTotalReclaimable: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalReclaimableBytes))
    }
    
    public var formattedSelectedReclaimable: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(selectedReclaimableBytes))
    }
    
    public func toggleItem(_ id: String) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isSelected.toggle()
        }
    }
    
    public func selectAll(_ select: Bool) {
        for idx in items.indices {
            items[idx].isSelected = select
        }
    }
    
    public func startScan() {
        guard !isScanning, !isCleaning else { return }
        isScanning = true
        showSuccessBanner = false
        
        let currentItems = self.items
        
        Task.detached(priority: .userInitiated) {
            let engine = SystemCleanerEngine()
            var updated = currentItems
            
            for idx in updated.indices {
                let size = engine.scanItemSize(updated[idx])
                updated[idx].sizeBytes = size
            }
            
            await CleanerManager.shared.applyScannedItems(updated)
        }
    }
    
    private func applyScannedItems(_ scanned: [CleanTargetItem]) {
        self.items = scanned
        self.isScanning = false
    }
    
    public func cleanSelected() {
        guard !isCleaning else { return }
        isCleaning = true
        showSuccessBanner = false
        
        let toClean = items.filter { $0.isSelected && $0.sizeBytes > 0 }
        
        Task.detached(priority: .userInitiated) {
            let engine = SystemCleanerEngine()
            var totalFreed: UInt64 = 0
            
            for target in toClean {
                let freed = engine.cleanTarget(target)
                totalFreed += freed
            }
            
            await CleanerManager.shared.finishCleaning(freedBytes: totalFreed)
        }
    }
    
    private func finishCleaning(freedBytes: UInt64) {
        self.lastCleanedBytes = freedBytes
        self.isCleaning = false
        self.showSuccessBanner = true
        // Re-scan to reflect fresh sizes
        startScan()
    }
    
    public func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
}
