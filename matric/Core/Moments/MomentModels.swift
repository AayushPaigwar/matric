import Foundation
import SwiftUI

public struct MomentAppItem: Identifiable, Codable, Sendable, Equatable, Hashable {
    public var id: String { "\(name)-\(pid)" }
    public let name: String
    public let pid: pid_t
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    
    public nonisolated init(name: String, pid: pid_t, cpuPercent: Double, memoryBytes: UInt64) {
        self.name = name
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
    }
    
    public var formattedMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryBytes))
    }
}

public struct SavedMoment: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var tag: String
    public let createdAt: Date
    
    // CPU
    public let cpuPercent: Double
    public let cpuUserPercent: Double
    public let cpuSystemPercent: Double
    public let thermalState: String
    
    // Memory
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let memoryPressure: String
    public let swapUsedBytes: UInt64
    
    // Disk
    public let diskReadBps: Double
    public let diskWriteBps: Double
    public let diskAvailableBytes: UInt64
    
    // Network
    public let networkDownloadBps: Double
    public let networkUploadBps: Double
    
    // GPU & Battery
    public let gpuUtilization: Double
    public let batteryPercent: Int
    public let batteryWatts: Double
    public let isPluggedIn: Bool
    
    // Attribution
    public let topApps: [MomentAppItem]
    
    public nonisolated init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        tag: String = "General",
        createdAt: Date = Date(),
        cpuPercent: Double,
        cpuUserPercent: Double = 0.0,
        cpuSystemPercent: Double = 0.0,
        thermalState: String = "Nominal",
        memoryUsedBytes: UInt64,
        memoryTotalBytes: UInt64,
        memoryPressure: String,
        swapUsedBytes: UInt64 = 0,
        diskReadBps: Double = 0.0,
        diskWriteBps: Double = 0.0,
        diskAvailableBytes: UInt64 = 0,
        networkDownloadBps: Double = 0.0,
        networkUploadBps: Double = 0.0,
        gpuUtilization: Double = 0.0,
        batteryPercent: Int = 100,
        batteryWatts: Double = 0.0,
        isPluggedIn: Bool = true,
        topApps: [MomentAppItem] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.tag = tag
        self.createdAt = createdAt
        self.cpuPercent = cpuPercent
        self.cpuUserPercent = cpuUserPercent
        self.cpuSystemPercent = cpuSystemPercent
        self.thermalState = thermalState
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.memoryPressure = memoryPressure
        self.swapUsedBytes = swapUsedBytes
        self.diskReadBps = diskReadBps
        self.diskWriteBps = diskWriteBps
        self.diskAvailableBytes = diskAvailableBytes
        self.networkDownloadBps = networkDownloadBps
        self.networkUploadBps = networkUploadBps
        self.gpuUtilization = gpuUtilization
        self.batteryPercent = batteryPercent
        self.batteryWatts = batteryWatts
        self.isPluggedIn = isPluggedIn
        self.topApps = topApps
    }
    
    public var formattedMemoryUsed: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsedBytes))
    }
    
    public var formattedSwap: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(swapUsedBytes))
    }
    
    public var formattedDiskAvailable: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(diskAvailableBytes))
    }
    
    public var formattedNetworkSpeed: String {
        let total = networkDownloadBps + networkUploadBps
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return "\(formatter.string(fromByteCount: Int64(total)))/s"
    }
    
    public static func == (lhs: SavedMoment, rhs: SavedMoment) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct MomentDelta: Sendable {
    public let cpuDelta: Double
    public let memoryDeltaBytes: Int64
    public let gpuDelta: Double
    public let networkDeltaBps: Double
    
    public var formattedCpuDelta: String {
        let sign = cpuDelta >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, cpuDelta)
    }
    
    public var formattedMemoryDelta: String {
        let sign = memoryDeltaBytes >= 0 ? "+" : "-"
        let absBytes = abs(memoryDeltaBytes)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return "\(sign)\(formatter.string(fromByteCount: absBytes))"
    }
}
