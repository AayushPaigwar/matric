import Foundation
import AppKit

public struct ProcessRecord: Identifiable, Sendable {
    public var id: pid_t { pid }
    public let pid: pid_t
    public let ppid: pid_t
    public let name: String
    public let executablePath: String
    public let bundlePath: String?
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    public let cpuTimeSeconds: Double
    
    public init(
        pid: pid_t,
        ppid: pid_t,
        name: String,
        executablePath: String,
        bundlePath: String?,
        cpuPercent: Double,
        memoryBytes: UInt64,
        cpuTimeSeconds: Double
    ) {
        self.pid = pid
        self.ppid = ppid
        self.name = name
        self.executablePath = executablePath
        self.bundlePath = bundlePath
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.cpuTimeSeconds = cpuTimeSeconds
    }
}

public struct AppGroupRecord: Identifiable {
    public let id: String
    public let name: String
    public let bundleURL: URL?
    public let bundleIdentifier: String?
    public let icon: NSImage?
    public let rootPid: pid_t
    public let isAppBundle: Bool
    public var processes: [ProcessRecord]
    
    public init(
        id: String,
        name: String,
        bundleURL: URL?,
        bundleIdentifier: String?,
        icon: NSImage?,
        rootPid: pid_t,
        isAppBundle: Bool,
        processes: [ProcessRecord] = []
    ) {
        self.id = id
        self.name = name
        self.bundleURL = bundleURL
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
        self.rootPid = rootPid
        self.isAppBundle = isAppBundle
        self.processes = processes
    }
    
    public var totalCpuPercent: Double {
        processes.reduce(0.0) { $0 + $1.cpuPercent }
    }
    
    public var totalMemoryBytes: UInt64 {
        processes.reduce(0) { $0 + $1.memoryBytes }
    }
    
    public var processCount: Int {
        processes.count
    }
    
    public var formattedMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(totalMemoryBytes))
    }
    
    public var formattedCpu: String {
        String(format: "%.1f%%", totalCpuPercent)
    }
}
