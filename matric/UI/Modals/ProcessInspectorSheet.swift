import SwiftUI
import AppKit

public struct ProcessInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let appGroup: AppGroupRecord
    
    @State private var searchText: String = ""
    @State private var showForceQuitConfirmation: Bool = false
    
    public init(appGroup: AppGroupRecord) {
        self.appGroup = appGroup
    }
    
    private var filteredProcesses: [ProcessRecord] {
        let sorted = appGroup.processes.sorted {
            if $0.cpuPercent != $1.cpuPercent {
                return $0.cpuPercent > $1.cpuPercent
            }
            return $0.memoryBytes > $1.memoryBytes
        }
        
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            String($0.pid).contains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                if let icon = appGroup.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appGroup.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        Text("PID \(appGroup.rootPid)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        
                        if let bundleId = appGroup.bundleIdentifier {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(bundleId)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // KPI Cards Row
            HStack(spacing: 12) {
                kpiCard(
                    title: "PROCESSES",
                    value: "\(appGroup.processCount)",
                    subtext: "1 main + \(max(appGroup.processCount - 1, 0)) helpers",
                    icon: "square.stack.3d.up.fill",
                    color: .blue
                )
                
                kpiCard(
                    title: "TOTAL CPU",
                    value: appGroup.formattedCpu,
                    subtext: "Aggregate core load",
                    icon: "cpu",
                    color: .purple
                )
                
                kpiCard(
                    title: "PHYSICAL MEMORY",
                    value: appGroup.formattedMemory,
                    subtext: "Resident footprint",
                    icon: "memorychip",
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Search filter for sub-processes
            if appGroup.processCount > 4 {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter helper processes...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            
            // Processes Table
            VStack(spacing: 0) {
                // Table header
                HStack {
                    Text("SUB-PROCESS")
                        .frame(minWidth: 160, alignment: .leading)
                    Spacer()
                    Text("PID")
                        .frame(width: 70, alignment: .trailing)
                    Text("CPU")
                        .frame(width: 80, alignment: .trailing)
                    Text("MEMORY")
                        .frame(width: 90, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                
                Divider()
                
                // Table content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredProcesses) { proc in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(proc.name)
                                        .font(.system(size: 12, weight: proc.pid == appGroup.rootPid ? .semibold : .regular))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    if proc.pid == appGroup.rootPid {
                                        Text("Parent Application Process")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .frame(minWidth: 160, alignment: .leading)
                                
                                Spacer()
                                
                                Text("\(proc.pid)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .trailing)
                                
                                Text(String(format: "%.1f%%", proc.cpuPercent))
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(proc.cpuPercent > 10 ? .orange : .primary)
                                    .frame(width: 80, alignment: .trailing)
                                
                                Text(formatBytes(proc.memoryBytes))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .frame(width: 90, alignment: .trailing)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                            
                            Divider()
                                .opacity(0.4)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            
            // Attribution Footnote
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Matric groups child helpers, renderers, and background workers under the parent application to reflect accurate aggregate consumption.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.2))
            
            Divider()
            
            // Bottom Action Bar
            HStack {
                if let bundleURL = appGroup.bundleURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button("Quit App") {
                    quitApp(force: false)
                }
                .buttonStyle(.bordered)
                
                Button("Force Quit...") {
                    showForceQuitConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(16)
        }
        .frame(width: 580, height: 520)
        .confirmationDialog(
            "Force Quit \(appGroup.name)?",
            isPresented: $showForceQuitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Force Quit", role: .destructive) {
                quitApp(force: true)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Any unsaved changes will be lost immediately. This sends SIGKILL to PID \(appGroup.rootPid) and all helper processes.")
        }
    }
    
    @ViewBuilder
    private func kpiCard(title: String, value: String, subtext: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(subtext)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
    
    private func quitApp(force: Bool) {
        if force {
            // Send SIGKILL to root process and child processes
            for p in appGroup.processes {
                kill(p.pid, SIGKILL)
            }
        } else {
            // Graceful termination
            if let running = NSRunningApplication(processIdentifier: appGroup.rootPid) {
                running.terminate()
            } else {
                kill(appGroup.rootPid, SIGTERM)
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
