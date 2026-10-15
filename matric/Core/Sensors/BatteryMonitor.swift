import Foundation
import IOKit
import IOKit.ps

public struct ConnectedAccessory: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let batteryPercent: Int
    
    public init(name: String, batteryPercent: Int) {
        self.name = name
        self.batteryPercent = batteryPercent
    }
}

public struct BatterySample: Sendable {
    public let hasBattery: Bool
    public let chargePercent: Int
    public let isCharging: Bool
    public let powerSourceState: String
    public let currentWatts: Double
    public let cycleCount: Int
    public let healthPercent: Int
    public let timeRemainingMinutes: Int?
    public let accessories: [ConnectedAccessory]
    public let timestamp: Date
    
    public init(
        hasBattery: Bool,
        chargePercent: Int,
        isCharging: Bool,
        powerSourceState: String,
        currentWatts: Double,
        cycleCount: Int,
        healthPercent: Int,
        timeRemainingMinutes: Int?,
        accessories: [ConnectedAccessory] = [],
        timestamp: Date = Date()
    ) {
        self.hasBattery = hasBattery
        self.chargePercent = chargePercent
        self.isCharging = isCharging
        self.powerSourceState = powerSourceState
        self.currentWatts = currentWatts
        self.cycleCount = cycleCount
        self.healthPercent = healthPercent
        self.timeRemainingMinutes = timeRemainingMinutes
        self.accessories = accessories
        self.timestamp = timestamp
    }
    
    public static var zero: BatterySample {
        BatterySample(
            hasBattery: false,
            chargePercent: 100,
            isCharging: false,
            powerSourceState: "AC Power",
            currentWatts: 0,
            cycleCount: 0,
            healthPercent: 100,
            timeRemainingMinutes: nil
        )
    }
}

public final class BatteryMonitor {
    public init() {}
    
    public func sample() -> BatterySample {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        
        guard !sources.isEmpty else {
            return BatterySample.zero
        }
        
        var chargePct = 0
        var isCharging = false
        var powerState = "AC Power"
        var timeRemaining: Int? = nil
        var hasInternalBattery = false
        
        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                if let type = desc[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                    hasInternalBattery = true
                    if let cur = desc[kIOPSCurrentCapacityKey] as? Int {
                        chargePct = cur
                    }
                    if let charging = desc[kIOPSIsChargingKey] as? Bool {
                        isCharging = charging
                    }
                    if let state = desc[kIOPSPowerSourceStateKey] as? String {
                        powerState = state
                    }
                    if let time = desc[kIOPSTimeToEmptyKey] as? Int, time > 0 {
                        timeRemaining = time
                    }
                }
            }
        }
        
        guard hasInternalBattery else {
            return BatterySample.zero
        }
        
        // Query AppleSmartBattery for Hardware details: Cycles, Voltage, Amperage
        var cycleCount = 0
        var healthPct = 100
        var watts: Double = 0
        
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AppleSmartBattery")
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if kr == KERN_SUCCESS {
            let entry = IOIteratorNext(iterator)
            if entry != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = properties?.takeRetainedValue() as? [String: Any] {
                    
                    if let cycles = dict["CycleCount"] as? Int {
                        cycleCount = cycles
                    }
                    
                    if let maxCap = dict["MaxCapacity"] as? Int {
                        healthPct = min(maxCap, 100)
                    }
                    
                    var voltageMV: Double = 0
                    var amperageMA: Double = 0
                    
                    if let v = dict["Voltage"] as? Double { voltageMV = v }
                    else if let v = dict["Voltage"] as? Int { voltageMV = Double(v) }
                    
                    if let a = dict["InstantAmperage"] as? Double { amperageMA = a }
                    else if let a = dict["InstantAmperage"] as? Int { amperageMA = Double(a) }
                    else if let a = dict["Amperage"] as? Double { amperageMA = a }
                    else if let a = dict["Amperage"] as? Int { amperageMA = Double(a) }
                    
                    let volts = voltageMV / 1000.0
                    let amps = abs(amperageMA) / 1000.0
                    watts = volts * amps
                }
                IOObjectRelease(entry)
            }
            IOObjectRelease(iterator)
        }
        
        return BatterySample(
            hasBattery: true,
            chargePercent: chargePct,
            isCharging: isCharging,
            powerSourceState: powerState,
            currentWatts: watts,
            cycleCount: cycleCount,
            healthPercent: healthPct,
            timeRemainingMinutes: timeRemaining,
            accessories: [],
            timestamp: Date()
        )
    }
}
