import Foundation
import Darwin
import AppKit

public final class ProcessScanner {
    private var previousCpuData: [pid_t: (nanos: UInt64, time: Date)] = [:]
    
    public init() {}
    
    public func scan() -> [ProcessRecord] {
        let now = Date()
        let pidsCapacity = 4096
        var pids = [pid_t](repeating: 0, count: pidsCapacity)
        let bytesUsed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pidsCapacity * MemoryLayout<pid_t>.size))
        
        guard bytesUsed > 0 else { return [] }
        let count = Int(bytesUsed) / MemoryLayout<pid_t>.size
        
        var records: [ProcessRecord] = []
        records.reserveCapacity(count)
        
        var currentCpuData: [pid_t: (nanos: UInt64, time: Date)] = [:]
        currentCpuData.reserveCapacity(count)
        
        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }
            
            var allInfo = proc_taskallinfo()
            let infoSize = Int32(MemoryLayout<proc_taskallinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &allInfo, infoSize)
            guard result == infoSize else { continue }
            
            // Process BSD Name
            let name = withUnsafePointer(to: &allInfo.pbsd.pbi_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: 32) { String(cString: $0) }
            }
            let ppid = pid_t(allInfo.pbsd.pbi_ppid)
            let residentBytes = allInfo.ptinfo.pti_resident_size
            let totalCpuNanos = allInfo.ptinfo.pti_total_user + allInfo.ptinfo.pti_total_system
            let totalCpuSeconds = Double(totalCpuNanos) / 1_000_000_000.0
            
            // Compute delta CPU usage
            var cpuPercent = 0.0
            if let prev = previousCpuData[pid] {
                let timeDelta = now.timeIntervalSince(prev.time)
                if timeDelta > 0.001 && totalCpuNanos >= prev.nanos {
                    let nanosDelta = totalCpuNanos - prev.nanos
                    let cpuSeconds = Double(nanosDelta) / 1_000_000_000.0
                    cpuPercent = (cpuSeconds / timeDelta) * 100.0
                }
            }
            currentCpuData[pid] = (nanos: totalCpuNanos, time: now)
            
            // Executable path
            var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            let pathLen = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
            let execPath = pathLen > 0 ? String(cString: pathBuffer) : ""
            
            // Bundle Path detection
            var bundlePath: String? = nil
            if let range = execPath.range(of: ".app/") {
                bundlePath = String(execPath[...range.lowerBound]) + "app"
            }
            
            let record = ProcessRecord(
                pid: pid,
                ppid: ppid,
                name: name,
                executablePath: execPath,
                bundlePath: bundlePath,
                cpuPercent: cpuPercent,
                memoryBytes: residentBytes,
                cpuTimeSeconds: totalCpuSeconds
            )
            records.append(record)
        }
        
        self.previousCpuData = currentCpuData
        return records
    }
}
