import SwiftUI
import Charts

public struct NetworkDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "network")
                            .font(.system(size: 22))
                            .foregroundStyle(.cyan)
                        
                        Text("Network Bandwidth")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("\(hub.network.interfaces.count) Interfaces")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.12)))
                    }
                    
                    Text("Darwin BSD Sockets & AF_LINK · Real-time Rx/Tx Throughput")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Active status
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    
                    Text("Connected")
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
                            value: formatSpeed(hub.network.totalDownloadBps + hub.network.totalUploadBps),
                            subtitle: "Combined Rx + Tx",
                            icon: "arrow.up.arrow.down",
                            statusColor: .cyan,
                            sparklineData: hub.networkHistory.map { $0.totalDownloadBps + $0.totalUploadBps }
                        )
                        
                        MetricKPICard(
                            title: "Download (Rx)",
                            value: formatSpeed(hub.network.totalDownloadBps),
                            subtitle: "Inbound Packets",
                            icon: "arrow.down.to.line.circle.fill",
                            statusColor: .blue,
                            sparklineData: hub.networkHistory.map { $0.totalDownloadBps }
                        )
                        
                        MetricKPICard(
                            title: "Upload (Tx)",
                            value: formatSpeed(hub.network.totalUploadBps),
                            subtitle: "Outbound Packets",
                            icon: "arrow.up.to.line.circle.fill",
                            statusColor: .mint,
                            sparklineData: hub.networkHistory.map { $0.totalUploadBps }
                        )
                        
                        MetricKPICard(
                            title: "Physical Adapters",
                            value: "\(hub.network.interfaces.filter { $0.isPhysical }.count)",
                            subtitle: "\(hub.network.interfaces.count) Total Link Adapters",
                            icon: "wifi",
                            statusColor: .teal
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "Inbound & Outbound Bandwidth Timeline",
                        currentFormattedValue: formatSpeed(hub.network.totalDownloadBps + hub.network.totalUploadBps),
                        unitLabel: "bytes",
                        dataPoints: hub.networkHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.totalDownloadBps + $0.totalUploadBps) },
                        accentColor: .cyan
                    )
                    
                    // Network Interfaces Table
                    interfacesSection
                    
                    // Top Applications Table
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .cpu,
                        title: "ACTIVE NETWORK APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var interfacesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HARDWARE & VIRTUAL INTERFACES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                ForEach(Array(hub.network.interfaces.prefix(8))) { iface in
                    InterfaceCard(iface: iface)
                }
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
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSec)))/s"
    }
}

private struct InterfaceCard: View {
    let iface: NetworkInterfaceInfo
    
    private var isActive: Bool {
        iface.downloadBytesPerSec > 0 || iface.uploadBytesPerSec > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(isActive ? Color.cyan : Color.secondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.primary.opacity(0.05)))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(iface.name)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if isActive {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("↓ \(formatSpeed(iface.downloadBytesPerSec))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(iface.downloadBytesPerSec > 0 ? .primary : .secondary)
                    Text("↑ \(formatSpeed(iface.uploadBytesPerSec))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(iface.uploadBytesPerSec > 0 ? .primary : .secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private var iconName: String {
        if iface.name.hasPrefix("en0") { return "wifi" }
        if iface.name.hasPrefix("en") { return "cable.connector" }
        if iface.name.hasPrefix("bridge") { return "point.3.connected.trianglepath.dotted" }
        if iface.name.hasPrefix("utun") { return "lock.shield" }
        return "network"
    }
    
    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSec)))/s"
    }
}

#Preview {
    NetworkDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
