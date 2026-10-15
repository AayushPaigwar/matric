import SwiftUI

public struct PlaceholderDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    let item: NavigationItem
    
    public init(item: NavigationItem) {
        self.item = item
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.rawValue)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Live indicator badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isLive ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    
                    Text(appState.isLive ? "Live" : "Paused")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Content Body showing live sensor telemetry & process attribution
            ScrollView {
                VStack(spacing: 16) {
                    // Live Sensor Telemetry Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        telemetryCard(
                            title: "CPU Load",
                            value: String(format: "%.1f%%", hub.cpu.totalPercent),
                            subtext: String(format: "User: %.1f%% · Sys: %.1f%% · Load: %.2f", hub.cpu.userPercent, hub.cpu.systemPercent, hub.cpu.loadAverage1Min),
                            icon: "cpu",
                            accent: .blue
                        )
                        
                        telemetryCard(
                            title: "Memory",
                            value: formatBytes(hub.memory.workingBytes),
                            subtext: "\(hub.memory.pressureState.rawValue) Pressure · Swap: \(formatBytes(hub.memory.swapUsedBytes))",
                            icon: "memorychip",
                            accent: hub.memory.pressureState == .critical ? .red : (hub.memory.pressureState == .elevated ? .orange : .green)
                        )
                        
                        telemetryCard(
                            title: "Disk I/O",
                            value: formatSpeed(hub.disk.readBytesPerSec + hub.disk.writeBytesPerSec),
                            subtext: "Read: \(formatSpeed(hub.disk.readBytesPerSec)) · Write: \(formatSpeed(hub.disk.writeBytesPerSec))",
                            icon: "internaldrive",
                            accent: .purple
                        )
                        
                        telemetryCard(
                            title: "Network",
                            value: formatSpeed(hub.network.totalDownloadBps + hub.network.totalUploadBps),
                            subtext: "↓ \(formatSpeed(hub.network.totalDownloadBps)) · ↑ \(formatSpeed(hub.network.totalUploadBps))",
                            icon: "network",
                            accent: .cyan
                        )
                        
                        telemetryCard(
                            title: "Graphics (GPU)",
                            value: String(format: "%.0f%%", hub.gpu.utilizationPercent),
                            subtext: "\(hub.gpu.chipModel) · Thermal: \(hub.gpu.thermalState.rawValue)",
                            icon: "display",
                            accent: .indigo
                        )
                        
                        telemetryCard(
                            title: "Battery & Power",
                            value: hub.battery.hasBattery ? "\(hub.battery.chargePercent)%" : "AC Power",
                            subtext: hub.battery.hasBattery ? String(format: "%.1f W · Cycles: %d · Health: %d%%", hub.battery.currentWatts, hub.battery.cycleCount, hub.battery.healthPercent) : "Desktop Mac",
                            icon: "battery.100",
                            accent: .green
                        )
                    }
                    
                    // Process Attribution Section (Phase 3)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Active Applications & Process Attribution")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("\(hub.appGroups.count) applications · Click to inspect helpers")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Applications table container
                        VStack(spacing: 0) {
                            // Table Header
                            HStack {
                                Text("APPLICATION")
                                    .frame(minWidth: 200, alignment: .leading)
                                Spacer()
                                Text("PROCESSES")
                                    .frame(width: 90, alignment: .trailing)
                                Text("CPU")
                                    .frame(width: 80, alignment: .trailing)
                                Text("MEMORY")
                                    .frame(width: 90, alignment: .trailing)
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                            
                            Divider()
                            
                            // App Rows
                            ForEach(hub.appGroups.prefix(10)) { app in
                                Button {
                                    appState.presentInspector(for: app)
                                } label: {
                                    HStack(spacing: 12) {
                                        // App icon
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 22, height: 22)
                                        } else {
                                            Image(systemName: "app")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 22, height: 22)
                                        }
                                        
                                        // Name and bundle ID
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            if let bundleId = app.bundleIdentifier {
                                                Text(bundleId)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .frame(minWidth: 160, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        // Process count pill
                                        Text("\(app.processCount) procs")
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundStyle(app.processCount > 1 ? Color.accentColor : Color.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(app.processCount > 1 ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                                            )
                                            .frame(width: 90, alignment: .trailing)
                                        
                                        // CPU
                                        Text(app.formattedCpu)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(app.totalCpuPercent > 10 ? .orange : .primary)
                                            .frame(width: 80, alignment: .trailing)
                                        
                                        // Memory
                                        Text(app.formattedMemory)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.primary)
                                            .frame(width: 90, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                    .opacity(0.5)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            // Persistent Bottom Footer
            StatusFooterView()
        }
    }
    
    @ViewBuilder
    private func telemetryCard(title: String, value: String, subtext: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(accent)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(subtext)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSec)))/s"
    }
}

#Preview {
    PlaceholderDetailView(item: .overview)
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
