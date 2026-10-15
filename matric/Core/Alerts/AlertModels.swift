import Foundation
import SwiftUI

public enum AlertSeverity: String, CaseIterable, Codable, Sendable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"
    
    public var iconName: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .critical: return Color.red
        case .warning: return Color.orange
        case .info: return Color.blue
        }
    }
}

public enum AlertType: String, CaseIterable, Codable, Sendable {
    case highCPU = "High CPU Load"
    case highMemory = "High Memory Pressure"
    case lowDiskSpace = "Low Disk Space"
    case thermalThrottling = "Thermal Throttling"
    case batteryDrain = "High Battery Drain"
    case swapThrashing = "Elevated Swap Usage"
    
    public var defaultSeverity: AlertSeverity {
        switch self {
        case .highCPU: return .warning
        case .highMemory: return .critical
        case .lowDiskSpace: return .warning
        case .thermalThrottling: return .critical
        case .batteryDrain: return .warning
        case .swapThrashing: return .info
        }
    }
    
    public var iconName: String {
        switch self {
        case .highCPU: return "cpu"
        case .highMemory: return "memorychip"
        case .lowDiskSpace: return "internaldrive"
        case .thermalThrottling: return "flame.fill"
        case .batteryDrain: return "battery.25"
        case .swapThrashing: return "arrow.triangle.2.circlepath"
        }
    }
}

public struct SystemAlert: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let culpritAppName: String?
    public let culpritPID: pid_t?
    public let metricValue: String
    public let timestamp: Date
    public var isResolved: Bool
    public var resolvedAt: Date?
    
    public nonisolated init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        culpritAppName: String? = nil,
        culpritPID: pid_t? = nil,
        metricValue: String,
        timestamp: Date = Date(),
        isResolved: Bool = false,
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.culpritAppName = culpritAppName
        self.culpritPID = culpritPID
        self.metricValue = metricValue
        self.timestamp = timestamp
        self.isResolved = isResolved
        self.resolvedAt = resolvedAt
    }
}
