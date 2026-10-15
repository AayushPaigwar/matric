import SwiftUI

public enum NavigationGroup: String, CaseIterable, Identifiable {
    case resources = "RESOURCES"
    case workspace = "WORKSPACE"
    
    public var id: String { rawValue }
}

public enum NavigationItem: String, CaseIterable, Identifiable, Hashable {
    // Resources
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case network = "Network"
    case storage = "Storage"
    case graphics = "Graphics"
    case battery = "Battery"
    
    // Workspace
    case projects = "Projects"
    case cleanup = "Cleanup"
    case settings = "Settings"
    case history = "History"
    case alerts = "Alerts"
    case savedMoments = "Saved moments"
    
    public var id: String { rawValue }
    
    public var group: NavigationGroup {
        switch self {
        case .overview, .cpu, .memory, .disk, .network, .storage, .graphics, .battery:
            return .resources
        case .projects, .cleanup, .settings, .history, .alerts, .savedMoments:
            return .workspace
        }
    }
    
    public var iconName: String {
        switch self {
        case .overview:
            return "square.grid.2x2"
        case .cpu:
            return "cpu"
        case .memory:
            return "memorychip"
        case .disk:
            return "internaldrive"
        case .network:
            return "network"
        case .storage:
            return "externaldrive"
        case .graphics:
            return "display"
        case .battery:
            return "battery.100"
        case .projects:
            return "folder.badge.gearshape"
        case .cleanup:
            return "sparkles"
        case .settings:
            return "gearshape"
        case .history:
            return "clock.arrow.circlepath"
        case .alerts:
            return "bell.badge"
        case .savedMoments:
            return "bookmark"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .overview:
            return "Your Mac, at a glance."
        case .cpu:
            return "Processor utilization, cores, and load averages."
        case .memory:
            return "Physical memory, pressure, and the apps using it."
        case .disk:
            return "Storage capacity and live read/write activity."
        case .network:
            return "Traffic across your active network interfaces."
        case .storage:
            return "See what takes up space, folder by folder."
        case .graphics:
            return "Graphics activity reported by this Mac."
        case .battery:
            return "Power source, charging, and battery condition."
        case .projects:
            return "Local runtimes, grouped by their working folder."
        case .cleanup:
            return "Safe cache purging and developer workspace cleanup."
        case .settings:
            return "App behavior, refresh rate, and customization."
        case .history:
            return "Thirty days of measurements, stored on this Mac."
        case .alerts:
            return "Sustained activity that may need your attention."
        case .savedMoments:
            return "A closer look at the moments you saved."
        }
    }
}
