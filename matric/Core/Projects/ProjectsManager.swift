import Foundation
import SwiftUI
import Observation
import AppKit

@Observable
@MainActor
public final class ProjectsManager {
    public static let shared = ProjectsManager()
    
    public var projects: [DevProjectRecord] = []
    public var portEntries: [PortInspectionItem] = []
    public var isScanning: Bool = false
    public var includeRuntimesWithoutPorts: Bool = true
    public var selectedCategory: DevProjectCategory = .all
    public var sortOption: DevProjectSortOption = .ports
    public var viewMode: DevProjectViewMode = .cards
    public var searchText: String = ""
    public var lastScannedAt: Date?
    
    // Quick Port Inspector Modal
    public var isShowingPortChecker: Bool = false
    public var portCheckInput: String = ""
    public var portCheckStatus: PortCheckStatus? = nil
    
    public enum PortCheckStatus: Equatable {
        case idle
        case checking
        case free(port: Int)
        case occupied(
            port: Int,
            pid: pid_t,
            processName: String,
            user: String,
            cpuPercent: Double,
            memoryBytes: UInt64,
            workingDir: String?,
            command: String
        )
    }
    
    public var hasCursor: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") != nil ||
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cursor.Cursor") != nil ||
        FileManager.default.fileExists(atPath: "/Applications/Cursor.app")
    }
    
    public var hasVSCode: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") != nil ||
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCodeInsiders") != nil ||
        FileManager.default.fileExists(atPath: "/Applications/Visual Studio Code.app")
    }
    
    public init() {
        refreshProjects()
    }
    
    // MARK: - Feature 1: Real-Time Metric Aggregation Engine
    
    /// Count of active developer services and runtimes.
    public var activeServicesCount: Int {
        projects.count
    }
    public var totalActiveServers: Int {
        activeServicesCount
    }
    
    /// Unique count of active TCP listening ports (:3000, :5173, etc.).
    public var openPortsCount: Int {
        var set = Set<Int>()
        for p in projects {
            set.formUnion(p.listeningPorts)
        }
        return set.count
    }
    public var totalListeningPorts: Int {
        openPortsCount
    }
    
    /// Aggregate RAM (RSS) consumed across all dev processes.
    public var totalDevMemoryBytes: UInt64 {
        projects.reduce(0) { $0 + $1.memoryBytes }
    }
    
    public var formattedDevMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(totalDevMemoryBytes))
    }
    
    /// Combined CPU utilization across all dev processes.
    public var totalDevCpuPercent: Double {
        projects.reduce(0.0) { $0 + $1.cpuPercent }
    }
    public var totalDevCPU: Double {
        totalDevCpuPercent
    }
    
    /// Updates live CPU and Memory vitals from the 1-second system telemetry tick without re-scanning disks
    public func updateVitals(with processes: [ProcessRecord]) {
        guard !projects.isEmpty else { return }
        let map = Dictionary(processes.map { ($0.pid, $0) }, uniquingKeysWith: { first, _ in first })
        
        for i in 0..<projects.count {
            let pid = projects[i].pid
            if let proc = map[pid] {
                projects[i].cpuPercent = proc.cpuPercent
                projects[i].memoryBytes = proc.memoryBytes
            }
        }
        
        for i in 0..<portEntries.count {
            let pid = portEntries[i].pid
            if let proc = map[pid] {
                portEntries[i].cpuPercent = proc.cpuPercent
                portEntries[i].memoryBytes = proc.memoryBytes
            }
        }
    }
    
    // MARK: - Feature 3: Smart Filtering & Organization
    
    /// Count of matching projects for a specific category
    public func projectCount(for category: DevProjectCategory) -> Int {
        if category == .all {
            return includeRuntimesWithoutPorts ? projects.count : projects.filter { !$0.listeningPorts.isEmpty }.count
        }
        return projects.filter { p in
            if !includeRuntimesWithoutPorts && p.listeningPorts.isEmpty { return false }
            return p.category == category
        }.count
    }
    
    /// Count of matching ports for a specific category
    public func portCount(for category: DevProjectCategory) -> Int {
        if category == .all {
            return portEntries.count
        }
        return portEntries.filter { $0.runtime.category == category }.count
    }
    
    public var filteredProjects: [DevProjectRecord] {
        let rawQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let queryCleanPort = rawQuery.hasPrefix(":") ? String(rawQuery.dropFirst()) : rawQuery
        
        let list = projects.filter { project in
            if !includeRuntimesWithoutPorts && project.listeningPorts.isEmpty {
                return false
            }
            if selectedCategory != .all && project.category != selectedCategory {
                return false
            }
            if rawQuery.isEmpty { return true }
            return project.projectName.lowercased().contains(rawQuery) ||
                   project.projectPath.lowercased().contains(rawQuery) ||
                   project.runtime.rawValue.lowercased().contains(rawQuery) ||
                   (project.gitBranch?.lowercased().contains(rawQuery) ?? false) ||
                   project.listeningPorts.contains { "\($0)".contains(queryCleanPort) }
        }
        
        return list.sorted { a, b in
            switch sortOption {
            case .ports:
                let aPort = a.listeningPorts.first ?? 999999
                let bPort = b.listeningPorts.first ?? 999999
                if !a.listeningPorts.isEmpty && b.listeningPorts.isEmpty { return true }
                if a.listeningPorts.isEmpty && !b.listeningPorts.isEmpty { return false }
                return aPort < bPort
            case .cpu:
                return a.cpuPercent > b.cpuPercent
            case .memory:
                return a.memoryBytes > b.memoryBytes
            case .name:
                return a.projectName.localizedCaseInsensitiveCompare(b.projectName) == .orderedAscending
            }
        }
    }
    
    public var filteredPortEntries: [PortInspectionItem] {
        let rawQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let queryCleanPort = rawQuery.hasPrefix(":") ? String(rawQuery.dropFirst()) : rawQuery
        
        let list = portEntries.filter { item in
            if selectedCategory != .all && item.runtime.category != selectedCategory {
                return false
            }
            if rawQuery.isEmpty { return true }
            return "\(item.port)".contains(queryCleanPort) ||
                   item.projectName.lowercased().contains(rawQuery) ||
                   item.processName.lowercased().contains(rawQuery) ||
                   item.projectPath.lowercased().contains(rawQuery) ||
                   (item.gitBranch?.lowercased().contains(rawQuery) ?? false) ||
                   item.runtime.rawValue.lowercased().contains(rawQuery)
        }
        
        return list.sorted { a, b in
            switch sortOption {
            case .ports:
                return a.port < b.port
            case .cpu:
                return a.cpuPercent > b.cpuPercent
            case .memory:
                return a.memoryBytes > b.memoryBytes
            case .name:
                return a.projectName.localizedCaseInsensitiveCompare(b.projectName) == .orderedAscending
            }
        }
    }
    
    public func refreshProjects() {
        guard !isScanning else { return }
        isScanning = true
        
        Task.detached(priority: .userInitiated) {
            let scanner = PortScanner()
            let cwdResolver = WorkingDirResolver()
            let classifier = DevRuntimeClassifier()
            let procScanner = ProcessScanner()
            
            // 1. Scan listening TCP ports
            let portMap = scanner.scanListeningPorts()
            
            // 2. Scan active processes
            let rawProcesses = procScanner.scan()
            
            // 3. Known development executables or processes with listening ports
            let devKeywords = ["node", "bun", "deno", "python", "python3", "uvicorn", "vite", "next-server", "go", "cargo", "ruby", "rails", "puma", "postgres", "redis-server", "docker", "mongod", "mysqld", "cloudflared", "code helper", "t3 code"]
            
            var discovered: [DevProjectRecord] = []
            var flatPorts: [PortInspectionItem] = []
            
            for proc in rawProcesses {
                let nameLower = proc.name.lowercased()
                let hasListeningPort = portMap[proc.pid] != nil
                let isDevExecutable = devKeywords.contains { nameLower.contains($0) }
                
                // If it has listening ports or is a known dev executable
                if hasListeningPort || isDevExecutable {
                    let ports = portMap[proc.pid] ?? []
                    
                    // Skip generic background system daemons
                    if !isDevExecutable && (proc.name == "rapportd" || proc.name.hasPrefix("ControlCe") || proc.name == "Raycast" || proc.name == "OneDrive" || proc.name == "figma_agent") {
                        continue
                    }
                    
                    // Resolve working directory
                    let cwd = cwdResolver.resolveCWD(for: proc.pid)
                    let dirPath = cwd ?? (nameLower.contains("code") ? "VS Code Remote Session" : "~/Projects")
                    
                    var projName = cwdResolver.projectName(from: dirPath, fallback: proc.name)
                    if projName == "/" || projName.isEmpty {
                        projName = proc.name
                    }
                    
                    // Resolve git branch if valid directory
                    let branch = cwd != nil ? cwdResolver.resolveGitBranch(for: dirPath) : nil
                    
                    // Classify runtime
                    let runtime = classifier.classify(processName: proc.name, command: proc.name, workingDir: cwd)
                    
                    // Filter out non-dev processes that happen to open ports unless classified
                    if runtime == .generic && !isDevExecutable && ports.isEmpty {
                        continue
                    }
                    
                    let record = DevProjectRecord(
                        projectName: projName,
                        projectPath: dirPath,
                        gitBranch: branch,
                        runtime: runtime,
                        pid: proc.pid,
                        command: proc.name,
                        fullCommand: proc.name,
                        listeningPorts: ports,
                        cpuPercent: proc.cpuPercent,
                        memoryBytes: proc.memoryBytes
                    )
                    discovered.append(record)
                    
                    // Build ports table items
                    for port in ports {
                        flatPorts.append(PortInspectionItem(
                            port: port,
                            status: "LISTEN",
                            projectName: projName,
                            projectPath: dirPath,
                            gitBranch: branch,
                            runtime: runtime,
                            pid: proc.pid,
                            processName: proc.name,
                            cpuPercent: proc.cpuPercent,
                            memoryBytes: proc.memoryBytes
                        ))
                    }
                }
            }
            
            // Sort flat ports numerically
            flatPorts.sort { $0.port < $1.port }
            
            await MainActor.run {
                self.projects = discovered
                self.portEntries = flatPorts
                self.isScanning = false
                self.lastScannedAt = Date()
            }
        }
    }
    
    // MARK: - Feature 6: Port Inspector Utility Logic
    public func inspectCustomPort() {
        let clean = portCheckInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ":", with: "")
        if let port = Int(clean) {
            checkPortAvailability(port)
        }
    }
    
    public func checkPortAvailability(_ port: Int) {
        guard port > 0 && port <= 65535 else { return }
        portCheckStatus = .checking
        
        Task.detached(priority: .userInitiated) {
            let scanner = PortScanner()
            let procScanner = ProcessScanner()
            let cwdResolver = WorkingDirResolver()
            
            let portMap = scanner.scanListeningPorts()
            let processes = procScanner.scan()
            let procDict = Dictionary(processes.map { ($0.pid, $0) }, uniquingKeysWith: { a, _ in a })
            
            var occupiedPID: pid_t?
            for (pid, ports) in portMap {
                if ports.contains(port) {
                    occupiedPID = pid
                    break
                }
            }
            
            await MainActor.run {
                if let pid = occupiedPID {
                    let proc = procDict[pid]
                    let name = proc?.name ?? "Unknown Process"
                    let user = ProjectsManager.resolveProcessUser(pid: pid)
                    let cwd = cwdResolver.resolveCWD(for: pid)
                    let cpu = proc?.cpuPercent ?? 0.0
                    let mem = proc?.memoryBytes ?? 0
                    
                    self.portCheckStatus = .occupied(
                        port: port,
                        pid: pid,
                        processName: name,
                        user: user,
                        cpuPercent: cpu,
                        memoryBytes: mem,
                        workingDir: cwd,
                        command: name
                    )
                } else {
                    self.portCheckStatus = .free(port: port)
                }
            }
        }
    }
    
    private nonisolated static func resolveProcessUser(pid: pid_t) -> String {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        if proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size {
            if let pw = getpwuid(info.pbi_uid) {
                return String(cString: pw.pointee.pw_name)
            }
        }
        return NSUserName()
    }
    
    public func killProcessHoldingPort(pid: pid_t, port: Int, force: Bool = false) {
        let signal = force ? SIGKILL : SIGTERM
        kill(pid, signal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.checkPortAvailability(port)
            self.refreshProjects()
        }
    }
    
    // MARK: - Process Lifecycle Actions
    public func stopProject(_ project: DevProjectRecord, force: Bool = false) {
        let signal = force ? SIGKILL : SIGTERM
        kill(project.pid, signal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.refreshProjects()
        }
    }
    
    public func stopPort(port: Int, force: Bool = false) {
        if let entry = portEntries.first(where: { $0.port == port }) {
            let signal = force ? SIGKILL : SIGTERM
            kill(entry.pid, signal)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.refreshProjects()
            }
        }
    }
    
    // MARK: - Feature 5: 1-Click Developer Actions
    public func openInBrowser(port: Int) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    public func openInCursor(_ project: DevProjectRecord) {
        openPathInCursor(project.projectPath)
    }
    
    public func openPathInCursor(_ path: String) {
        let url = URL(fileURLWithPath: path)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") ??
                        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cursor.Cursor") ??
                        (FileManager.default.fileExists(atPath: "/Applications/Cursor.app") ? URL(fileURLWithPath: "/Applications/Cursor.app") : nil) {
            if FileManager.default.fileExists(atPath: appURL.path) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        // Fallback to CLI command
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["cursor", path]
        try? task.run()
    }
    
    public func openInVSCode(_ project: DevProjectRecord) {
        openPathInVSCode(project.projectPath)
    }
    
    public func openPathInVSCode(_ path: String) {
        let url = URL(fileURLWithPath: path)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") ??
                        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCodeInsiders") ??
                        (FileManager.default.fileExists(atPath: "/Applications/Visual Studio Code.app") ? URL(fileURLWithPath: "/Applications/Visual Studio Code.app") : nil) {
            if FileManager.default.fileExists(atPath: appURL.path) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        // Fallback to CLI command
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["code", path]
        try? task.run()
    }
    
    public func openInTerminal(_ project: DevProjectRecord) {
        openPathInTerminal(project.projectPath)
    }
    
    public func openPathInTerminal(_ path: String) {
        let escaped = path.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "cd \"\(escaped)\""
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
    
    public func revealInFinder(_ project: DevProjectRecord) {
        revealPathInFinder(project.projectPath)
    }
    
    public func revealPathInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
