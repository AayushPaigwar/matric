import SwiftUI
import Charts

public struct GPUDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.pink)
                        
                        Text("Graphics & Metal GPU")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(hub.gpu.chipModel.isEmpty ? "Apple Silicon GPU" : hub.gpu.chipModel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.pink.opacity(0.12)))
                    }
                    
                    Text("IOAccelerator · Metal Compute, Render & Unified Shared VRAM")
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
                            title: "GPU Utilization",
                            value: String(format: "%.1f%%", hub.gpu.utilizationPercent),
                            subtitle: "Device Engine Load",
                            icon: "waveform.path.ecg",
                            statusColor: hub.gpu.utilizationPercent > 50 ? .orange : .pink,
                            sparklineData: hub.gpuHistory.map(\.utilizationPercent)
                        )
                        
                        MetricKPICard(
                            title: "Allocated VRAM",
                            value: formatBytes(hub.gpu.driverAllocatedMemoryBytes),
                            subtitle: "Shared Unified Memory",
                            icon: "memorychip",
                            statusColor: .purple
                        )
                        
                        MetricKPICard(
                            title: "Thermal Pressure",
                            value: hub.gpu.thermalState.rawValue,
                            subtitle: "Dynamic Thermal Throttling",
                            icon: "thermometer.medium",
                            statusColor: thermalColor
                        )
                        
                        MetricKPICard(
                            title: "Metal Pipeline",
                            value: "Metal 3",
                            subtitle: "Hardware Ray Tracing",
                            icon: "sparkles",
                            statusColor: .indigo
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "GPU Device Load Timeline",
                        currentFormattedValue: String(format: "%.1f%%", hub.gpu.utilizationPercent),
                        unitLabel: "%",
                        dataPoints: hub.gpuHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: $0.utilizationPercent) },
                        accentColor: .pink,
                        maxY: 100.0
                    )
                    
                    // GPU Architecture & Metal Subsystem Card
                    gpuCapabilitiesSection
                    
                    // Top Applications Table
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .cpu,
                        title: "GRAPHICS & GPU APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var gpuCapabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("APPLE SILICON GRAPHICS CAPABILITIES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                capItem(title: "Architecture", value: "Apple M-Series GPU", icon: "cpu")
                capItem(title: "Memory Model", value: "Unified Zero-Copy Memory", icon: "arrow.triangle.swap")
                capItem(title: "Shading Language", value: "MSL 3.1 & Mesh Shaders", icon: "curlybraces")
                capItem(title: "Raytracing", value: "Hardware Accelerated", icon: "cube.transparent")
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
    private func capItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.pink)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.pink.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
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
    
    private var thermalColor: Color {
        switch hub.gpu.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
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
    GPUDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
