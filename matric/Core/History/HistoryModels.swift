import Foundation
import SwiftUI

public enum HistoryRange: String, CaseIterable, Identifiable, Codable, Sendable {
    case oneHour = "1 Hour"
    case twentyFourHours = "24 Hours"
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    
    public var id: String { rawValue }
    
    public var shortLabel: String {
        switch self {
        case .oneHour: return "1H"
        case .twentyFourHours: return "24H"
        case .sevenDays: return "7D"
        case .thirtyDays: return "30D"
        }
    }
    
    public var durationSeconds: TimeInterval {
        switch self {
        case .oneHour: return 3600
        case .twentyFourHours: return 86400
        case .sevenDays: return 86400 * 7
        case .thirtyDays: return 86400 * 30
        }
    }
}

public enum HistoryMetricType: String, CaseIterable, Identifiable, Codable, Sendable {
    case cpu = "Processor (CPU)"
    case memory = "Physical Memory"
    case gpu = "Graphics (GPU)"
    case network = "Network Traffic"
    case disk = "Disk Throughput"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .gpu: return "display"
        case .network: return "network"
        case .disk: return "internaldrive"
        }
    }
    
    public var unitLabel: String {
        switch self {
        case .cpu, .gpu: return "%"
        case .memory: return "GB"
        case .network, .disk: return "MB/s"
        }
    }
    
    public var chartColor: Color {
        switch self {
        case .cpu: return Color.blue
        case .memory: return Color.green
        case .gpu: return Color.purple
        case .network: return Color.cyan
        case .disk: return Color.orange
        }
    }
}

public struct HistoryPoint: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let cpuPercent: Double
    public let memoryUsedGB: Double
    public let memoryPressure: Double // 0.0 - 100.0%
    public let gpuPercent: Double
    public let networkTotalMBps: Double
    public let diskTotalMBps: Double
    public let batteryPercent: Double
    
    public nonisolated init(
        id: UUID = UUID(),
        timestamp: Date,
        cpuPercent: Double,
        memoryUsedGB: Double,
        memoryPressure: Double = 15.0,
        gpuPercent: Double = 5.0,
        networkTotalMBps: Double = 0.5,
        diskTotalMBps: Double = 2.0,
        batteryPercent: Double = 100.0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cpuPercent = cpuPercent
        self.memoryUsedGB = memoryUsedGB
        self.memoryPressure = memoryPressure
        self.gpuPercent = gpuPercent
        self.networkTotalMBps = networkTotalMBps
        self.diskTotalMBps = diskTotalMBps
        self.batteryPercent = batteryPercent
    }
    
    public func value(for metric: HistoryMetricType) -> Double {
        switch metric {
        case .cpu: return cpuPercent
        case .memory: return memoryUsedGB
        case .gpu: return gpuPercent
        case .network: return networkTotalMBps
        case .disk: return diskTotalMBps
        }
    }
}

public struct HistoryHighlight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let detail: String
    public let timestamp: Date
    public let iconName: String
    public let color: Color
}
