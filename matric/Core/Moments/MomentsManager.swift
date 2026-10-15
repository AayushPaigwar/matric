import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class MomentsManager {
    public static let shared = MomentsManager()
    
    public var moments: [SavedMoment] = []
    public var selectedTag: String = "All"
    public var comparingMoments: [SavedMoment] = []
    
    // Explicit comparison selection slots
    public var comparisonMomentA: SavedMoment?
    public var comparisonMomentB: SavedMoment?
    
    private let storageURL: URL
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let matricDir = appSupport.appendingPathComponent("matric", isDirectory: true)
        try? fileManager.createDirectory(at: matricDir, withIntermediateDirectories: true)
        self.storageURL = matricDir.appendingPathComponent("moments.json")
        
        loadMoments()
        
        // Seed default moment if empty so user has instant visual understanding
        if moments.isEmpty {
            seedSampleMoments()
        }
    }
    
    public var allTags: [String] {
        var tags = Set<String>()
        tags.insert("All")
        for m in moments {
            tags.insert(m.tag)
        }
        return Array(tags).sorted()
    }
    
    public var availableTags: [String] {
        allTags
    }
    
    public var filteredMoments: [SavedMoment] {
        if selectedTag == "All" {
            return moments
        }
        return moments.filter { $0.tag.localizedCaseInsensitiveCompare(selectedTag) == .orderedSame }
    }
    
    // Capture current telemetry snapshot
    public func captureMoment(
        title: String? = nil,
        notes: String = "",
        tag: String = "General",
        hub: SystemTelemetryHub? = nil
    ) {
        let activeHub = hub ?? SystemTelemetryHub.shared
        let actualTitle: String
        if let t = title, !t.trimmingCharacters(in: .whitespaces).isEmpty {
            actualTitle = t.trimmingCharacters(in: .whitespaces)
        } else {
            let df = DateFormatter()
            df.dateFormat = "MMM d, h:mm a"
            actualTitle = "Snapshot \(df.string(from: Date()))"
        }
        
        // Extract top 5 apps by CPU
        let topApps = activeHub.appGroups
            .sorted { $0.totalCpuPercent > $1.totalCpuPercent }
            .prefix(5)
            .map { app in
                MomentAppItem(
                    name: app.name,
                    pid: app.rootPid,
                    cpuPercent: app.totalCpuPercent,
                    memoryBytes: app.totalMemoryBytes
                )
            }
        
        let plugged = !activeHub.battery.hasBattery || activeHub.battery.powerSourceState == "AC Power" || activeHub.battery.isCharging
        
        let newMoment = SavedMoment(
            title: actualTitle,
            notes: notes,
            tag: tag.isEmpty ? "General" : tag,
            createdAt: Date(),
            cpuPercent: activeHub.cpu.totalPercent,
            cpuUserPercent: activeHub.cpu.userPercent,
            cpuSystemPercent: activeHub.cpu.systemPercent,
            thermalState: activeHub.gpu.thermalState.rawValue,
            memoryUsedBytes: activeHub.memory.workingBytes,
            memoryTotalBytes: activeHub.memory.totalBytes,
            memoryPressure: activeHub.memory.pressureState.rawValue,
            swapUsedBytes: activeHub.memory.swapUsedBytes,
            diskReadBps: activeHub.disk.readBytesPerSec,
            diskWriteBps: activeHub.disk.writeBytesPerSec,
            diskAvailableBytes: activeHub.disk.freeSpaceBytes,
            networkDownloadBps: activeHub.network.totalDownloadBps,
            networkUploadBps: activeHub.network.totalUploadBps,
            gpuUtilization: activeHub.gpu.utilizationPercent,
            batteryPercent: activeHub.battery.hasBattery ? activeHub.battery.chargePercent : 100,
            batteryWatts: activeHub.battery.currentWatts,
            isPluggedIn: plugged,
            topApps: topApps
        )
        
        withAnimation {
            moments.insert(newMoment, at: 0)
        }
        saveMoments()
    }
    
    public func deleteMoment(_ moment: SavedMoment) {
        withAnimation {
            moments.removeAll { $0.id == moment.id }
            comparingMoments.removeAll { $0.id == moment.id }
            if comparisonMomentA?.id == moment.id { comparisonMomentA = nil }
            if comparisonMomentB?.id == moment.id { comparisonMomentB = nil }
        }
        saveMoments()
    }
    
    public func updateMoment(id: UUID, title: String, notes: String, tag: String) {
        guard let idx = moments.firstIndex(where: { $0.id == id }) else { return }
        moments[idx].title = title
        moments[idx].notes = notes
        moments[idx].tag = tag
        saveMoments()
    }
    
    // Comparison Helper
    public func toggleComparison(for moment: SavedMoment) {
        if let idx = comparingMoments.firstIndex(where: { $0.id == moment.id }) {
            comparingMoments.remove(at: idx)
        } else {
            if comparingMoments.count >= 2 {
                comparingMoments.removeFirst()
            }
            comparingMoments.append(moment)
        }
    }
    
    public func isComparing(_ moment: SavedMoment) -> Bool {
        comparingMoments.contains { $0.id == moment.id }
    }
    
    public func computeDelta(from base: SavedMoment, to target: SavedMoment) -> MomentDelta {
        MomentDelta(
            cpuDelta: target.cpuPercent - base.cpuPercent,
            memoryDeltaBytes: Int64(target.memoryUsedBytes) - Int64(base.memoryUsedBytes),
            gpuDelta: target.gpuUtilization - base.gpuUtilization,
            networkDeltaBps: (target.networkDownloadBps + target.networkUploadBps) - (base.networkDownloadBps + base.networkUploadBps)
        )
    }
    
    public func calculateDelta(from base: SavedMoment, to target: SavedMoment) -> MomentDelta {
        computeDelta(from: base, to: target)
    }
    
    // Export formatted report
    public func exportTextSummary(for moment: SavedMoment) -> String {
        """
        === Matric Telemetry Snapshot ===
        Title: \(moment.title)
        Tag: \(moment.tag)
        Timestamp: \(moment.createdAt.formatted(date: .abbreviated, time: .standard))
        Notes: \(moment.notes.isEmpty ? "None" : moment.notes)
        
        -- System Status --
        CPU: \(String(format: "%.1f%%", moment.cpuPercent)) (User: \(String(format: "%.1f%%", moment.cpuUserPercent)), Sys: \(String(format: "%.1f%%", moment.cpuSystemPercent)))
        Thermal State: \(moment.thermalState)
        Memory: \(moment.formattedMemoryUsed) (Pressure: \(moment.memoryPressure), Swap: \(moment.formattedSwap))
        Disk Available: \(moment.formattedDiskAvailable)
        Network: \(moment.formattedNetworkSpeed)
        GPU: \(String(format: "%.1f%%", moment.gpuUtilization))
        Battery: \(moment.batteryPercent)% (\(String(format: "%.1fW", moment.batteryWatts)), \(moment.isPluggedIn ? "AC Power" : "Discharging"))
        
        -- Top Applications --
        \(moment.topApps.map { "• \($0.name) (PID \($0.pid)): \(String(format: "%.1f%%", $0.cpuPercent)) CPU, \($0.formattedMemory)" }.joined(separator: "\n"))
        """
    }
    
    public func exportMomentSummary(_ moment: SavedMoment) -> String {
        exportTextSummary(for: moment)
    }
    
    private func saveMoments() {
        let list = self.moments
        let url = self.storageURL
        Task.detached(priority: .background) {
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
    
    private func loadMoments() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([SavedMoment].self, from: data) else {
            return
        }
        self.moments = list
    }
    
    private func seedSampleMoments() {
        let sample1 = SavedMoment(
            title: "Baseline Idle State",
            notes: "Clean system boot before launching developer workspaces.",
            tag: "Baseline",
            createdAt: Date().addingTimeInterval(-86400),
            cpuPercent: 5.2,
            cpuUserPercent: 3.1,
            cpuSystemPercent: 2.1,
            thermalState: "Nominal",
            memoryUsedBytes: 6_442_450_944,
            memoryTotalBytes: 34_359_738_368,
            memoryPressure: "Normal",
            swapUsedBytes: 0,
            diskReadBps: 240_000,
            diskWriteBps: 80_000,
            diskAvailableBytes: 350_000_000_000,
            networkDownloadBps: 45_000,
            networkUploadBps: 12_000,
            gpuUtilization: 3.5,
            batteryPercent: 100,
            batteryWatts: 4.5,
            isPluggedIn: true,
            topApps: [
                MomentAppItem(name: "WindowServer", pid: 210, cpuPercent: 2.1, memoryBytes: 420_000_000),
                MomentAppItem(name: "Finder", pid: 340, cpuPercent: 0.5, memoryBytes: 150_000_000)
            ]
        )
        self.moments = [sample1]
    }
}
