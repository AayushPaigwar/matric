import Foundation
import AppKit

public final class ProcessTreeResolver {
    public init() {}
    
    public func resolve(processes: [ProcessRecord]) -> [AppGroupRecord] {
        let processMap: [pid_t: ProcessRecord] = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
        var claimedPids = Set<pid_t>()
        
        var appGroups: [String: AppGroupRecord] = [:]
        
        // 1. Resolve GUI & Background User Applications from NSWorkspace
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard let bundleURL = app.bundleURL ?? app.executableURL else { continue }
            let key = bundleURL.path
            let rootPid = app.processIdentifier
            let appName = app.localizedName ?? bundleURL.deletingPathExtension().lastPathComponent
            let icon = app.icon ?? NSWorkspace.shared.icon(forFile: key)
            
            var matchedProcs: [ProcessRecord] = []
            
            // Add root process if present
            if let rootProc = processMap[rootPid] {
                matchedProcs.append(rootProc)
                claimedPids.insert(rootPid)
            }
            
            // Collect helper/child daemons belonging to this app
            for proc in processes where !claimedPids.contains(proc.pid) && proc.pid != rootPid {
                let matchesBundle = proc.bundlePath?.hasPrefix(key) ?? false
                let matchesPath = !proc.executablePath.isEmpty && proc.executablePath.hasPrefix(key)
                let matchesPpid = proc.ppid == rootPid
                
                if matchesBundle || matchesPath || matchesPpid {
                    matchedProcs.append(proc)
                    claimedPids.insert(proc.pid)
                }
            }
            
            // Create or update record
            let record = AppGroupRecord(
                id: key,
                name: appName,
                bundleURL: bundleURL,
                bundleIdentifier: app.bundleIdentifier,
                icon: icon,
                rootPid: rootPid,
                isAppBundle: true,
                processes: matchedProcs
            )
            appGroups[key] = record
        }
        
        // 2. Discover remaining app bundles not registered in NSWorkspace (e.g. nested helpers)
        for proc in processes where !claimedPids.contains(proc.pid) {
            guard let bp = proc.bundlePath else { continue }
            let bundleURL = URL(fileURLWithPath: bp)
            let key = bp
            
            if var existing = appGroups[key] {
                existing.processes.append(proc)
                appGroups[key] = existing
                claimedPids.insert(proc.pid)
            } else {
                let cleanName = (bp as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                let icon = NSWorkspace.shared.icon(forFile: bp)
                let bundleId = Bundle(url: bundleURL)?.bundleIdentifier
                
                let newRecord = AppGroupRecord(
                    id: key,
                    name: cleanName.isEmpty ? proc.name : cleanName,
                    bundleURL: bundleURL,
                    bundleIdentifier: bundleId,
                    icon: icon,
                    rootPid: proc.pid,
                    isAppBundle: true,
                    processes: [proc]
                )
                appGroups[key] = newRecord
                claimedPids.insert(proc.pid)
            }
        }
        
        // 3. Group Standalone System / CLI Processes (WindowServer, launchd, node, python, etc.)
        let standaloneProcs = processes.filter { !claimedPids.contains($0.pid) }
        let groupedByName = Dictionary(grouping: standaloneProcs, by: { $0.name })
        
        var standaloneRecords: [AppGroupRecord] = []
        for (name, procs) in groupedByName {
            let totalMem = procs.reduce(0) { $0 + $1.memoryBytes }
            let totalCpu = procs.reduce(0.0) { $0 + $1.cpuPercent }
            
            // Include standalone processes with visible resource footprints or multi-process helpers
            if totalMem > 10 * 1024 * 1024 || totalCpu > 0.1 || procs.count >= 2 || name == "WindowServer" || name == "kernel_task" {
                let root = procs.first?.pid ?? 0
                let systemIcon: NSImage
                if name.contains("node") || name.contains("bun") || name.contains("deno") {
                    systemIcon = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: name) ?? NSWorkspace.shared.icon(forFile: "/bin/zsh")
                } else if name.contains("python") || name.contains("ruby") || name.contains("go") {
                    systemIcon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: name) ?? NSWorkspace.shared.icon(forFile: "/bin/zsh")
                } else {
                    systemIcon = NSImage(systemSymbolName: "gearshape.2.fill", accessibilityDescription: name) ?? NSWorkspace.shared.icon(forFile: "/bin/zsh")
                }
                
                let record = AppGroupRecord(
                    id: "system.\(name)",
                    name: name,
                    bundleURL: nil,
                    bundleIdentifier: nil,
                    icon: systemIcon,
                    rootPid: root,
                    isAppBundle: false,
                    processes: procs
                )
                standaloneRecords.append(record)
            }
        }
        
        var allResults = Array(appGroups.values) + standaloneRecords
        
        // Sort descending by total CPU percentage by default, tie-break with memory
        allResults.sort {
            if $0.totalCpuPercent != $1.totalCpuPercent {
                return $0.totalCpuPercent > $1.totalCpuPercent
            }
            return $0.totalMemoryBytes > $1.totalMemoryBytes
        }
        
        return allResults
    }
}
