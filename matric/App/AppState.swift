import SwiftUI
import Observation
import ServiceManagement

public enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case celsius = "Celsius (°C)"
    case fahrenheit = "Fahrenheit (°F)"
    
    public var id: String { rawValue }
    
    public var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

public enum MenuBarDisplayMode: String, CaseIterable, Identifiable, Codable {
    case iconAndCpu = "Icon + CPU %"
    case iconOnly = "Icon Only"
    case cpuOnly = "CPU % Only"
    case iconCpuRam = "Icon + CPU + RAM"
    
    public var id: String { rawValue }
}

@Observable
@MainActor
public final class AppState {
    public var selectedItem: NavigationItem = .overview
    public var isLive: Bool = true
    public var refreshInterval: Double = 2.0
    public var hardwareInfo: HardwareInfo = HardwareInfo.current()
    public var searchQuery: String = ""
    public var statusNote: String? = nil
    
    // Preferences
    public var temperatureUnit: TemperatureUnit = .celsius
    public var menuBarMode: MenuBarDisplayMode = .iconAndCpu
    public var launchAtLogin: Bool = false
    public var hudOpacity: Double = 0.85
    public var confirmBeforeCleanup: Bool = true
    
    // Process inspector state
    public var inspectedApp: AppGroupRecord? = nil
    
    // Global search focus trigger
    public var searchFocusTrigger: Int = 0
    
    public init() {
        // Load persistent settings
        if let savedInterval = UserDefaults.standard.value(forKey: "matric_refresh_interval") as? Double, savedInterval > 0 {
            self.refreshInterval = savedInterval
        }
        if let tempRaw = UserDefaults.standard.string(forKey: "matric_temp_unit"),
           let unit = TemperatureUnit(rawValue: tempRaw) {
            self.temperatureUnit = unit
        }
        if let barRaw = UserDefaults.standard.string(forKey: "matric_menubar_mode"),
           let mode = MenuBarDisplayMode(rawValue: barRaw) {
            self.menuBarMode = mode
        }
        if UserDefaults.standard.object(forKey: "matric_launch_at_login") != nil {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "matric_launch_at_login")
        }
        if let opacity = UserDefaults.standard.value(forKey: "matric_hud_opacity") as? Double, opacity > 0 {
            self.hudOpacity = opacity
        }
        if UserDefaults.standard.object(forKey: "matric_confirm_cleanup") != nil {
            self.confirmBeforeCleanup = UserDefaults.standard.bool(forKey: "matric_confirm_cleanup")
        }
    }
    
    public func select(_ item: NavigationItem) {
        self.selectedItem = item
    }
    
    public func setRefreshInterval(_ interval: Double) {
        self.refreshInterval = interval
        UserDefaults.standard.set(interval, forKey: "matric_refresh_interval")
        SystemTelemetryHub.shared.startMonitoring(interval: interval)
    }
    
    public func setTemperatureUnit(_ unit: TemperatureUnit) {
        self.temperatureUnit = unit
        UserDefaults.standard.set(unit.rawValue, forKey: "matric_temp_unit")
    }
    
    public func setMenuBarMode(_ mode: MenuBarDisplayMode) {
        self.menuBarMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "matric_menubar_mode")
    }
    
    public func setLaunchAtLogin(_ enabled: Bool) {
        self.launchAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: "matric_launch_at_login")
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to toggle Launch at Login: \(error.localizedDescription)")
        }
    }
    
    public func setHudOpacity(_ opacity: Double) {
        self.hudOpacity = opacity
        UserDefaults.standard.set(opacity, forKey: "matric_hud_opacity")
    }
    
    public func setConfirmBeforeCleanup(_ confirm: Bool) {
        self.confirmBeforeCleanup = confirm
        UserDefaults.standard.set(confirm, forKey: "matric_confirm_cleanup")
    }
    
    public func presentInspector(for app: AppGroupRecord) {
        self.inspectedApp = app
    }
    
    public func dismissInspector() {
        self.inspectedApp = nil
    }
    
    public func triggerManualRefresh() {
        SystemTelemetryHub.shared.refreshAll()
        self.statusNote = "Refreshed at \(Date().formatted(date: .omitted, time: .standard))"
    }
}
