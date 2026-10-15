import SwiftUI

public struct AlertsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    private var alertsManager = AlertsManager.shared
    
    @State private var showingSettingsSheet: Bool = false
    @State private var alertToDismiss: SystemAlert?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Strip
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // KPI Strip
                    kpiSummaryStrip
                    
                    // Filter & Action Toolbar
                    filterToolbar
                    
                    // Alerts List or Empty State
                    if alertsManager.filteredAlerts.isEmpty {
                        emptyStateView
                    } else {
                        alertsListView
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingSettingsSheet) {
            alertThresholdsSheet
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Alerts")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    if alertsManager.activeAlertsCount > 0 {
                        Text("\(alertsManager.activeAlertsCount) active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule().fill(Color.red)
                            )
                    }
                }
                
                Text("Sustained activity and resource anomalies needing your attention.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    showingSettingsSheet = true
                } label: {
                    Label("Thresholds", systemImage: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                
                if alertsManager.resolvedCount > 0 {
                    Button {
                        alertsManager.clearResolved()
                    } label: {
                        Text("Clear Resolved")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }
    
    // MARK: - KPI Summary Strip
    private var kpiSummaryStrip: some View {
        HStack(spacing: 14) {
            kpiCard(
                title: "Active Alerts",
                value: "\(alertsManager.activeAlertsCount)",
                subtitle: alertsManager.activeAlertsCount == 0 ? "Everything calm" : "Requires attention",
                icon: "bell.badge.fill",
                color: alertsManager.activeAlertsCount > 0 ? .red : .secondary
            )
            
            kpiCard(
                title: "Critical Issues",
                value: "\(alertsManager.criticalCount)",
                subtitle: "Severe throttling / pressure",
                icon: "exclamationmark.octagon.fill",
                color: alertsManager.criticalCount > 0 ? .red : .secondary
            )
            
            kpiCard(
                title: "Resolved",
                value: "\(alertsManager.resolvedCount)",
                subtitle: "Automatically cleared",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            kpiCard(
                title: "System Health",
                value: alertsManager.isSystemHealthy ? "Nominal" : "Under Load",
                subtitle: alertsManager.isSystemHealthy ? "All thresholds within bounds" : "Spike detected",
                icon: alertsManager.isSystemHealthy ? "shield.lefthalf.filled" : "exclamationmark.triangle.fill",
                color: alertsManager.isSystemHealthy ? .green : .orange
            )
        }
    }
    
    private func kpiCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Filter Toolbar
    private var filterToolbar: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(AlertsManager.AlertFilter.allCases) { filter in
                    Button {
                        alertsManager.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: alertsManager.selectedFilter == filter ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(alertsManager.selectedFilter == filter ? Color.accentColor : Color.clear)
                            )
                            .foregroundStyle(alertsManager.selectedFilter == filter ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule().fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
            )
            
            Spacer()
            
            if !alertsManager.alerts.isEmpty {
                Button {
                    alertsManager.clearAllAlerts()
                } label: {
                    Text("Clear All")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Alerts List
    private var alertsListView: some View {
        VStack(spacing: 12) {
            ForEach(alertsManager.filteredAlerts) { alert in
                alertCard(alert)
            }
        }
    }
    
    private func alertCard(_ alert: SystemAlert) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Severity Icon Pillar
            ZStack {
                Circle()
                    .fill(alert.severity.color.opacity(alert.isResolved ? 0.1 : 0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: alert.isResolved ? "checkmark" : alert.type.iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(alert.isResolved ? Color.secondary : alert.severity.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(alert.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(alert.metricValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(alert.severity.color.opacity(0.15))
                        )
                        .foregroundStyle(alert.severity.color)
                    
                    if alert.isResolved {
                        Text("Resolved")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(alert.severity.color)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(alert.severity.color)
                        }
                    }
                    
                    Spacer()
                    
                    Text(relativeTimeString(from: alert.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                
                Text(alert.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Footer details & actions
                HStack(spacing: 12) {
                    if let appName = alert.culpritAppName {
                        HStack(spacing: 5) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(appName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary)
                            if let pid = alert.culpritPID {
                                Text("PID \(pid)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.04))
                        )
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    if !alert.isResolved {
                        if let culprit = alert.culpritAppName,
                           let appGroup = hub.appGroups.first(where: { $0.name == culprit || $0.processes.contains { $0.name == culprit } }) {
                            Button {
                                appState.inspectedApp = appGroup
                            } label: {
                                Text("Inspect Process")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Button {
                            alertsManager.dismissAlert(alert)
                        } label: {
                            Text("Dismiss")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button {
                            alertsManager.deleteAlert(alert)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(alert.isResolved ? Color.primary.opacity(0.04) : alert.severity.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }
            .padding(.top, 40)
            
            VStack(spacing: 6) {
                Text("All Systems Nominal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("No sustained processor spikes, thermal warnings, or memory pressure detected.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            
            // Sensor Checkmarks
            HStack(spacing: 20) {
                sensorCheck(name: "CPU", value: String(format: "%.1f%%", hub.cpu.totalPercent))
                sensorCheck(name: "Memory", value: hub.memory.pressureState.rawValue)
                sensorCheck(name: "Disk", value: String(format: "%.0f GB", Double(hub.disk.freeSpaceBytes) / 1_073_741_824.0))
                sensorCheck(name: "Thermals", value: hub.gpu.thermalState.rawValue)
            }
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
    }
    
    private func sensorCheck(name: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
            Text("\(name): \(value)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Alert Thresholds Sheet
    private var alertThresholdsSheet: some View {
        @Bindable var mgr = alertsManager
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alert Trigger Thresholds")
                        .font(.system(size: 16, weight: .bold))
                    Text("Customize sustained resource limits that trigger system warnings.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    showingSettingsSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("CPU Spike Limit")
                            .font(.system(size: 13, weight: .medium))
                        Text("Trigger alert when CPU load stays above this percentage.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f%%", mgr.cpuThresholdPercent))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Slider(value: $mgr.cpuThresholdPercent, in: 50...98, step: 5)
                        .frame(width: 140)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Low Disk Warning")
                            .font(.system(size: 13, weight: .medium))
                        Text("Trigger alert when free startup disk drops below.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f GB", mgr.lowDiskThresholdGB))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Slider(value: $mgr.lowDiskThresholdGB, in: 5...50, step: 5)
                        .frame(width: 140)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("High Battery Draw")
                            .font(.system(size: 13, weight: .medium))
                        Text("Alert when running on battery with discharge rate exceeding.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f W", mgr.batteryDrainThresholdWatts))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Slider(value: $mgr.batteryDrainThresholdWatts, in: 15...60, step: 5)
                        .frame(width: 140)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 480, height: 340)
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
