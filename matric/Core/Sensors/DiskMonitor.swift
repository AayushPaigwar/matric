import Foundation
import IOKit

public struct DiskSample: Sendable {
    public let readBytesPerSec: Double
    public let writeBytesPerSec: Double
    public let totalSpaceBytes: UInt64
    public let freeSpaceBytes: UInt64
    public let usedSpaceBytes: UInt64
    public let volumeName: String
    public let timestamp: Date
    
    public init(
        readBytesPerSec: Double,
        writeBytesPerSec: Double,
        totalSpaceBytes: UInt64,
        freeSpaceBytes: UInt64,
        usedSpaceBytes: UInt64,
        volumeName: String,
        timestamp: Date = Date()
    ) {
        self.readBytesPerSec = readBytesPerSec
        self.writeBytesPerSec = writeBytesPerSec
        self.totalSpaceBytes = totalSpaceBytes
        self.freeSpaceBytes = freeSpaceBytes
        self.usedSpaceBytes = usedSpaceBytes
        self.volumeName = volumeName
        self.timestamp = timestamp
    }
    
    public static var zero: DiskSample {
        DiskSample(
            readBytesPerSec: 0,
            writeBytesPerSec: 0,
            totalSpaceBytes: 0,
            freeSpaceBytes: 0,
            usedSpaceBytes: 0,
            volumeName: "Macintosh HD"
        )
    }
}

public final class DiskMonitor {
    private var previousReadBytes: UInt64 = 0
    private var previousWriteBytes: UInt64 = 0
    private var previousTimestamp: Date?
    
    public init() {}
    
    public func sample() -> DiskSample {
        let now = Date()
        var currentReadBytes: UInt64 = 0
        var currentWriteBytes: UInt64 = 0
        
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOBlockStorageDriver")
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if kr == KERN_SUCCESS {
            var entry = IOIteratorNext(iterator)
            while entry != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = properties?.takeRetainedValue() as? [String: Any],
                   let stats = dict["Statistics"] as? [String: Any] {
                    if let r = stats["Bytes (Read)"] as? UInt64 {
                        currentReadBytes += r
                    }
                    if let w = stats["Bytes (Write)"] as? UInt64 {
                        currentWriteBytes += w
                    }
                }
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        var readSpeed: Double = 0
        var writeSpeed: Double = 0
        
        if let prevTime = previousTimestamp, previousReadBytes > 0 || previousWriteBytes > 0 {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0.1 {
                let deltaRead = currentReadBytes >= previousReadBytes ? currentReadBytes - previousReadBytes : 0
                let deltaWrite = currentWriteBytes >= previousWriteBytes ? currentWriteBytes - previousWriteBytes : 0
                readSpeed = Double(deltaRead) / elapsed
                writeSpeed = Double(deltaWrite) / elapsed
            }
        }
        
        previousReadBytes = currentReadBytes
        previousWriteBytes = currentWriteBytes
        previousTimestamp = now
        
        // Storage capacity for root volume
        var totalSpace: UInt64 = 0
        var freeSpace: UInt64 = 0
        var volName = "Macintosh HD"
        
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            if let total = attrs[.systemSize] as? NSNumber {
                totalSpace = total.uint64Value
            }
            if let free = attrs[.systemFreeSize] as? NSNumber {
                freeSpace = free.uint64Value
            }
        }
        
        let rootURL = URL(fileURLWithPath: "/")
        if let resourceValues = try? rootURL.resourceValues(forKeys: [.volumeLocalizedNameKey]),
           let name = resourceValues.volumeLocalizedName {
            volName = name
        }
        
        let usedSpace = totalSpace >= freeSpace ? totalSpace - freeSpace : 0
        
        return DiskSample(
            readBytesPerSec: max(readSpeed, 0),
            writeBytesPerSec: max(writeSpeed, 0),
            totalSpaceBytes: totalSpace,
            freeSpaceBytes: freeSpace,
            usedSpaceBytes: usedSpace,
            volumeName: volName,
            timestamp: now
        )
    }
}
