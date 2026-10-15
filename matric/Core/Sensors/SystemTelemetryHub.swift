import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class SystemTelemetryHub {
    public static let shared = SystemTelemetryHub()
    
    // Live sensor state
    public var cpu: CPUSample = .zero
    public var memory: MemorySample = .zero
    public var disk: DiskSample = .zero
    public var network: NetworkSample = .zero
    public var gpu: GPUSample = .zero
    public var battery: BatterySample = .zero
    
    // Live process tree
    public var appGroups: [AppGroupRecord] = []
    
    // Rolling history for live charts (retains last 300 data points = up to 10 mins at 2s interval)
    public var cpuHistory: [CPUSample] = []
    public var memoryHistory: [MemorySample] = []
    public var diskHistory: [DiskSample] = []
    public var networkHistory: [NetworkSample] = []
    public var gpuHistory: [GPUSample] = []
    public var batteryHistory: [BatterySample] = []
    
    public var isMonitoring: Bool = false
    public var refreshInterval: Double = 2.0
    
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let gpuMonitor = GPUMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let processScanner = ProcessScanner()
    private let treeResolver = ProcessTreeResolver()
    
    private var timerTask: Task<Void, Never>?
    private let maxHistoryPoints: Int = 300
    
    public init() {
        // Initial sample
        refreshAll()
    }
    
    public func startMonitoring(interval: Double = 2.0) {
        self.refreshInterval = interval
        self.isMonitoring = true
        
        // Immediate sample on start
        self.refreshAll()
        
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard let self = self, self.isMonitoring else { break }
                self.refreshAll()
            }
        }
    }
    
    public func stopMonitoring() {
        self.isMonitoring = false
        timerTask?.cancel()
        timerTask = nil
    }
    
    public func refreshAll() {
        let newCPU = cpuMonitor.sample()
        let newMemory = memoryMonitor.sample()
        let newDisk = diskMonitor.sample()
        let newNetwork = networkMonitor.sample()
        let newGPU = gpuMonitor.sample()
        let newBattery = batteryMonitor.sample()
        
        // Scan & resolve process hierarchy
        let rawProcesses = processScanner.scan()
        let resolvedApps = treeResolver.resolve(processes: rawProcesses)
        
        self.cpu = newCPU
        self.memory = newMemory
        self.disk = newDisk
        self.network = newNetwork
        self.gpu = newGPU
        self.battery = newBattery
        self.appGroups = resolvedApps
        
        // Append to rolling history
        appendHistory(&cpuHistory, item: newCPU)
        appendHistory(&memoryHistory, item: newMemory)
        appendHistory(&diskHistory, item: newDisk)
        appendHistory(&networkHistory, item: newNetwork)
        appendHistory(&gpuHistory, item: newGPU)
        appendHistory(&batteryHistory, item: newBattery)
        
        // Feed watchdog alert evaluator
        AlertsManager.shared.evaluateTelemetry(
            cpu: newCPU,
            memory: newMemory,
            disk: newDisk,
            gpu: newGPU,
            battery: newBattery,
            appGroups: resolvedApps
        )
        
        // Feed long-term historical telemetry store
        HistoryStore.shared.recordSample(
            cpu: newCPU,
            memory: newMemory,
            disk: newDisk,
            network: newNetwork,
            gpu: newGPU,
            battery: newBattery
        )
    }
    
    private func appendHistory<T>(_ array: inout [T], item: T) {
        array.append(item)
        if array.count > maxHistoryPoints {
            array.removeFirst(array.count - maxHistoryPoints)
        }
    }
}
