import SwiftUI

public enum OverviewChartMetric: String, CaseIterable, Identifiable {
    case cpu = "CPU Load"
    case memory = "Memory Footprint"
    case network = "Network Bandwidth"
    case disk = "Disk I/O"
    
    public var id: String { rawValue }
}

public struct OverviewDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    @State private var activeChartMetric: OverviewChartMetric = .cpu
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Dashboard Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Overview")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(appState.hardwareInfo.chipName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                    }
                    
                    Text("Real-time system telemetry and unified process attribution")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Live status capsule
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isLive ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    
                    Text(appState.isLive ? "Live · 2s" : "Paused")
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
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 16) {
                    // Top KPI Cards Row
                    HStack(spacing: 12) {
                        MetricKPICard(
                            title: "CPU Load",
                            value: String(format: "%.1f%%", hub.cpu.totalPercent),
                            subtitle: String(format: "User %.1f%% · Sys %.1f%%", hub.cpu.userPercent, hub.cpu.systemPercent),
                            icon: "cpu",
                            statusColor: .blue,
                            trend: hub.cpu.totalPercent > 15 ? "+high" : nil,
                            sparklineData: hub.cpuHistory.map(\.totalPercent),
                            isSelected: activeChartMetric == .cpu
                        ) {
                            activeChartMetric = .cpu
                        }
                        
                        MetricKPICard(
                            title: "Working Memory",
                            value: formatBytes(hub.memory.workingBytes),
                            subtitle: "\(hub.memory.pressureState.rawValue) Pressure · \(formatBytes(hub.memory.swapUsedBytes)) swap",
                            icon: "memorychip",
                            statusColor: hub.memory.pressureState == .critical ? .red : (hub.memory.pressureState == .elevated ? .orange : .green),
                            sparklineData: hub.memoryHistory.map { Double($0.workingBytes) },
                            isSelected: activeChartMetric == .memory
                        ) {
                            activeChartMetric = .memory
                        }
                        
                        MetricKPICard(
                            title: "Network",
                            value: formatSpeed(hub.network.totalDownloadBps + hub.network.totalUploadBps),
                            subtitle: "↓ \(formatSpeed(hub.network.totalDownloadBps)) · ↑ \(formatSpeed(hub.network.totalUploadBps))",
                            icon: "network",
                            statusColor: .cyan,
                            sparklineData: hub.networkHistory.map { $0.totalDownloadBps + $0.totalUploadBps },
                            isSelected: activeChartMetric == .network
                        ) {
                            activeChartMetric = .network
                        }
                        
                        MetricKPICard(
                            title: "Disk I/O",
                            value: formatSpeed(hub.disk.readBytesPerSec + hub.disk.writeBytesPerSec),
                            subtitle: "R \(formatSpeed(hub.disk.readBytesPerSec)) · W \(formatSpeed(hub.disk.writeBytesPerSec))",
                            icon: "internaldrive",
                            statusColor: .purple,
                            sparklineData: hub.diskHistory.map { $0.readBytesPerSec + $0.writeBytesPerSec },
                            isSelected: activeChartMetric == .disk
                        ) {
                            activeChartMetric = .disk
                        }
                    }
                    
                    // Main Interactive Timeline Chart
                    timelineSection
                    
                    // Memory Composition & Pressure Breakdown
                    MemoryCompositionChart(
                        activeBytes: hub.memory.activeBytes,
                        wiredBytes: hub.memory.wiredBytes,
                        compressedBytes: hub.memory.compressedBytes,
                        freeBytes: hub.memory.freeBytes,
                        totalPhysicalBytes: appState.hardwareInfo.totalMemoryBytes,
                        swapUsedBytes: hub.memory.swapUsedBytes,
                        swapTotalBytes: hub.memory.swapTotalBytes,
                        pressureState: hub.memory.pressureState
                    )
                    
                    // Top Applications Activity Table
                    AppsActivityTableView(appGroups: hub.appGroups)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            // Persistent Bottom Status Footer
            StatusFooterView()
        }
    }
    
    @ViewBuilder
    private var timelineSection: some View {
        switch activeChartMetric {
        case .cpu:
            TimelineChartView(
                title: "CPU Utilization Timeline",
                currentFormattedValue: String(format: "%.1f%%", hub.cpu.totalPercent),
                unitLabel: "%",
                dataPoints: hub.cpuHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.totalPercent) },
                accentColor: .blue,
                maxY: 100.0
            )
            
        case .memory:
            TimelineChartView(
                title: "Memory Footprint Timeline",
                currentFormattedValue: formatBytes(hub.memory.workingBytes),
                unitLabel: "bytes",
                dataPoints: hub.memoryHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: Double($0.workingBytes)) },
                accentColor: .green,
                maxY: Double(appState.hardwareInfo.totalMemoryBytes)
            )
            
        case .network:
            TimelineChartView(
                title: "Network Throughput Timeline",
                currentFormattedValue: formatSpeed(hub.network.totalDownloadBps + hub.network.totalUploadBps),
                unitLabel: "bytes",
                dataPoints: hub.networkHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.totalDownloadBps + $0.totalUploadBps) },
                accentColor: .cyan
            )
            
        case .disk:
            TimelineChartView(
                title: "Disk I/O Throughput Timeline",
                currentFormattedValue: formatSpeed(hub.disk.readBytesPerSec + hub.disk.writeBytesPerSec),
                unitLabel: "bytes",
                dataPoints: hub.diskHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.readBytesPerSec + $0.writeBytesPerSec) },
                accentColor: .purple
            )
        }
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
    OverviewDashboardView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
