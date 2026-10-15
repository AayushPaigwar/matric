import Foundation
import Darwin

public enum MemoryPressureState: String, Sendable, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case critical = "Critical"
}

public struct MemorySample: Sendable {
    public let totalBytes: UInt64
    public let activeBytes: UInt64
    public let inactiveBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    public let freeBytes: UInt64
    public let swapUsedBytes: UInt64
    public let swapTotalBytes: UInt64
    public let pressureState: MemoryPressureState
    public let timestamp: Date
    
    public init(
        totalBytes: UInt64,
        activeBytes: UInt64,
        inactiveBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        freeBytes: UInt64,
        swapUsedBytes: UInt64,
        swapTotalBytes: UInt64,
        pressureState: MemoryPressureState,
        timestamp: Date = Date()
    ) {
        self.totalBytes = totalBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.freeBytes = freeBytes
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
        self.pressureState = pressureState
        self.timestamp = timestamp
    }
    
    public var workingBytes: UInt64 {
        activeBytes + wiredBytes + compressedBytes
    }
    
    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return (Double(workingBytes) / Double(totalBytes)) * 100.0
    }
    
    public static var zero: MemorySample {
        MemorySample(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            activeBytes: 0,
            inactiveBytes: 0,
            wiredBytes: 0,
            compressedBytes: 0,
            freeBytes: ProcessInfo.processInfo.physicalMemory,
            swapUsedBytes: 0,
            swapTotalBytes: 0,
            pressureState: .normal
        )
    }
}

public final class MemoryMonitor {
    public init() {}
    
    public func sample() -> MemorySample {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemorySample.zero
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(vmStats.active_count) * pageSize
        let inactive = UInt64(vmStats.inactive_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        
        // Swap usage via sysctl
        var mib = [CTL_VM, VM_SWAPUSAGE]
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapUsed: UInt64 = 0
        var swapTotal: UInt64 = 0
        
        if sysctl(&mib, 2, &swapUsage, &swapSize, nil, 0) == 0 {
            swapUsed = UInt64(swapUsage.xsu_used)
            swapTotal = UInt64(swapUsage.xsu_total)
        }
        
        // Determine memory pressure state
        let working = active + wired + compressed
        let pressure: MemoryPressureState
        let ratio = totalBytes > 0 ? Double(working) / Double(totalBytes) : 0
        
        if ratio > 0.92 || swapUsed > 2 * 1024 * 1024 * 1024 {
            pressure = .critical
        } else if ratio > 0.80 || swapUsed > 500 * 1024 * 1024 {
            pressure = .elevated
        } else {
            pressure = .normal
        }
        
        return MemorySample(
            totalBytes: totalBytes,
            activeBytes: active,
            inactiveBytes: inactive,
            wiredBytes: wired,
            compressedBytes: compressed,
            freeBytes: free,
            swapUsedBytes: swapUsed,
            swapTotalBytes: swapTotal,
            pressureState: pressure
        )
    }
}
