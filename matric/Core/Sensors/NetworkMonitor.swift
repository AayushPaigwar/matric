import Foundation
import Darwin

public struct NetworkInterfaceInfo: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let isPhysical: Bool
    public let downloadBytesPerSec: Double
    public let uploadBytesPerSec: Double
    public let totalRxBytes: UInt64
    public let totalTxBytes: UInt64
    
    public init(
        name: String,
        isPhysical: Bool,
        downloadBytesPerSec: Double,
        uploadBytesPerSec: Double,
        totalRxBytes: UInt64,
        totalTxBytes: UInt64
    ) {
        self.name = name
        self.isPhysical = isPhysical
        self.downloadBytesPerSec = downloadBytesPerSec
        self.uploadBytesPerSec = uploadBytesPerSec
        self.totalRxBytes = totalRxBytes
        self.totalTxBytes = totalTxBytes
    }
}

public struct NetworkSample: Sendable {
    public let totalDownloadBps: Double
    public let totalUploadBps: Double
    public let interfaces: [NetworkInterfaceInfo]
    public let timestamp: Date
    
    public init(
        totalDownloadBps: Double,
        totalUploadBps: Double,
        interfaces: [NetworkInterfaceInfo],
        timestamp: Date = Date()
    ) {
        self.totalDownloadBps = totalDownloadBps
        self.totalUploadBps = totalUploadBps
        self.interfaces = interfaces
        self.timestamp = timestamp
    }
    
    public static var zero: NetworkSample {
        NetworkSample(
            totalDownloadBps: 0,
            totalUploadBps: 0,
            interfaces: []
        )
    }
}

public final class NetworkMonitor {
    private var previousData: [String: (rx: UInt64, tx: UInt64, time: Date)] = [:]
    
    public init() {}
    
    public func sample() -> NetworkSample {
        let now = Date()
        var currentSnapshots: [String: (rx: UInt64, tx: UInt64)] = [:]
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while let cur = ptr {
                let name = String(cString: cur.pointee.ifa_name)
                if cur.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
                   let data = cur.pointee.ifa_data {
                    let d = data.assumingMemoryBound(to: if_data.self)
                    let rx = UInt64(d.pointee.ifi_ibytes)
                    let tx = UInt64(d.pointee.ifi_obytes)
                    currentSnapshots[name] = (rx: rx, tx: tx)
                }
                ptr = cur.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        
        var interfaceResults: [NetworkInterfaceInfo] = []
        var totalDown: Double = 0
        var totalUp: Double = 0
        
        for (name, current) in currentSnapshots {
            let isPhysical = name.hasPrefix("en") && !name.contains("bridge")
            var downRate: Double = 0
            var upRate: Double = 0
            
            if let prev = previousData[name] {
                let elapsed = now.timeIntervalSince(prev.time)
                if elapsed > 0.1 {
                    let deltaRx = current.rx >= prev.rx ? current.rx - prev.rx : 0
                    let deltaTx = current.tx >= prev.tx ? current.tx - prev.tx : 0
                    downRate = Double(deltaRx) / elapsed
                    upRate = Double(deltaTx) / elapsed
                }
            }
            
            if !name.hasPrefix("lo") {
                totalDown += downRate
                totalUp += upRate
            }
            
            interfaceResults.append(
                NetworkInterfaceInfo(
                    name: name,
                    isPhysical: isPhysical,
                    downloadBytesPerSec: downRate,
                    uploadBytesPerSec: upRate,
                    totalRxBytes: current.rx,
                    totalTxBytes: current.tx
                )
            )
            
            previousData[name] = (rx: current.rx, tx: current.tx, time: now)
        }
        
        // Sort: physical first, then alphabetical
        interfaceResults.sort {
            if $0.isPhysical != $1.isPhysical {
                return $0.isPhysical && !$1.isPhysical
            }
            return $0.name < $1.name
        }
        
        return NetworkSample(
            totalDownloadBps: max(totalDown, 0),
            totalUploadBps: max(totalUp, 0),
            interfaces: interfaceResults,
            timestamp: now
        )
    }
}
