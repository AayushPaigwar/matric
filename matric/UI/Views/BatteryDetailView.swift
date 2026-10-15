import SwiftUI
import Charts

public struct BatteryDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    private var isACConnected: Bool {
        hub.battery.powerSourceState == "AC Power" || hub.battery.isCharging
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: batteryIcon)
                            .font(.system(size: 22))
                            .foregroundStyle(batteryColor)
                        
                        Text("Battery & Power")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(hub.battery.isCharging ? "Charging" : (isACConnected ? "AC Connected" : "On Battery"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(batteryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(batteryColor.opacity(0.12)))
                    }
                    
                    Text("IOKit AppleSmartBattery · Lithium-Polymer Chemistry & Cycle Health")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Live charge pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(batteryColor)
                        .frame(width: 7, height: 7)
                    
                    Text("\(hub.battery.chargePercent)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
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
                            title: "Current Charge",
                            value: "\(hub.battery.chargePercent)%",
                            subtitle: isACConnected ? "Power Adapter Active" : "Discharging",
                            icon: batteryIcon,
                            statusColor: batteryColor,
                            sparklineData: hub.batteryHistory.map { Double($0.chargePercent) }
                        )
                        
                        MetricKPICard(
                            title: "Battery Health",
                            value: "\(hub.battery.healthPercent)%",
                            subtitle: "Maximum Design Capacity",
                            icon: "heart.fill",
                            statusColor: hub.battery.healthPercent > 80 ? .green : .orange
                        )
                        
                        MetricKPICard(
                            title: "Cycle Count",
                            value: "\(hub.battery.cycleCount)",
                            subtitle: "of 1000 Design Limit",
                            icon: "arrow.triangle.2.circlepath",
                            statusColor: .blue
                        )
                        
                        MetricKPICard(
                            title: "Power Draw",
                            value: hub.battery.currentWatts > 0 ? String(format: "%.1f W", hub.battery.currentWatts) : "Nominal",
                            subtitle: isACConnected ? "Adapter Connected" : "Battery Drain Rate",
                            icon: "bolt.fill",
                            statusColor: hub.battery.isCharging ? .green : .orange
                        )
                    }
                    
                    // Main Timeline Chart
                    TimelineChartView(
                        title: "Battery Charge Level Timeline",
                        currentFormattedValue: "\(hub.battery.chargePercent)%",
                        unitLabel: "%",
                        dataPoints: hub.batteryHistory.map { TimelineDataPoint(timestamp: $0.timestamp, value: Double($0.chargePercent)) },
                        accentColor: batteryColor,
                        maxY: 100.0
                    )
                    
                    // Diagnostics & Power Architecture
                    powerDiagnosticsSection
                    
                    // Top Applications Table (Energy impact)
                    AppsActivityTableView(
                        appGroups: hub.appGroups,
                        defaultSort: .cpu,
                        title: "ENERGY IMPACT APPLICATIONS"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
    }
    
    private var powerDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BATTERY HEALTH & SMART CHARGING DIAGNOSTICS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                diagItem(title: "Power Source", value: isACConnected ? "AC Power Adapter" : "Internal Battery", icon: "cable.connector")
                diagItem(title: "Condition", value: hub.battery.healthPercent >= 80 ? "Normal" : "Service Recommended", icon: "checkmark.shield")
                diagItem(title: "Optimized Charging", value: "Enabled", icon: "sparkles")
                diagItem(title: "Temperature", value: "Normal / Nominal", icon: "thermometer.snowflake")
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
    private func diagItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(batteryColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(batteryColor.opacity(0.1)))
            
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
    
    private var batteryIcon: String {
        if hub.battery.isCharging {
            return "battery.100.bolt"
        }
        let charge = hub.battery.chargePercent
        if charge > 75 { return "battery.100" }
        if charge > 50 { return "battery.75" }
        if charge > 25 { return "battery.50" }
        return "battery.25"
    }
    
    private var batteryColor: Color {
        if hub.battery.isCharging { return .green }
        let charge = hub.battery.chargePercent
        if charge > 30 { return .green }
        if charge > 15 { return .orange }
        return .red
    }
}

#Preview {
    BatteryDetailView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
