import SwiftUI

public struct SavedMomentsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    private var momentsManager = MomentsManager.shared
    
    @State private var showingCaptureSheet: Bool = false
    @State private var showingCompareSheet: Bool = false
    @State private var captureTitle: String = ""
    @State private var captureNotes: String = ""
    @State private var captureTag: String = "General"
    @State private var toastMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Tag Filter Bar & Quick Stats
                    filterAndStatusBar
                    
                    // Moments List or Empty State
                    if momentsManager.filteredMoments.isEmpty {
                        emptyStateView
                    } else {
                        momentsListView
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingCaptureSheet) {
            captureModalSheet
        }
        .sheet(isPresented: $showingCompareSheet) {
            compareMomentsSheet
        }
        .overlay(alignment: .bottom) {
            if let toast = toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 3)
                )
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Saved moments")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(momentsManager.moments.count) saved")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.06))
                        )
                }
                
                Text("Comprehensive system snapshots to benchmark performance and compare workloads.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                if momentsManager.moments.count >= 2 {
                    Button {
                        if momentsManager.comparisonMomentA == nil {
                            momentsManager.comparisonMomentA = momentsManager.moments.first
                            momentsManager.comparisonMomentB = momentsManager.moments.dropFirst().first
                        }
                        showingCompareSheet = true
                    } label: {
                        Label("Compare", systemImage: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    let df = DateFormatter()
                    df.dateFormat = "MMM d, h:mm a"
                    captureTitle = "Snapshot \(df.string(from: Date()))"
                    captureNotes = ""
                    captureTag = "General"
                    showingCaptureSheet = true
                } label: {
                    Label("Capture Moment", systemImage: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }
    
    // MARK: - Filter Bar
    private var filterAndStatusBar: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(momentsManager.availableTags, id: \.self) { tag in
                    Button {
                        momentsManager.selectedTag = tag
                    } label: {
                        Text(tag)
                            .font(.system(size: 12, weight: momentsManager.selectedTag == tag ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(momentsManager.selectedTag == tag ? Color.accentColor : Color.clear)
                            )
                            .foregroundStyle(momentsManager.selectedTag == tag ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule().fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
            )
            
            Spacer()
        }
    }
    
    // MARK: - Moments List
    private var momentsListView: some View {
        VStack(spacing: 14) {
            ForEach(momentsManager.filteredMoments) { moment in
                momentCard(moment)
            }
        }
    }
    
    private func momentCard(_ moment: SavedMoment) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card Top Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(moment.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(moment.tag)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    if !moment.notes.isEmpty {
                        Text(moment.notes)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Text(moment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Menu {
                        Button {
                            copyMomentSummary(moment)
                        } label: {
                            Label("Copy Summary", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            momentsManager.comparisonMomentA = moment
                            if let other = momentsManager.moments.first(where: { $0.id != moment.id }) {
                                momentsManager.comparisonMomentB = other
                            }
                            showingCompareSheet = true
                        } label: {
                            Label("Compare with another...", systemImage: "arrow.left.and.right")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            momentsManager.deleteMoment(moment)
                        } label: {
                            Label("Delete Moment", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                }
            }
            
            // Telemetry Pills Row
            HStack(spacing: 10) {
                metricPill(title: "CPU", value: String(format: "%.1f%%", moment.cpuPercent), icon: "cpu", color: .blue)
                metricPill(title: "Memory", value: moment.formattedMemoryUsed, icon: "memorychip", color: .green)
                metricPill(title: "GPU", value: String(format: "%.0f%%", moment.gpuUtilization), icon: "display", color: .purple)
                metricPill(title: "Network", value: moment.formattedNetworkSpeed, icon: "network", color: .cyan)
                metricPill(title: "Power", value: moment.isPluggedIn ? "AC Power" : "\(moment.batteryPercent)%", icon: "battery.100", color: .orange)
            }
            
            // Top Processes Strip
            if !moment.topApps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Top Processes at Snapshot")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        ForEach(moment.topApps.prefix(3)) { app in
                            HStack(spacing: 5) {
                                Text(app.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.primary)
                                
                                Text(String(format: "%.1f%%", app.cpuPercent))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.blue)
                                
                                Text(app.formattedMemory)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.04))
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func metricPill(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Capture Modal Sheet
    private var captureModalSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Capture System Moment")
                        .font(.system(size: 16, weight: .bold))
                    Text("Record full telemetry, CPU/Memory load, and active processes.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") {
                    showingCaptureSheet = false
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Snapshot Title")
                        .font(.system(size: 12, weight: .medium))
                    TextField("e.g. Idle Baseline, 4K Render, Full Test Run", text: $captureTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tag / Workload Category")
                        .font(.system(size: 12, weight: .medium))
                    
                    HStack(spacing: 6) {
                        ForEach(["General", "Baseline", "Build", "Gaming", "Stress Test"], id: \.self) { tag in
                            Button {
                                captureTag = tag
                            } label: {
                                Text(tag)
                                    .font(.system(size: 11, weight: captureTag == tag ? .semibold : .regular))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(captureTag == tag ? Color.accentColor : Color(nsColor: .controlBackgroundColor)))
                                    .foregroundStyle(captureTag == tag ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Notes (Optional)")
                        .font(.system(size: 12, weight: .medium))
                    TextField("Observations, external displays connected, etc.", text: $captureNotes)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Live Preview of Current Vitals to be Saved
            HStack(spacing: 12) {
                previewVitals(title: "CPU", val: String(format: "%.1f%%", hub.cpu.totalPercent))
                previewVitals(title: "RAM", val: formatBytes(hub.memory.workingBytes))
                previewVitals(title: "GPU", val: String(format: "%.0f%%", hub.gpu.utilizationPercent))
                previewVitals(title: "Apps", val: "\(hub.appGroups.count)")
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Save Snapshot") {
                    momentsManager.captureMoment(title: captureTitle, notes: captureNotes, tag: captureTag, hub: hub)
                    showingCaptureSheet = false
                    showToast("Snapshot saved successfully")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460, height: 380)
    }
    
    private func previewVitals(title: String, val: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(val)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Compare Moments Sheet
    private var compareMomentsSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compare System Moments")
                        .font(.system(size: 16, weight: .bold))
                    Text("Side-by-side telemetry differential between two recorded points in time.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    showingCompareSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            // Picker selectors for Moment A and B
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base Snapshot (A)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { momentsManager.comparisonMomentA ?? momentsManager.moments.first! },
                        set: { momentsManager.comparisonMomentA = $0 }
                    )) {
                        ForEach(momentsManager.moments) { m in
                            Text(m.title).tag(m)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Comparison Snapshot (B)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { momentsManager.comparisonMomentB ?? momentsManager.moments.last! },
                        set: { momentsManager.comparisonMomentB = $0 }
                    )) {
                        ForEach(momentsManager.moments) { m in
                            Text(m.title).tag(m)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            if let a = momentsManager.comparisonMomentA, let b = momentsManager.comparisonMomentB {
                let delta = momentsManager.calculateDelta(from: a, to: b)
                
                // Comparison Grid
                VStack(spacing: 12) {
                    compareRow(metric: "CPU Load", valA: String(format: "%.1f%%", a.cpuPercent), valB: String(format: "%.1f%%", b.cpuPercent), delta: delta.formattedCpuDelta, isNegativeGood: true)
                    compareRow(metric: "Memory Footprint", valA: a.formattedMemoryUsed, valB: b.formattedMemoryUsed, delta: delta.formattedMemoryDelta, isNegativeGood: true)
                    compareRow(metric: "GPU Utilization", valA: String(format: "%.0f%%", a.gpuUtilization), valB: String(format: "%.0f%%", b.gpuUtilization), delta: String(format: "%@%.0f%%", delta.gpuDelta >= 0 ? "+" : "", delta.gpuDelta), isNegativeGood: true)
                    compareRow(metric: "Network Total", valA: a.formattedNetworkSpeed, valB: b.formattedNetworkSpeed, delta: "", isNegativeGood: false)
                    compareRow(metric: "Free Disk Space", valA: a.formattedDiskAvailable, valB: b.formattedDiskAvailable, delta: "", isNegativeGood: false)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 580, height: 420)
    }
    
    private func compareRow(metric: String, valA: String, valB: String, delta: String, isNegativeGood: Bool) -> some View {
        HStack {
            Text(metric)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(valA)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(valB)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !delta.isEmpty {
                Text(delta)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(delta.hasPrefix("+") ? (isNegativeGood ? Color.red : Color.green) : Color.green)
                    .frame(width: 80, alignment: .trailing)
            } else {
                Spacer().frame(width: 80)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .padding(.top, 40)
            
            VStack(spacing: 6) {
                Text("No Saved Moments")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Take a snapshot of your Mac's resource state right now to bookmark performance or compare with future workloads.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            
            Button {
                momentsManager.captureMoment(title: "First Snapshot", hub: hub)
            } label: {
                Text("Capture Moment Now")
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
    }
    
    private func copyMomentSummary(_ moment: SavedMoment) {
        let summary = momentsManager.exportMomentSummary(moment)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        showToast("Moment summary copied to clipboard")
    }
    
    private func showToast(_ text: String) {
        withAnimation {
            toastMessage = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                if toastMessage == text {
                    toastMessage = nil
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
