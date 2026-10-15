import SwiftUI
import AppKit

public struct MenuBarPopupView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    @State private var hudController = FloatingHUDWindowController.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header: Mac Model & Matric Title
            headerSection
            
            Divider()
                .opacity(0.4)
            
            // Core Metrics Grid (CPU, RAM, Disk, Net)
            metricsGridSection
            
            Divider()
                .opacity(0.4)
            
            // Top Resource Consumers
            topAppsSection
            
            Divider()
                .opacity(0.4)
            
            // Footer Quick Actions
            footerActionsSection
        }
        .padding(14)
        .frame(width: 300)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 24, height: 24)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(appState.hardwareInfo.chipName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(appState.hardwareInfo.modelIdentifier)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("Live")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Metrics Grid
    private var metricsGridSection: some View {
        VStack(spacing: 8) {
            // Row 1: CPU & Memory
            HStack(spacing: 8) {
                metricBox(
                    title: "CPU",
                    value: "\(Int(hub.cpu.totalPercent))%",
                    detail: "\(hub.cpu.corePercentages.count) Cores",
                    icon: "cpu",
                    tint: .cyan,
                    progress: hub.cpu.totalPercent / 100.0
                )
                
                metricBox(
                    title: "MEMORY",
                    value: "\(Int(hub.memory.usedPercentage))%",
                    detail: "\(ByteCountFormatter.string(fromByteCount: Int64(hub.memory.workingBytes), countStyle: .memory))",
                    icon: "memorychip",
                    tint: .purple,
                    progress: hub.memory.usedPercentage / 100.0
                )
            }
            
            // Row 2: Disk & Network
            HStack(spacing: 8) {
                let totalDisk = Double(max(hub.disk.totalSpaceBytes, 1))
                let usedDisk = Double(hub.disk.usedSpaceBytes)
                let diskPercent = (usedDisk / totalDisk) * 100.0
                
                metricBox(
                    title: "STORAGE",
                    value: "\(Int(diskPercent))%",
                    detail: "\(ByteCountFormatter.string(fromByteCount: Int64(hub.disk.freeSpaceBytes), countStyle: .file)) Free",
                    icon: "internaldrive",
                    tint: .blue,
                    progress: diskPercent / 100.0
                )
                
                // Network Box
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text("NETWORK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.green)
                            Text(formatSpeed(hub.network.totalDownloadBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.blue)
                            Text(formatSpeed(hub.network.totalUploadBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.top, 2)
                    
                    Spacer(minLength: 0)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
            }
        }
    }
    
    private func metricBox(title: String, value: String, detail: String, icon: String, tint: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule().fill(tint).frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)))
                }
            }
            .frame(height: 3)
            
            Text(detail)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
    }
    
    // MARK: - Top Apps
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP RESOURCE CONSUMERS")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            
            let sortedApps = hub.appGroups.sorted { $0.totalCpuPercent > $1.totalCpuPercent }
            let topApps = Array(sortedApps.prefix(3))
            
            if topApps.isEmpty {
                Text("Analyzing active processes...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 6) {
                    ForEach(topApps) { app in
                        HStack(spacing: 8) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text(app.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%%", app.totalCpuPercent))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.cyan)
                            
                            Text(app.formattedMemory)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Actions
    private var footerActionsSection: some View {
        HStack(spacing: 8) {
            // Floating HUD Toggle
            Button {
                hudController.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hudController.isVisible ? "pip.exit" : "pip.enter")
                        .font(.system(size: 10))
                    Text(hudController.isVisible ? "Hide HUD" : "Floating HUD")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(hudController.isVisible ? Color.cyan.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .foregroundStyle(hudController.isVisible ? Color.cyan : Color.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Open Main App Window
            Button {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Text("Open Matric")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            
            // Open Preferences
            Button {
                NSApp.activate(ignoringOtherApps: true)
                appState.select(.settings)
                if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .background(Circle().fill(Color.primary.opacity(0.05)))
            }
            .buttonStyle(.plain)
            .help("Preferences (⌘,)")
            
            // Quit
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .background(Circle().fill(Color.primary.opacity(0.05)))
            }
            .buttonStyle(.plain)
            .help("Quit Matric")
        }
    }
    
    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 {
            return "0 K"
        } else if bps < 1024 * 1024 {
            return String(format: "%.0f K", bps / 1024)
        } else {
            return String(format: "%.1f M", bps / (1024 * 1024))
        }
    }
}
