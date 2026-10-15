import SwiftUI
import AppKit

public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    @State private var selectedTab: SettingsTab = .general
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case menuBar = "Menu Bar & HUD"
        case shortcuts = "Shortcuts"
        case cleanup = "Cleanup"
        case about = "About"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .general: return "gearshape"
            case .menuBar: return "menubar.rectangle"
            case .shortcuts: return "command"
            case .cleanup: return "sparkles"
            case .about: return "info.circle"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Tabs Picker
                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 420)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
                .opacity(0.4)
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        generalSection
                    case .menuBar:
                        menuBarSection
                    case .shortcuts:
                        shortcutsSection
                    case .cleanup:
                        cleanupSection
                    case .about:
                        aboutSection
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Refresh Interval Card
            settingsCard(title: "Telemetry Update Frequency", icon: "timer") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Controls how frequently kernel sensors interrogate hardware and process trees.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        refreshOptionButton(title: "0.5s", subtitle: "High Precision", interval: 0.5)
                        refreshOptionButton(title: "1.0s", subtitle: "Standard", interval: 1.0)
                        refreshOptionButton(title: "2.0s", subtitle: "Default / Balanced", interval: 2.0)
                        refreshOptionButton(title: "5.0s", subtitle: "Power Saver", interval: 5.0)
                    }
                }
            }
            
            // Temperature Unit Card
            settingsCard(title: "Temperature Units", icon: "thermometer.medium") {
                Picker("Unit", selection: Binding(
                    get: { appState.temperatureUnit },
                    set: { appState.setTemperatureUnit($0) }
                )) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
            }
            
            // Launch at Login
            settingsCard(title: "Startup & Background Behavior", icon: "power") {
                Toggle(isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.setLaunchAtLogin($0) }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Launch Matric at System Login")
                            .font(.system(size: 13, weight: .medium))
                        Text("Starts Matric silently in the menu bar whenever your Mac boots.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
    }
    
    private func refreshOptionButton(title: String, subtitle: String, interval: Double) -> some View {
        let isSelected = abs(appState.refreshInterval - interval) < 0.05
        return Button {
            appState.setRefreshInterval(interval)
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Menu Bar Section
    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsCard(title: "Menu Bar Item Appearance", icon: "menubar.rectangle") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configure what is rendered in the top macOS status bar.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { appState.menuBarMode },
                        set: { appState.setMenuBarMode($0) }
                    )) {
                        ForEach(MenuBarDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            
            settingsCard(title: "Desktop Floating Mini HUD", icon: "pip.enter") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Configure the translucent floating monitor widget overlay.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        Text("Window Opacity:")
                            .font(.system(size: 12, weight: .medium))
                        
                        Slider(
                            value: Binding(
                                get: { appState.hudOpacity },
                                set: { appState.setHudOpacity($0) }
                            ),
                            in: 0.5...1.0,
                            step: 0.05
                        )
                        .frame(width: 160)
                        
                        Text("\(Int(appState.hudOpacity * 100))%")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        FloatingHUDWindowController.shared.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: FloatingHUDWindowController.shared.isVisible ? "pip.exit" : "pip.enter")
                            Text(FloatingHUDWindowController.shared.isVisible ? "Hide Floating HUD" : "Launch Floating HUD Now")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.15)))
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Shortcuts Section
    private var shortcutsSection: some View {
        settingsCard(title: "Keyboard Shortcuts", icon: "command") {
            VStack(spacing: 8) {
                shortcutRow(keys: ["⌘", "1"], description: "Navigate to Overview Dashboard")
                shortcutRow(keys: ["⌘", "2"], description: "Navigate to CPU Load & Cores")
                shortcutRow(keys: ["⌘", "3"], description: "Navigate to Physical Memory")
                shortcutRow(keys: ["⌘", "4"], description: "Navigate to Disk I/O & Storage")
                shortcutRow(keys: ["⌘", "5"], description: "Navigate to Network Throughput")
                shortcutRow(keys: ["⌘", "6"], description: "Navigate to Storage Space Analyzer")
                shortcutRow(keys: ["⌘", "7"], description: "Navigate to GPU Utilization")
                shortcutRow(keys: ["⌘", "8"], description: "Navigate to Battery & Power Diagnostics")
                shortcutRow(keys: ["⌘", "9"], description: "Navigate to Developer Projects")
                shortcutRow(keys: ["⌘", "0"], description: "Navigate to System Cleanup")
                shortcutRow(keys: ["⌘", "R"], description: "Force Manual Telemetry Sensor Refresh")
                shortcutRow(keys: ["⌘", "H"], description: "Toggle Desktop Floating HUD Window")
                shortcutRow(keys: ["⌘", ","], description: "Open Preferences / Settings")
            }
        }
    }
    
    private func shortcutRow(keys: [String], description: String) -> some View {
        HStack {
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Cleanup Section
    private var cleanupSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsCard(title: "Cleanup Protection & Safety", icon: "shield") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { appState.confirmBeforeCleanup },
                        set: { appState.setConfirmBeforeCleanup($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Confirm before deleting target items")
                                .font(.system(size: 13, weight: .medium))
                            Text("Presents a confirmation modal with size breakdown before executing purge commands.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    Divider().padding(.vertical, 4)
                    
                    Text("Safety Policy:")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text("Matric only scans temporary caches (DerivedData, Simulator caches, Package manager download caches, User Caches, Trash). User documents, source code repositories, and configuration files are never touched.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsCard(title: "Hardware & Platform Details", icon: "laptopcomputer") {
                VStack(spacing: 8) {
                    infoRow(label: "Processor", value: appState.hardwareInfo.chipName)
                    infoRow(label: "Hardware Model", value: appState.hardwareInfo.modelIdentifier)
                    infoRow(label: "CPU Cores", value: "\(appState.hardwareInfo.coreCount) Total Cores")
                    infoRow(label: "Unified Memory", value: "\(appState.hardwareInfo.ramGB) GB RAM")
                    infoRow(label: "macOS Kernel", value: ProcessInfo.processInfo.operatingSystemVersionString)
                    infoRow(label: "App Version", value: "Matric 1.0.0 (Native Swift 6.0)")
                }
            }
            
            settingsCard(title: "Architecture & Low Overhead", icon: "bolt.shield") {
                Text("Matric is built purely with native macOS Darwin, Mach kernel APIs (`host_processor_info`, `mach_vm_page_info`, `statfs`), IOKit registries, and SwiftUI. It does not spawn background Python/Node runtimes or shell sub-processes for sensor reads, ensuring near-zero CPU and energy impact.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 3)
    }
    
    // MARK: - Helper Container
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
