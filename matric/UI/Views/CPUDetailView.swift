import SwiftUI
import Charts

public struct CPUDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    private var coreCount: Int {
        hub.cpu.corePercentages.isEmpty ? appState.hardwareInfo.coreCount : hub.cpu.corePercentages.count
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .font(.system(size: 22))
                            .foregroundStyle(.blue)
                        
                        Text("Processor")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("\(coreCount) Cores")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.blue.opacity(0.12)))
                    }
                    
                    Text("\(appState.hardwareInfo.chipName) · Host Processor Load & Multi-Core Distribution")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Thermal state pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(thermalColor)
                        .frame(width: 7, height: 7)
                    
                    Text(hub.gpu.thermalState.rawValue)
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
                            title: "Total Load",
                            value: String(format: "%.1f%%", hub.cpu.totalPercent),
                            subtitle: "\(coreCount) Active Cores",
                            icon: "gauge.with.needle",
                            statusColor: hub.cpu.totalPercent > 50 ? .orange : .blue,
                            sparklineData: hub.cpuHistory.map(\.totalPercent)
                        )
                        
                        MetricKPICard(
                            title: "User Space",
                            value: String(format: "%.1f%%", hub.cpu.userPercent),
                            subtitle: "Applications & UI",
                            icon: "person.fill",
                            statusColor: .indigo,
                            sparklineData: hub.cpuHistory.map(\.userPercent)
                        )
                        
                        MetricKPICard(
                            title: "System / Kernel",
                            value: String(format: "%.1f%%", hub.cpu.systemPercent),
                            subtitle: "Darwin Mach Services",
                            icon: "gearshape.fill",
                            statusColor: .purple,
                            sparklineData: hub.cpuHistory.map(\.systemPercent)
                        )
                        
                        MetricKPICard(
                            title: "Load Averages",
                            value: String(format: "%.2f", hub.cpu.loadAverage1Min),
                            subtitle: String(format: "5m: %.2f · 15m: %.2f", hub.cpu.loadAverage5Min, hub.cpu.loadAverage15Min),
                            icon: "chart.line.uptrend.xyaxis",
                            statusColor: .teal
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "CPU Load Timeline",
                        currentFormattedValue: String(format: "%.1f%%", hub.cpu.totalPercent),
                        unitLabel: "%",
                        dataPoints: hub.cpuHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.totalPercent) },
                        accentColor: .blue,
                        maxY: 100.0
                    )
                    
                    // Per-Core Matrix
                    perCoreMatrixSection
                    
                    // Top CPU Applications Table
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .cpu,
                        title: "TOP CPU APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var perCoreMatrixSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PER-CORE UTILIZATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text("\(coreCount) Logical / Performance & Efficiency Cores")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(Array(hub.cpu.corePercentages.enumerated()), id: \.offset) { idx, load in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Core \(idx + 1)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", load))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(load > 70 ? .red : (load > 40 ? .orange : .primary))
                        }
                        
                        GeometryReader { g in
                            let pct = min(load / 100.0, 1.0)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                                Capsule()
                                    .fill(load > 70 ? Color.red : (load > 40 ? Color.orange : Color.blue))
                                    .frame(width: max(g.size.width * pct, 3))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                    )
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
    
    private var thermalColor: Color {
        switch hub.gpu.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        }
    }
}

#Preview {
    CPUDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
