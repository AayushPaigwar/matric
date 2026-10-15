import Foundation

public struct HardwareInfo: Sendable {
    public let chipName: String
    public let modelIdentifier: String
    public let coreCount: Int
    public let ramGB: Int
    public let totalMemoryBytes: UInt64
    
    public static func current() -> HardwareInfo {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        let brand: String
        if size > 0 {
            var machine = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
            brand = String(cString: machine)
        } else {
            brand = "Apple Silicon"
        }
        
        var modelSize = 0
        sysctlbyname("hw.model", nil, &modelSize, nil, 0)
        let model: String
        if modelSize > 0 {
            var modelChars = [CChar](repeating: 0, count: modelSize)
            sysctlbyname("hw.model", &modelChars, &modelSize, nil, 0)
            model = String(cString: modelChars)
        } else {
            model = "Mac"
        }
        
        let cores = ProcessInfo.processInfo.processorCount
        let physicalMem = ProcessInfo.processInfo.physicalMemory
        let ram = Int(physicalMem / (1024 * 1024 * 1024))
        
        return HardwareInfo(
            chipName: brand.isEmpty ? "Apple Silicon" : brand,
            modelIdentifier: model,
            coreCount: cores,
            ramGB: ram,
            totalMemoryBytes: physicalMem
        )
    }
}
