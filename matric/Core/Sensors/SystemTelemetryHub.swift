import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class SystemTelemetryHub {
    public static let shared = SystemTelemetryHub()
    
    // Core telemetry models
    public var cpu: CPUSample = .zero
    public var memory: MemorySample = .zero
    public var disk: DiskSample = .zero
    public var network: NetworkSample = .zero
    public var gpu: GPUSample = .zero
    public var battery: BatterySample = .zero
    
    // Process trees
    public var appGroups: [AppGroupRecord] = []
    
    // Rolling historical buffers (last 60 seconds)
    public var cpuHistory: [CPUSample] = []
    public var memoryHistory: [MemorySample] = []
    public var diskHistory: [DiskSample] = []
    public var networkHistory: [NetworkSample] = []
    public var gpuHistory: [GPUSample] = []
    public var batteryHistory: [BatterySample] = []
    
    // Monitors
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let gpuMonitor = GPUMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let processScanner = ProcessScanner()
    private let treeResolver = ProcessTreeResolver()
    
    private var timer: Timer?
    private let maxHistoryPoints: Int = 60
    
    public init() {
        start()
    }
    
    public func start() {
        startMonitoring(interval: 1.0)
    }
    
    public func startMonitoring(interval: Double = 1.0) {
        stop()
        refreshAll()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAll()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
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
        
        // Update live resource metrics for active dev projects
        ProjectsManager.shared.updateVitals(with: rawProcesses)
        
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
