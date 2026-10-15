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
        case occupied(port: Int, pid: pid_t, processName: String, command: String)
    }
    
    public var hasCursor: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") != nil
    }
    
    public var hasVSCode: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") != nil
    }
    
    public init() {
        refreshProjects()
    }
    
    // Aggregated Metrics
    public var totalActiveServers: Int {
        projects.count
    }
    
    public var totalListeningPorts: Int {
        var set = Set<Int>()
        for p in projects {
            set.formUnion(p.listeningPorts)
        }
        return set.count
    }
    
    public var totalDevMemoryBytes: UInt64 {
        projects.reduce(0) { $0 + $1.memoryBytes }
    }
    
    public var formattedDevMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(totalDevMemoryBytes))
    }
    
    public var totalDevCPU: Double {
        projects.reduce(0.0) { $0 + $1.cpuPercent }
    }
    
    public var filteredProjects: [DevProjectRecord] {
        let list = projects.filter { project in
            if !includeRuntimesWithoutPorts && project.listeningPorts.isEmpty {
                return false
            }
            if selectedCategory != .all && project.category != selectedCategory {
                return false
            }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return project.projectName.lowercased().contains(query) ||
                   project.projectPath.lowercased().contains(query) ||
                   project.runtime.rawValue.lowercased().contains(query) ||
                   (project.gitBranch?.lowercased().contains(query) ?? false) ||
                   project.listeningPorts.contains { "\($0)".contains(query) }
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
        if searchText.isEmpty {
            return portEntries
        }
        let q = searchText.lowercased()
        return portEntries.filter { item in
            "\(item.port)".contains(q) ||
            item.projectName.lowercased().contains(q) ||
            item.processName.lowercased().contains(q) ||
            item.runtime.rawValue.lowercased().contains(q)
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
                        listeningPorts: ports.sorted(),
                        cpuPercent: proc.cpuPercent,
                        memoryBytes: proc.memoryBytes
                    )
                    
                    discovered.append(record)
                    
                    // Populate flat ports table
                    for p in ports.sorted() {
                        let isWeb = (p >= 80 && p <= 90) || (p >= 3000 && p <= 9999) || p == 443 || p == 4200 || p == 5173
                        flatPorts.append(PortInspectionItem(
                            port: p,
                            pid: proc.pid,
                            processName: proc.name,
                            projectName: projName,
                            projectPath: dirPath,
                            runtime: runtime,
                            isHTTP: isWeb,
                            cpuPercent: proc.cpuPercent,
                            memoryFormatted: record.formattedMemory
                        ))
                    }
                }
            }
            
            let sortedPorts = flatPorts.sorted { $0.port < $1.port }
            
            await ProjectsManager.shared.applyDiscoveredProjects(discovered, ports: sortedPorts)
        }
    }
    
    private func applyDiscoveredProjects(_ results: [DevProjectRecord], ports: [PortInspectionItem]) {
        self.projects = results
        self.portEntries = ports
        self.lastScannedAt = Date()
        self.isScanning = false
    }
    
    public func stopProject(_ project: DevProjectRecord, force: Bool = false) {
        let sig = force ? SIGKILL : SIGTERM
        kill(project.pid, sig)
        
        withAnimation {
            projects.removeAll { $0.pid == project.pid }
            portEntries.removeAll { $0.pid == project.pid }
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            self.refreshProjects()
        }
    }
    
    public func stopPort(port: Int, force: Bool = false) {
        if let entry = portEntries.first(where: { $0.port == port }) {
            let sig = force ? SIGKILL : SIGTERM
            kill(entry.pid, sig)
            
            withAnimation {
                portEntries.removeAll { $0.port == port }
                if let idx = projects.firstIndex(where: { $0.pid == entry.pid }) {
                    let updated = projects[idx]
                    var remainingPorts = updated.listeningPorts
                    remainingPorts.removeAll { $0 == port }
                    if remainingPorts.isEmpty {
                        projects.remove(at: idx)
                    }
                }
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                self.refreshProjects()
            }
        }
    }
    
    public func openInBrowser(port: Int) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    public func revealInFinder(_ project: DevProjectRecord) {
        guard FileManager.default.fileExists(atPath: project.projectPath) else { return }
        let url = URL(fileURLWithPath: project.projectPath)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    
    public func openInCursor(_ project: DevProjectRecord) {
        guard FileManager.default.fileExists(atPath: project.projectPath) else { return }
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") {
            NSWorkspace.shared.open([URL(fileURLWithPath: project.projectPath)], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
    
    public func openInVSCode(_ project: DevProjectRecord) {
        guard FileManager.default.fileExists(atPath: project.projectPath) else { return }
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") {
            NSWorkspace.shared.open([URL(fileURLWithPath: project.projectPath)], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
    
    public func openInTerminal(_ project: DevProjectRecord) {
        let path = project.projectPath
        guard FileManager.default.fileExists(atPath: path) else { return }
        let script = "tell application \"Terminal\" to do script \"cd \(path.replacingOccurrences(of: "\"", with: "\\\""))\""
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
    
    public func inspectCustomPort() {
        guard let port = Int(portCheckInput.trimmingCharacters(in: .whitespaces)) else {
            return
        }
        portCheckStatus = .checking
        
        Task.detached(priority: .userInitiated) {
            let scanner = PortScanner()
            if let pid = scanner.inspectPort(port) {
                // Find process name
                let pNameTask = Process()
                pNameTask.launchPath = "/bin/ps"
                pNameTask.arguments = ["-p", "\(pid)", "-o", "comm="]
                let pipe = Pipe()
                pNameTask.standardOutput = pipe
                try? pNameTask.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let pName = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Process"
                
                await MainActor.run {
                    self.portCheckStatus = .occupied(port: port, pid: pid, processName: pName, command: pName)
                }
            } else {
                await MainActor.run {
                    self.portCheckStatus = .free(port: port)
                }
            }
        }
    }
}
