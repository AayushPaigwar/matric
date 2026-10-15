import Foundation
import IOKit

public enum ThermalState: String, Sendable, CaseIterable {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"
    
    public static func from(processInfoState: ProcessInfo.ThermalState) -> ThermalState {
        switch processInfoState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }
}

public struct GPUSample: Sendable {
    public let utilizationPercent: Double
    public let driverAllocatedMemoryBytes: UInt64
    public let thermalState: ThermalState
    public let chipModel: String
    public let timestamp: Date
    
    public init(
        utilizationPercent: Double,
        driverAllocatedMemoryBytes: UInt64,
        thermalState: ThermalState,
        chipModel: String,
        timestamp: Date = Date()
    ) {
        self.utilizationPercent = utilizationPercent
        self.driverAllocatedMemoryBytes = driverAllocatedMemoryBytes
        self.thermalState = thermalState
        self.chipModel = chipModel
        self.timestamp = timestamp
    }
    
    public static var zero: GPUSample {
        GPUSample(
            utilizationPercent: 0,
            driverAllocatedMemoryBytes: 0,
            thermalState: .nominal,
            chipModel: "Apple Silicon"
        )
    }
}

public final class GPUMonitor {
    private let chipModel: String
    
    public init() {
        self.chipModel = HardwareInfo.current().chipName
    }
    
    public func sample() -> GPUSample {
        var gpuPercent: Double = 0
        var allocMemory: UInt64 = 0
        
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if kr == KERN_SUCCESS {
            var entry = IOIteratorNext(iterator)
            while entry != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = properties?.takeRetainedValue() as? [String: Any],
                   let perf = dict["PerformanceStatistics"] as? [String: Any] {
                    
                    if let util = perf["Device Utilization %"] as? Double {
                        gpuPercent = max(gpuPercent, util)
                    } else if let util = perf["Device Utilization %"] as? Int {
                        gpuPercent = max(gpuPercent, Double(util))
                    }
                    
                    if let mem = perf["In use system memory"] as? UInt64 {
                        allocMemory = max(allocMemory, mem)
                    } else if let mem = perf["Alloc system memory"] as? UInt64 {
                        allocMemory = max(allocMemory, mem)
                    }
                }
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        let thermal = ThermalState.from(processInfoState: ProcessInfo.processInfo.thermalState)
        
        return GPUSample(
            utilizationPercent: min(max(gpuPercent, 0), 100),
            driverAllocatedMemoryBytes: allocMemory,
            thermalState: thermal,
            chipModel: chipModel,
            timestamp: Date()
        )
    }
}
