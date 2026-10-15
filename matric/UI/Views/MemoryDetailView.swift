import SwiftUI
import Charts

public struct MemoryDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                        
                        Text("Unified Memory")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("\(appState.hardwareInfo.ramGB) GB LPDDR5")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.12)))
                    }
                    
                    Text("Darwin Mach VM Subsystem · Memory Pressure & Page Allocation")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Pressure Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(pressureColor)
                        .frame(width: 7, height: 7)
                    
                    Text("\(hub.memory.pressureState.rawValue) Pressure")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(pressureColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(pressureColor.opacity(0.12))
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Top KPI Cards Row
                    HStack(spacing: 12) {
                        MetricKPICard(
                            title: "Working Set",
                            value: formatBytes(hub.memory.workingBytes),
                            subtitle: "Active + Wired + Compressed",
                            icon: "memorychip.fill",
                            statusColor: pressureColor,
                            sparklineData: hub.memoryHistory.map { Double($0.workingBytes) }
                        )
                        
                        MetricKPICard(
                            title: "App Memory",
                            value: formatBytes(hub.memory.activeBytes),
                            subtitle: "User Processes & Frameworks",
                            icon: "app.badge.fill",
                            statusColor: .blue,
                            sparklineData: hub.memoryHistory.map { Double($0.activeBytes) }
                        )
                        
                        MetricKPICard(
                            title: "Wired Memory",
                            value: formatBytes(hub.memory.wiredBytes),
                            subtitle: "Kernel & Non-pageable",
                            icon: "lock.fill",
                            statusColor: .purple,
                            sparklineData: hub.memoryHistory.map { Double($0.wiredBytes) }
                        )
                        
                        MetricKPICard(
                            title: "Compressed",
                            value: formatBytes(hub.memory.compressedBytes),
                            subtitle: "Z-Ram In-Memory Cache",
                            icon: "archivebox.fill",
                            statusColor: .orange,
                            sparklineData: hub.memoryHistory.map { Double($0.compressedBytes) }
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "Memory Consumption Timeline",
                        currentFormattedValue: formatBytes(hub.memory.workingBytes),
                        unitLabel: "bytes",
                        dataPoints: hub.memoryHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: Double($0.workingBytes)) },
                        accentColor: .green,
                        maxY: Double(appState.hardwareInfo.totalMemoryBytes)
                    )
                    
                    // Full Memory Composition Breakdown
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
                    
                    // Detailed VM Statistics Grid
                    detailedVMStatsSection
                    
                    // Top Memory Applications Table
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .memory,
                        title: "TOP MEMORY APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var detailedVMStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("VIRTUAL MEMORY SUBSYSTEM METRICS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                vmStatCard(title: "Physical RAM", value: "\(appState.hardwareInfo.ramGB) GB", icon: "cpu")
                vmStatCard(title: "Free Headroom", value: formatBytes(hub.memory.freeBytes), icon: "checkmark.circle")
                vmStatCard(title: "Swap Space Used", value: formatBytes(hub.memory.swapUsedBytes), icon: "arrow.triangle.swap")
                vmStatCard(title: "Swap Allocated", value: formatBytes(hub.memory.swapTotalBytes), icon: "externaldrive")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func vmStatCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.primary.opacity(0.05)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
    }
    
    private var pressureColor: Color {
        switch hub.memory.pressureState {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    MemoryDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
