import SwiftUI
import Charts

public struct DiskDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    private var totalCapacity: UInt64 {
        hub.disk.totalSpaceBytes
    }
    
    private var availableSpace: UInt64 {
        hub.disk.freeSpaceBytes
    }
    
    private var usedSpace: UInt64 {
        hub.disk.usedSpaceBytes
    }
    
    private var usedFraction: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedSpace) / Double(totalCapacity)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 22))
                            .foregroundStyle(.purple)
                        
                        Text("Storage & Disk I/O")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(hub.disk.volumeName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
                    }
                    
                    Text("APFS Container · Block Storage Driver Read / Write Bandwidth")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Volume usage status
                HStack(spacing: 6) {
                    Circle()
                        .fill(usedFraction > 0.9 ? Color.red : (usedFraction > 0.75 ? Color.orange : Color.green))
                        .frame(width: 7, height: 7)
                    
                    Text(String(format: "%.0f%% Used", usedFraction * 100))
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
            
            ScrollView {
                VStack(spacing: 16) {
                    // Top KPI Cards Row
                    HStack(spacing: 12) {
                        MetricKPICard(
                            title: "Total Throughput",
                            value: formatSpeed(hub.disk.readBytesPerSec + hub.disk.writeBytesPerSec),
                            subtitle: "Active I/O Transfer Rate",
                            icon: "arrow.left.arrow.right",
                            statusColor: .purple,
                            sparklineData: hub.diskHistory.map { $0.readBytesPerSec + $0.writeBytesPerSec }
                        )
                        
                        MetricKPICard(
                            title: "Read Bandwidth",
                            value: formatSpeed(hub.disk.readBytesPerSec),
                            subtitle: "NVMe Block Reads",
                            icon: "arrow.down.circle.fill",
                            statusColor: .blue,
                            sparklineData: hub.diskHistory.map { $0.readBytesPerSec }
                        )
                        
                        MetricKPICard(
                            title: "Write Bandwidth",
                            value: formatSpeed(hub.disk.writeBytesPerSec),
                            subtitle: "NVMe Block Writes",
                            icon: "arrow.up.circle.fill",
                            statusColor: .pink,
                            sparklineData: hub.diskHistory.map { $0.writeBytesPerSec }
                        )
                        
                        MetricKPICard(
                            title: "Available Space",
                            value: formatBytes(availableSpace),
                            subtitle: "of \(formatBytes(totalCapacity)) Total",
                            icon: "internaldrive.fill",
                            statusColor: usedFraction > 0.85 ? .orange : .green
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "Disk I/O Bandwidth Timeline",
                        currentFormattedValue: formatSpeed(hub.disk.readBytesPerSec + hub.disk.writeBytesPerSec),
                        unitLabel: "bytes",
                        dataPoints: hub.diskHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.readBytesPerSec + $0.writeBytesPerSec) },
                        accentColor: .purple
                    )
                    
                    // Storage Capacity Breakdown Bar
                    storageCapacitySection
                    
                    // Top Applications Table
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .cpu,
                        title: "ACTIVE DISK APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var storageCapacitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("APFS PRIMARY CONTAINER STORAGE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text("\(formatBytes(usedSpace)) used of \(formatBytes(totalCapacity)) total capacity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text(String(format: "%.1f%% Full", usedFraction * 100))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(usedFraction > 0.9 ? .red : .primary)
            }
            
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: max(w * usedFraction, 4))
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: max(w * (1.0 - usedFraction), 4))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 12)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color.purple).frame(width: 8, height: 8)
                    Text("Used Space:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(formatBytes(usedSpace))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color.primary.opacity(0.3)).frame(width: 8, height: 8)
                    Text("Available Free:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(formatBytes(availableSpace))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                Text("File System: Apple APFS (Encrypted)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
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
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSec)))/s"
    }
}

#Preview {
    DiskDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
