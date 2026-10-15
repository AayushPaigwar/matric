import SwiftUI
import AppKit

public struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @State private var projectsManager = ProjectsManager.shared
    
    // Stop confirmation state
    @State private var projectToStop: DevProjectRecord?
    @State private var showStopConfirmation: Bool = false
    @State private var portToStop: Int?
    @State private var showPortStopConfirmation: Bool = false
    
    // Feedback toast state
    @State private var copiedFeedback: String?
    
    // Row hover state for Ports Table
    @State private var hoveredRowID: String?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Feature 1: KPI Summary Metrics Bar
            kpiSummaryBar
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Feature 3: Filter, Category & View Control Bar
            controlToolbar
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
            
            // Main Content: Cards or Ports Table (Feature 2)
            ScrollView {
                VStack(spacing: 16) {
                    if projectsManager.viewMode == .cards {
                        cardsContentView
                            .transition(.opacity)
                    } else {
                        portsTableContentView
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(.easeInOut(duration: 0.18), value: projectsManager.viewMode)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
        .overlay(alignment: .bottom) {
            if let feedback = copiedFeedback {
                Text(feedback)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .shadow(radius: 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $projectsManager.isShowingPortChecker) {
            portCheckerSheet
        }
        .onAppear {
            projectsManager.refreshProjects()
        }
        // Project Stop Confirmation
        .confirmationDialog(
            "Stop Development Server?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible,
            presenting: projectToStop
        ) { project in
            Button("Gracefully Stop (SIGTERM)") {
                projectsManager.stopProject(project, force: false)
            }
            Button("Force Kill (SIGKILL)", role: .destructive) {
                projectsManager.stopProject(project, force: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: { project in
            Text("Stop \(project.projectName) (PID \(project.pid)) and release its ports?")
        }
        // Port Stop Confirmation
        .confirmationDialog(
            "Release Port?",
            isPresented: $showPortStopConfirmation,
            titleVisibility: .visible,
            presenting: portToStop
        ) { port in
            Button("Graceful Stop (SIGTERM)") {
                projectsManager.stopPort(port: port, force: false)
            }
            Button("Force Kill (SIGKILL)", role: .destructive) {
                projectsManager.stopPort(port: port, force: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: { port in
            Text("Terminate the process currently occupying port \(port)?")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.orange)
                    
                    Text("Developer Projects")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(projectsManager.activeServicesCount) Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                }
                
                Text("Automatic Discovery of Local Dev Servers, Listening Ports & Workspace Runtimes")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // Check Port Utility Button
                Button {
                    projectsManager.portCheckInput = ""
                    projectsManager.portCheckStatus = .idle
                    projectsManager.isShowingPortChecker = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "network.badge.shield.half.filled")
                            .font(.system(size: 12))
                        Text("Check Port...")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .help("Inspect if a specific port is free or occupied")
                
                // Refresh Button
                Button {
                    projectsManager.refreshProjects()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(projectsManager.isScanning ? 360 : 0))
                            .animation(projectsManager.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: projectsManager.isScanning)
                        
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Feature 1: KPI Summary Metrics Bar
    private var kpiSummaryBar: some View {
        HStack(spacing: 12) {
            KPIMetricCard(
                title: "ACTIVE SERVICES",
                value: "\(projectsManager.activeServicesCount)",
                icon: "server.rack",
                accentColor: .blue,
                subtitle: "Running dev servers & tools",
                badge: projectsManager.isScanning ? "Scanning..." : "\(projectsManager.activeServicesCount) online",
                badgeColor: projectsManager.isScanning ? .orange : .blue
            )
            
            KPIMetricCard(
                title: "OPEN TCP PORTS",
                value: "\(projectsManager.openPortsCount)",
                icon: "network",
                accentColor: .purple,
                subtitle: "Bound listening sockets",
                badge: projectsManager.openPortsCount > 0 ? "\(projectsManager.openPortsCount) active" : "None",
                badgeColor: .purple
            )
            
            KPIMetricCard(
                title: "DEV MEMORY USAGE",
                value: projectsManager.formattedDevMemory,
                icon: "memorychip",
                accentColor: .cyan,
                subtitle: "Resident RAM footprint",
                badge: projectsManager.totalDevMemoryBytes > 2_000_000_000 ? "High" : "Normal",
                badgeColor: projectsManager.totalDevMemoryBytes > 2_000_000_000 ? .orange : .cyan
            )
            
            KPIMetricCard(
                title: "DEV CPU LOAD",
                value: String(format: "%.1f%%", projectsManager.totalDevCpuPercent),
                icon: "cpu",
                accentColor: projectsManager.totalDevCpuPercent > 20 ? .orange : .indigo,
                subtitle: "Combined dev load",
                badge: projectsManager.totalDevCpuPercent > 20 ? "High Load" : "Nominal",
                badgeColor: projectsManager.totalDevCpuPercent > 20 ? .orange : .green
            )
        }
    }
    
    // MARK: - Feature 3: Smart Filtering & Organization Toolbar
    private var controlToolbar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Category Filter Pills (3.1)
                HStack(spacing: 6) {
                    ForEach(DevProjectCategory.allCases) { cat in
                        let count = projectsManager.viewMode == .cards ? projectsManager.projectCount(for: cat) : projectsManager.portCount(for: cat)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                projectsManager.selectedCategory = cat
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 11))
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: projectsManager.selectedCategory == cat ? .semibold : .regular))
                                
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(
                                            Capsule()
                                                .fill(projectsManager.selectedCategory == cat ? Color.orange.opacity(0.3) : Color.primary.opacity(0.08))
                                        )
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(projectsManager.selectedCategory == cat ? Color.orange.opacity(0.18) : Color.clear)
                            )
                            .foregroundStyle(projectsManager.selectedCategory == cat ? Color.orange : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // View Mode Switcher (Cards vs Table)
                Picker("", selection: $projectsManager.viewMode) {
                    ForEach(DevProjectViewMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
            
            HStack(spacing: 12) {
                // Live Search Input (3.3)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                    
                    TextField("Filter by project name, port (:3000), branch, or path...", text: $projectsManager.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                    
                    if !projectsManager.searchText.isEmpty {
                        let resultCount = projectsManager.viewMode == .cards ? projectsManager.filteredProjects.count : projectsManager.filteredPortEntries.count
                        Text("\(resultCount) found")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                projectsManager.searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
                
                // Multi-Attribute Sorting Menu (3.2)
                Menu {
                    ForEach(DevProjectSortOption.allCases) { opt in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                projectsManager.sortOption = opt
                            }
                        } label: {
                            HStack {
                                Text(opt.rawValue)
                                if projectsManager.sortOption == opt {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11))
                        Text("Sort: \(projectsManager.sortOption.rawValue)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                // Toggle Include Idle Runtimes
                Toggle(isOn: $projectsManager.includeRuntimesWithoutPorts) {
                    Text("Idle runtimes")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.checkbox)
            }
        }
    }
    
    // MARK: - Feature 2: Cards Content View
    @ViewBuilder
    private var cardsContentView: some View {
        if projectsManager.filteredProjects.isEmpty {
            emptyStateView
        } else {
            LazyVStack(spacing: 14) {
                ForEach(projectsManager.filteredProjects) { project in
                    ProjectCardView(
                        project: project,
                        hasCursor: projectsManager.hasCursor,
                        hasVSCode: projectsManager.hasVSCode,
                        onOpenBrowser: { port in projectsManager.openInBrowser(port: port) },
                        onCopyURL: { port in
                            let urlStr = "http://localhost:\(port)"
                            projectsManager.copyToClipboard(urlStr)
                            showToast("Copied \(urlStr)")
                        },
                        onCopyPath: {
                            projectsManager.copyToClipboard(project.projectPath)
                            showToast("Copied path")
                        },
                        onOpenCursor: { projectsManager.openInCursor(project) },
                        onOpenVSCode: { projectsManager.openInVSCode(project) },
                        onOpenTerminal: { projectsManager.openInTerminal(project) },
                        onReveal: { projectsManager.revealInFinder(project) },
                        onStop: {
                            projectToStop = project
                            showStopConfirmation = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Feature 2: High-Density Ports Table View
    @ViewBuilder
    private var portsTableContentView: some View {
        if projectsManager.filteredPortEntries.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 12) {
                    Text("PORT")
                        .frame(width: 80, alignment: .leading)
                    Text("STATUS")
                        .frame(width: 80, alignment: .leading)
                    Text("SERVICE / RUNTIME")
                        .frame(width: 160, alignment: .leading)
                    Text("PROJECT / PATH")
                        .frame(minWidth: 200, alignment: .leading)
                    Text("PID")
                        .frame(width: 70, alignment: .leading)
                    Text("RESOURCE")
                        .frame(width: 130, alignment: .leading)
                    Spacer()
                    Text("ACTIONS")
                        .frame(width: 120, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Table Rows
                ForEach(projectsManager.filteredPortEntries) { entry in
                    HStack(spacing: 12) {
                        // Port with Click-to-Copy URL shortcut
                        Button {
                            let urlStr = "http://localhost:\(entry.port)"
                            projectsManager.copyToClipboard(urlStr)
                            showToast("Copied \(urlStr)")
                        } label: {
                            HStack(spacing: 4) {
                                Text(":\(entry.port)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.cyan)
                                
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.cyan.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Click to copy http://localhost:\(entry.port)")
                        .frame(width: 80, alignment: .leading)
                        
                        // Status: LISTEN socket indicator
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(entry.status)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                        .frame(width: 80, alignment: .leading)
                        
                        // Service & Framework
                        HStack(spacing: 6) {
                            Image(systemName: entry.runtime.iconName)
                                .font(.system(size: 11))
                                .foregroundStyle(entry.runtime.themeColor)
                            Text(entry.runtime.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .frame(width: 160, alignment: .leading)
                        
                        // Project, Git Branch & Path
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(entry.projectName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                
                                if let branch = entry.gitBranch {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.triangle.branch")
                                            .font(.system(size: 8))
                                        Text(branch)
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    }
                                    .foregroundStyle(Color.purple)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.purple.opacity(0.1)))
                                }
                            }
                            
                            Button {
                                projectsManager.copyToClipboard(entry.projectPath)
                                showToast("Copied path")
                            } label: {
                                HStack(spacing: 4) {
                                    Text(entry.projectPath)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 7))
                                        .foregroundStyle(.secondary.opacity(0.4))
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Click to copy directory path")
                        }
                        .frame(minWidth: 200, alignment: .leading)
                        
                        // PID
                        Text("\(entry.pid)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        
                        // Resource: CPU% + RAM
                        HStack(spacing: 6) {
                            Text(String(format: "%.1f%%", entry.cpuPercent))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(entry.cpuPercent > 20 ? Color.orange : Color.secondary)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(entry.memoryFormatted)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 130, alignment: .leading)
                        
                        Spacer()
                        
                        // Direct Inline Actions
                        HStack(spacing: 6) {
                            if entry.isHTTP {
                                Button {
                                    projectsManager.openInBrowser(port: entry.port)
                                } label: {
                                    Image(systemName: "arrow.up.forward.app")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.cyan)
                                        .frame(width: 26, height: 26)
                                        .background(Circle().fill(Color.cyan.opacity(0.1)))
                                }
                                .buttonStyle(.plain)
                                .help("Open http://localhost:\(entry.port) in Browser")
                            }
                            
                            Button {
                                let urlStr = "http://localhost:\(entry.port)"
                                projectsManager.copyToClipboard(urlStr)
                                showToast("Copied \(urlStr)")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.cyan)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color.cyan.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                            .help("Copy localhost URL")
                            
                            Button {
                                projectsManager.openPathInTerminal(entry.projectPath)
                            } label: {
                                Image(systemName: "terminal")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color.primary.opacity(0.05)))
                            }
                            .buttonStyle(.plain)
                            .help("Open Terminal at Project Path")
                            
                            Button {
                                portToStop = entry.port
                                showPortStopConfirmation = true
                            } label: {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color.red.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                            .help("Stop or Kill Process Holding Port")
                        }
                        .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(hoveredRowID == entry.id ? Color.primary.opacity(0.04) : Color.clear)
                    .onHover { isHovered in
                        hoveredRowID = isHovered ? entry.id : nil
                    }
                    
                    Divider()
                        .opacity(0.4)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Port Checker Sheet
    private var portCheckerSheet: some View {
        VStack(spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 18))
                        .foregroundStyle(.orange)
                    Text("Port Availability Checker")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Button {
                    projectsManager.isShowingPortChecker = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Enter a local TCP port to inspect which process is currently listening, or verify if it is completely available for your dev server.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                TextField("Port number (e.g. 3000, 8080, 5432)", text: $projectsManager.portCheckInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .onSubmit {
                        projectsManager.inspectCustomPort()
                    }
                
                Button("Check Port") {
                    projectsManager.inspectCustomPort()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            if let status = projectsManager.portCheckStatus {
                switch status {
                case .idle:
                    EmptyView()
                case .checking:
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Inspecting socket...")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                case .free(let port):
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Port \(port) is Available")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.green)
                            Text("No local process is currently binding to this TCP port.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.1)))
                case .occupied(let port, let pid, let name, _):
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Port \(port) is In Use")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.orange)
                                Text("Occupied by **\(name)** (PID \(pid)).")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            Button("Kill Process", role: .destructive) {
                                kill(pid, SIGTERM)
                                projectsManager.portCheckStatus = .free(port: port)
                                projectsManager.refreshProjects()
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                }
            }
        }
        .padding(20)
        .frame(width: 440)
    }
    
    private func showToast(_ message: String) {
        withAnimation {
            copiedFeedback = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                if copiedFeedback == message {
                    copiedFeedback = nil
                }
            }
        }
    }
    
    // MARK: - Empty & Filter State
    private var emptyStateView: some View {
        let isFiltered = !projectsManager.searchText.isEmpty || projectsManager.selectedCategory != .all
        
        return VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 68, height: 68)
                
                Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle" : "terminal")
                    .font(.system(size: 30))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 6) {
                Text(isFiltered ? "No Matching Services Found" : "No Active Development Servers Found")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                
                if isFiltered {
                    Text("No services match the active filter for '\(projectsManager.selectedCategory.rawValue)'\(projectsManager.searchText.isEmpty ? "" : " with search query \"\(projectsManager.searchText)\"").")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                } else {
                    Text("Start your dev server (e.g. `npm run dev`, `vite`, `cargo run`, `fastapi dev`, `python manage.py runserver`) and Matric will automatically discover its listening ports, git branch, and directory.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }
            }
            
            HStack(spacing: 10) {
                if isFiltered {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            projectsManager.searchText = ""
                            projectsManager.selectedCategory = .all
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                            Text("Reset Filters")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        projectsManager.refreshProjects()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Scan Again")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        projectsManager.portCheckInput = ""
                        projectsManager.portCheckStatus = .idle
                        projectsManager.isShowingPortChecker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "network.badge.shield.half.filled")
                            Text("Check Port")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - KPI Metric Card (Feature 1)
private struct KPIMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    var subtitle: String? = nil
    var badge: String? = nil
    var badgeColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(accentColor.opacity(0.14))
                    )
                
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.3)
                
                Spacer(minLength: 0)
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(badgeColor ?? accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((badgeColor ?? accentColor).opacity(0.12))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Project Card View (Feature 2 & 4 Polish)
private struct ProjectCardView: View {
    let project: DevProjectRecord
    let hasCursor: Bool
    let hasVSCode: Bool
    let onOpenBrowser: (Int) -> Void
    let onCopyURL: (Int) -> Void
    let onCopyPath: () -> Void
    let onOpenCursor: () -> Void
    let onOpenVSCode: () -> Void
    let onOpenTerminal: () -> Void
    let onReveal: () -> Void
    let onStop: () -> Void
    
    @State private var isShowingDetails: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card Top Row
            HStack(alignment: .center, spacing: 10) {
                // Online Pulsing Dot (if has listening ports)
                if project.isListening {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                        Text("ONLINE")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.1)))
                }
                
                // Framework Badge
                HStack(spacing: 5) {
                    Image(systemName: project.runtime.iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(project.runtime.rawValue)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(project.runtime.themeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(project.runtime.themeColor.opacity(0.12))
                )
                
                // Project Name
                Text(project.projectName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                
                // Git Branch Pill (if available)
                if let branch = project.gitBranch {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 10))
                        Text(branch)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(Color.purple)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
                
                // PID
                Text("PID \(project.pid)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                
                Spacer()
                
                // Resource usage pills
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f%%", project.cpuPercent))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(project.cpuPercent > 20 ? Color.orange : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.04)))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 10))
                        Text(project.formattedMemory)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.04)))
                }
                
                // Stop Button
                Button(action: onStop) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.red.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Stop or kill process")
            }
            
            // Listening Ports / URLs
            if !project.listeningPorts.isEmpty {
                HStack(spacing: 8) {
                    Text("PORTS:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    ForEach(project.listeningPorts, id: \.self) { port in
                        HStack(spacing: 4) {
                            Button {
                                onOpenBrowser(port)
                            } label: {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 5, height: 5)
                                    
                                    Text(":\(port)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.cyan)
                                    
                                    Image(systemName: "arrow.up.forward.app")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.cyan.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Open http://localhost:\(port) in browser")
                            
                            // Copy URL button
                            Button {
                                onCopyURL(port)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.cyan.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help("Copy URL")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
                .opacity(0.4)
            
            // Path Row & Quick IDE Launchers
            HStack(spacing: 10) {
                // Project Path with Click-to-Copy
                Button(action: onCopyPath) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        
                        Text(project.projectPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
                .help("Click to copy path")
                
                Spacer()
                
                // Quick Launchers (Cursor, VS Code, Terminal, Finder)
                HStack(spacing: 6) {
                    if hasCursor {
                        Button(action: onOpenCursor) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 10))
                                Text("Cursor")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                        .help("Open Project in Cursor")
                    }
                    
                    if hasVSCode {
                        Button(action: onOpenVSCode) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 10))
                                Text("VS Code")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                        .help("Open Project in VS Code")
                    }
                    
                    Button(action: onOpenTerminal) {
                        HStack(spacing: 4) {
                            Image(systemName: "terminal")
                                .font(.system(size: 10))
                            Text("Terminal")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                    .help("Open in Terminal")
                    
                    Button(action: onReveal) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.primary.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                    .help("Reveal in Finder")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProjectsView()
        .environment(AppState())
}
