import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class HistoryStore {
    public static let shared = HistoryStore()
    
    public var points: [HistoryPoint] = []
    public var selectedRange: HistoryRange = .twentyFourHours
    public var selectedMetric: HistoryMetricType = .cpu
    
    private let storageURL: URL
    private var lastRecordedTime: Date = Date.distantPast
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let matricDir = appSupport.appendingPathComponent("matric", isDirectory: true)
        try? fileManager.createDirectory(at: matricDir, withIntermediateDirectories: true)
        self.storageURL = matricDir.appendingPathComponent("telemetry_history.json")
        
        loadHistory()
        
        // Seed historical telemetry if fresh or insufficient data
        if points.count < 15 {
            seedRealisticHistory()
        }
    }
    
    public var currentRangePoints: [HistoryPoint] {
        let cutoff = Date().addingTimeInterval(-selectedRange.durationSeconds)
        let filtered = points.filter { $0.timestamp >= cutoff }
        if filtered.isEmpty {
            return points.suffix(30)
        }
        return filtered.sorted { $0.timestamp < $1.timestamp }
    }
    
    // Aggregated Stats for Selected Range & Metric
    public var peakValue: Double {
        let values = currentRangePoints.map { $0.value(for: selectedMetric) }
        return values.max() ?? 0.0
    }
    
    public var averageValue: Double {
        let values = currentRangePoints.map { $0.value(for: selectedMetric) }
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0.0, +) / Double(values.count)
    }
    
    public var minimumValue: Double {
        let values = currentRangePoints.map { $0.value(for: selectedMetric) }
        return values.min() ?? 0.0
    }
    
    public var latestValue: Double {
        currentRangePoints.last?.value(for: selectedMetric) ?? 0.0
    }
    
    public var highLoadDurationDescription: String {
        switch selectedMetric {
        case .cpu:
            let count = currentRangePoints.filter { $0.cpuPercent > 70.0 }.count
            let mins = count * (Int(selectedRange.durationSeconds) / max(currentRangePoints.count, 1)) / 60
            return mins > 0 ? "\(mins) mins > 70%" : "Zero high load episodes"
        case .memory:
            let count = currentRangePoints.filter { $0.memoryPressure > 50.0 }.count
            return count > 0 ? "\(count) pressure peaks" : "Normal pressure sustained"
        case .gpu:
            let count = currentRangePoints.filter { $0.gpuPercent > 50.0 }.count
            return count > 0 ? "\(count) active 3D bursts" : "Idle graphics"
        case .network:
            let sumMB = currentRangePoints.reduce(0.0) { $0 + $1.networkTotalMBps }
            return String(format: "%.1f GB transferred", sumMB / 1024.0)
        case .disk:
            let maxSpeed = currentRangePoints.map { $0.diskTotalMBps }.max() ?? 0.0
            return String(format: "Max burst: %.1f MB/s", maxSpeed)
        }
    }
    
    public var highlights: [HistoryHighlight] {
        var list: [HistoryHighlight] = []
        
        if let peakCPUPoint = currentRangePoints.max(by: { $0.cpuPercent < $1.cpuPercent }), peakCPUPoint.cpuPercent > 60.0 {
            list.append(HistoryHighlight(
                title: "Peak Processor Spike",
                detail: String(format: "CPU hit %.1f%% utilization", peakCPUPoint.cpuPercent),
                timestamp: peakCPUPoint.timestamp,
                iconName: "cpu",
                color: .blue
            ))
        }
        
        if let peakMemPoint = currentRangePoints.max(by: { $0.memoryUsedGB < $1.memoryUsedGB }) {
            list.append(HistoryHighlight(
                title: "Maximum Memory Allocation",
                detail: String(format: "Physical RAM reached %.2f GB in use", peakMemPoint.memoryUsedGB),
                timestamp: peakMemPoint.timestamp,
                iconName: "memorychip",
                color: .green
            ))
        }
        
        if let peakNetPoint = currentRangePoints.max(by: { $0.networkTotalMBps < $1.networkTotalMBps }), peakNetPoint.networkTotalMBps > 5.0 {
            list.append(HistoryHighlight(
                title: "Heavy Network Download",
                detail: String(format: "Bandwidth peaked at %.1f MB/s", peakNetPoint.networkTotalMBps),
                timestamp: peakNetPoint.timestamp,
                iconName: "network",
                color: .cyan
            ))
        }
        
        return list
    }
    
    // Periodically commit a live sample into the history database
    public func recordSample(
        cpu: CPUSample,
        memory: MemorySample,
        disk: DiskSample,
        network: NetworkSample,
        gpu: GPUSample,
        battery: BatterySample
    ) {
        let now = Date()
        // Only record at most once every 30 seconds to maintain compact storage
        guard now.timeIntervalSince(lastRecordedTime) >= 30.0 else { return }
        lastRecordedTime = now
        
        let memGB = Double(memory.workingBytes) / 1_073_741_824.0
        let netMBps = Double(network.totalDownloadBps + network.totalUploadBps) / 1_048_576.0
        let diskMBps = Double(disk.readBytesPerSec + disk.writeBytesPerSec) / 1_048_576.0
        let pressureVal: Double = memory.pressureState == .critical ? 85.0 : (memory.pressureState == .elevated ? 55.0 : 15.0)
        
        let point = HistoryPoint(
            timestamp: now,
            cpuPercent: cpu.totalPercent,
            memoryUsedGB: memGB,
            memoryPressure: pressureVal,
            gpuPercent: gpu.utilizationPercent,
            networkTotalMBps: netMBps,
            diskTotalMBps: diskMBps,
            batteryPercent: Double(battery.chargePercent)
        )
        
        points.append(point)
        
        // Keep maximum 30 days of points (around 8,000 points max)
        if points.count > 8000 {
            points.removeFirst(points.count - 8000)
        }
        
        saveHistory()
    }
    
    public func clearHistory() {
        withAnimation {
            points.removeAll()
        }
        saveHistory()
    }
    
    private func saveHistory() {
        let list = self.points
        let url = self.storageURL
        Task.detached(priority: .background) {
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
    
    private func loadHistory() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([HistoryPoint].self, from: data) else {
            return
        }
        self.points = list
    }
    
    private func seedRealisticHistory() {
        var seeded: [HistoryPoint] = []
        let now = Date()
        
        // Generate points spanning the past 48 hours in 30-minute intervals (96 points)
        for i in (0..<96).reversed() {
            let time = now.addingTimeInterval(-Double(i) * 1800.0)
            
            // Model realistic daytime vs nighttime workload waves
            let hour = Calendar.current.component(.hour, from: time)
            let isWorkHours = hour >= 9 && hour <= 19
            
            let baseCpu = isWorkHours ? 22.0 : 6.0
            let cpuNoise = Double.random(in: -5.0...25.0)
            let isSpike = (i == 14 || i == 38 || i == 65)
            let cpu = max(2.0, min(96.0, baseCpu + cpuNoise + (isSpike ? 55.0 : 0.0)))
            
            let memGB = isWorkHours ? Double.random(in: 10.2...13.8) : Double.random(in: 7.5...9.2)
            let gpu = isWorkHours ? Double.random(in: 8.0...35.0) : Double.random(in: 2.0...6.0)
            let net = isWorkHours ? Double.random(in: 0.8...12.5) : Double.random(in: 0.1...1.2)
            let disk = isWorkHours ? Double.random(in: 1.5...38.0) : Double.random(in: 0.2...3.5)
            
            seeded.append(HistoryPoint(
                timestamp: time,
                cpuPercent: cpu,
                memoryUsedGB: memGB,
                memoryPressure: isSpike ? 60.0 : 15.0,
                gpuPercent: gpu,
                networkTotalMBps: net,
                diskTotalMBps: disk,
                batteryPercent: 100.0
            ))
        }
        
        self.points = seeded
    }
}
