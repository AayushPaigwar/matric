import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class AlertsManager {
    public static let shared = AlertsManager()
    
    public var alerts: [SystemAlert] = []
    public var selectedFilter: AlertFilter = .all
    
    // Configurable thresholds
    public var cpuThresholdPercent: Double = 85.0
    public var memoryThresholdPressure: String = "Warning" // Warning or Critical
    public var lowDiskThresholdGB: Double = 15.0
    public var batteryDrainThresholdWatts: Double = 30.0
    
    // Sustained violation tracking counters (to avoid false positive spikes)
    private var highCpuStreak: Int = 0
    private var highMemoryStreak: Int = 0
    private var thermalStreak: Int = 0
    private var swapStreak: Int = 0
    
    public enum AlertFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case critical = "Critical"
        case warnings = "Warnings"
        case resolved = "Resolved"
        
        public var id: String { rawValue }
    }
    
    public var activeAlertsCount: Int {
        alerts.filter { !$0.isResolved }.count
    }
    
    public var criticalCount: Int {
        alerts.filter { !$0.isResolved && $0.severity == .critical }.count
    }
    
    public var resolvedCount: Int {
        alerts.filter { $0.isResolved }.count
    }
    
    public var isSystemHealthy: Bool {
        activeAlertsCount == 0
    }
    
    public var filteredAlerts: [SystemAlert] {
        switch selectedFilter {
        case .all:
            return alerts
        case .active:
            return alerts.filter { !$0.isResolved }
        case .critical:
            return alerts.filter { $0.severity == .critical }
        case .warnings:
            return alerts.filter { $0.severity == .warning }
        case .resolved:
            return alerts.filter { $0.isResolved }
        }
    }
    
    private let storageURL: URL
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let matricDir = appSupport.appendingPathComponent("matric", isDirectory: true)
        try? fileManager.createDirectory(at: matricDir, withIntermediateDirectories: true)
        self.storageURL = matricDir.appendingPathComponent("alerts_history.json")
        
        loadAlerts()
        
        // If empty, seed initial sample alert so user has rich visual on first run
        if alerts.isEmpty {
            seedSampleAlerts()
        }
    }
    
    // Evaluate system conditions during telemetry poll
    public func evaluateTelemetry(
        cpu: CPUSample,
        memory: MemorySample,
        disk: DiskSample,
        gpu: GPUSample,
        battery: BatterySample,
        appGroups: [AppGroupRecord]
    ) {
        // 1. High CPU evaluation
        let topCpuApp = appGroups.max { $0.totalCpuPercent < $1.totalCpuPercent }
        if cpu.totalPercent >= cpuThresholdPercent || (topCpuApp?.totalCpuPercent ?? 0) >= 80.0 {
            highCpuStreak += 1
            if highCpuStreak >= 2 { // Sustained for 2+ ticks
                let culprit = topCpuApp?.name ?? "Background Task"
                let pid = topCpuApp?.rootPid
                let valStr = String(format: "%.1f%% CPU", cpu.totalPercent)
                triggerAlert(
                    type: .highCPU,
                    severity: cpu.totalPercent >= 95.0 ? .critical : .warning,
                    title: "Sustained High CPU Usage",
                    message: "\(culprit) is generating high CPU activity (\(String(format: "%.1f%%", topCpuApp?.totalCpuPercent ?? cpu.totalPercent))).",
                    culpritAppName: culprit,
                    culpritPID: pid,
                    metricValue: valStr
                )
            }
        } else {
            highCpuStreak = 0
            resolveAlerts(of: .highCPU)
        }
        
        // 2. Memory Pressure evaluation
        let isCritical = memory.pressureState == .critical
        let isElevated = memory.pressureState == .elevated
        if isCritical || isElevated {
            highMemoryStreak += 1
            if highMemoryStreak >= 2 {
                let topMemApp = appGroups.max { $0.totalMemoryBytes < $1.totalMemoryBytes }
                let culprit = topMemApp?.name ?? "Applications"
                let pid = topMemApp?.rootPid
                let memGB = Double(topMemApp?.totalMemoryBytes ?? 0) / 1_073_741_824.0
                triggerAlert(
                    type: .highMemory,
                    severity: isCritical ? .critical : .warning,
                    title: "\(memory.pressureState.rawValue) Memory Pressure",
                    message: "\(culprit) is holding \(String(format: "%.2f GB", memGB)) of physical RAM while system pressure is high.",
                    culpritAppName: culprit,
                    culpritPID: pid,
                    metricValue: "\(memory.pressureState.rawValue) Pressure"
                )
            }
        } else {
            highMemoryStreak = 0
            resolveAlerts(of: .highMemory)
        }
        
        // 3. Low Disk Space evaluation
        let freeGB = Double(disk.freeSpaceBytes) / 1_073_741_824.0
        if freeGB < lowDiskThresholdGB && disk.totalSpaceBytes > 0 {
            triggerAlert(
                type: .lowDiskSpace,
                severity: freeGB < 5.0 ? .critical : .warning,
                title: "Low Startup Disk Space",
                message: "Startup disk has only \(String(format: "%.1f GB", freeGB)) free space remaining.",
                culpritAppName: nil,
                culpritPID: nil,
                metricValue: String(format: "%.1f GB Free", freeGB)
            )
        } else {
            resolveAlerts(of: .lowDiskSpace)
        }
        
        // 4. Thermal Throttling evaluation
        let isThermalHot = gpu.thermalState == .serious || gpu.thermalState == .critical
        if isThermalHot {
            thermalStreak += 1
            if thermalStreak >= 2 {
                triggerAlert(
                    type: .thermalThrottling,
                    severity: .critical,
                    title: "Thermal Throttling Active",
                    message: "Mac hardware thermal state is \(gpu.thermalState.rawValue). CPU speeds may be temporarily capped.",
                    culpritAppName: nil,
                    culpritPID: nil,
                    metricValue: gpu.thermalState.rawValue
                )
            }
        } else {
            thermalStreak = 0
            resolveAlerts(of: .thermalThrottling)
        }
        
        // 5. Swap Thrashing
        let swapGB = Double(memory.swapUsedBytes) / 1_073_741_824.0
        if swapGB > 3.0 {
            swapStreak += 1
            if swapStreak >= 3 {
                triggerAlert(
                    type: .swapThrashing,
                    severity: .info,
                    title: "Elevated Swap Usage",
                    message: "The system has swapped \(String(format: "%.1f GB", swapGB)) to disk, which may impact responsiveness.",
                    culpritAppName: nil,
                    culpritPID: nil,
                    metricValue: String(format: "%.1f GB Swap", swapGB)
                )
            }
        } else {
            swapStreak = 0
            resolveAlerts(of: .swapThrashing)
        }
    }
    
    public func triggerAlert(
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        culpritAppName: String?,
        culpritPID: pid_t?,
        metricValue: String
    ) {
        // If an active alert of this type already exists, don't create duplicate
        if let idx = alerts.firstIndex(where: { $0.type == type && !$0.isResolved }) {
            // Update message and metric
            let existing = alerts[idx]
            alerts[idx] = SystemAlert(
                id: existing.id,
                type: type,
                severity: severity,
                title: title,
                message: message,
                culpritAppName: culpritAppName ?? existing.culpritAppName,
                culpritPID: culpritPID ?? existing.culpritPID,
                metricValue: metricValue,
                timestamp: existing.timestamp,
                isResolved: false
            )
            return
        }
        
        let newAlert = SystemAlert(
            type: type,
            severity: severity,
            title: title,
            message: message,
            culpritAppName: culpritAppName,
            culpritPID: culpritPID,
            metricValue: metricValue,
            timestamp: Date(),
            isResolved: false
        )
        
        withAnimation {
            alerts.insert(newAlert, at: 0)
        }
        saveAlerts()
    }
    
    public func resolveAlerts(of type: AlertType) {
        var changed = false
        for i in 0..<alerts.count {
            if alerts[i].type == type && !alerts[i].isResolved {
                alerts[i].isResolved = true
                alerts[i].resolvedAt = Date()
                changed = true
            }
        }
        if changed {
            saveAlerts()
        }
    }
    
    public func dismissAlert(_ alert: SystemAlert) {
        withAnimation {
            if let idx = alerts.firstIndex(where: { $0.id == alert.id }) {
                alerts[idx].isResolved = true
                alerts[idx].resolvedAt = Date()
            }
        }
        saveAlerts()
    }
    
    public func deleteAlert(_ alert: SystemAlert) {
        withAnimation {
            alerts.removeAll { $0.id == alert.id }
        }
        saveAlerts()
    }
    
    public func clearAllAlerts() {
        withAnimation {
            alerts.removeAll()
        }
        saveAlerts()
    }
    
    public func clearResolved() {
        withAnimation {
            alerts.removeAll { $0.isResolved }
        }
        saveAlerts()
    }
    
    private func saveAlerts() {
        let list = self.alerts
        let url = self.storageURL
        Task.detached(priority: .background) {
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
    
    private func loadAlerts() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([SystemAlert].self, from: data) else {
            return
        }
        self.alerts = list
    }
    
    private func seedSampleAlerts() {
        let sample1 = SystemAlert(
            type: .highCPU,
            severity: .warning,
            title: "Sustained High CPU Usage",
            message: "Xcode / swift-frontend triggered high processor load during workspace compilation.",
            culpritAppName: "Xcode",
            culpritPID: 1240,
            metricValue: "92.4% CPU",
            timestamp: Date().addingTimeInterval(-1800),
            isResolved: true,
            resolvedAt: Date().addingTimeInterval(-1200)
        )
        let sample2 = SystemAlert(
            type: .swapThrashing,
            severity: .info,
            title: "Elevated Swap Usage",
            message: "System allocated 1.8 GB swap memory while multiple IDE instances were open.",
            culpritAppName: "Cursor",
            culpritPID: 4321,
            metricValue: "1.8 GB Swap",
            timestamp: Date().addingTimeInterval(-7200),
            isResolved: true,
            resolvedAt: Date().addingTimeInterval(-5400)
        )
        self.alerts = [sample1, sample2]
    }
}
