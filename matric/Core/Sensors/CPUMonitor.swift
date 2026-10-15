import Foundation
import Darwin

public struct CPUSample: Sendable {
    public let totalPercent: Double
    public let userPercent: Double
    public let systemPercent: Double
    public let idlePercent: Double
    public let corePercentages: [Double]
    public let loadAverage1Min: Double
    public let loadAverage5Min: Double
    public let loadAverage15Min: Double
    public let timestamp: Date
    
    public init(
        totalPercent: Double,
        userPercent: Double,
        systemPercent: Double,
        idlePercent: Double,
        corePercentages: [Double],
        loadAverage1Min: Double,
        loadAverage5Min: Double,
        loadAverage15Min: Double,
        timestamp: Date = Date()
    ) {
        self.totalPercent = totalPercent
        self.userPercent = userPercent
        self.systemPercent = systemPercent
        self.idlePercent = idlePercent
        self.corePercentages = corePercentages
        self.loadAverage1Min = loadAverage1Min
        self.loadAverage5Min = loadAverage5Min
        self.loadAverage15Min = loadAverage15Min
        self.timestamp = timestamp
    }
    
    public static var zero: CPUSample {
        CPUSample(
            totalPercent: 0,
            userPercent: 0,
            systemPercent: 0,
            idlePercent: 100,
            corePercentages: [],
            loadAverage1Min: 0,
            loadAverage5Min: 0,
            loadAverage15Min: 0
        )
    }
}

public final class CPUMonitor {
    private var previousCoreTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
    
    public init() {}
    
    public func sample() -> CPUSample {
        var numProcessors: natural_t = 0
        var processorInfo: processor_info_array_t?
        var processorInfoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numProcessors,
            &processorInfo,
            &processorInfoCount
        )
        
        guard result == KERN_SUCCESS, let info = processorInfo else {
            return CPUSample.zero
        }
        
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(processorInfoCount * UInt32(MemoryLayout<integer_t>.size))
            )
        }
        
        let cpuLoadArray = info.withMemoryRebound(
            to: processor_cpu_load_info_data_t.self,
            capacity: Int(numProcessors)
        ) { pointer in
            Array(UnsafeBufferPointer(start: pointer, count: Int(numProcessors)))
        }
        
        var currentTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        for load in cpuLoadArray {
            let u = UInt64(load.cpu_ticks.0)
            let s = UInt64(load.cpu_ticks.1)
            let i = UInt64(load.cpu_ticks.2)
            let n = UInt64(load.cpu_ticks.3)
            currentTicks.append((user: u, system: s, idle: i, nice: n))
        }
        
        var corePercentages: [Double] = []
        var totalUserDelta: UInt64 = 0
        var totalSystemDelta: UInt64 = 0
        var totalIdleDelta: UInt64 = 0
        
        if previousCoreTicks.count == currentTicks.count {
            for idx in 0..<currentTicks.count {
                let prev = previousCoreTicks[idx]
                let curr = currentTicks[idx]
                
                let deltaUser = curr.user >= prev.user ? curr.user - prev.user : 0
                let deltaSystem = curr.system >= prev.system ? curr.system - prev.system : 0
                let deltaIdle = curr.idle >= prev.idle ? curr.idle - prev.idle : 0
                let deltaNice = curr.nice >= prev.nice ? curr.nice - prev.nice : 0
                
                let active = deltaUser + deltaSystem + deltaNice
                let total = active + deltaIdle
                
                totalUserDelta += deltaUser + deltaNice
                totalSystemDelta += deltaSystem
                totalIdleDelta += deltaIdle
                
                let pct = total > 0 ? (Double(active) / Double(total)) * 100.0 : 0.0
                corePercentages.append(min(max(pct, 0.0), 100.0))
            }
        } else {
            // First run, populate with 0
            corePercentages = Array(repeating: 0.0, count: currentTicks.count)
        }
        
        previousCoreTicks = currentTicks
        
        let grandTotal = totalUserDelta + totalSystemDelta + totalIdleDelta
        let userPercent = grandTotal > 0 ? (Double(totalUserDelta) / Double(grandTotal)) * 100.0 : 0.0
        let systemPercent = grandTotal > 0 ? (Double(totalSystemDelta) / Double(grandTotal)) * 100.0 : 0.0
        let idlePercent = grandTotal > 0 ? (Double(totalIdleDelta) / Double(grandTotal)) * 100.0 : 100.0
        let totalPercent = userPercent + systemPercent
        
        var loadavg = [Double](repeating: 0.0, count: 3)
        getloadavg(&loadavg, 3)
        
        return CPUSample(
            totalPercent: min(max(totalPercent, 0.0), 100.0),
            userPercent: min(max(userPercent, 0.0), 100.0),
            systemPercent: min(max(systemPercent, 0.0), 100.0),
            idlePercent: min(max(idlePercent, 0.0), 100.0),
            corePercentages: corePercentages,
            loadAverage1Min: max(loadavg[0], 0.0),
            loadAverage5Min: max(loadavg[1], 0.0),
            loadAverage15Min: max(loadavg[2], 0.0)
        )
    }
}
