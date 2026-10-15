import Foundation

public final class PortScanner: Sendable {
    public nonisolated init() {}
    
    /// Scans for all active TCP listening ports and maps them to PID: [Port]
    public nonisolated func scanListeningPorts() -> [pid_t: [Int]] {
        var pidToPorts: [pid_t: [Int]] = [:]
        
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-F", "pPn"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // discard stderr
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let output = String(data: data, encoding: .utf8) else {
                return pidToPorts
            }
            
            var currentPID: pid_t? = nil
            let lines = output.components(separatedBy: "\n")
            
            for line in lines {
                if line.hasPrefix("p") {
                    let pidString = String(line.dropFirst())
                    currentPID = pid_t(pidString)
                } else if line.hasPrefix("n"), let pid = currentPID {
                    // format: n*:3000 or n127.0.0.1:8080 or n[::1]:5173
                    let endpoint = String(line.dropFirst())
                    if let colonIndex = endpoint.lastIndex(of: ":") {
                        let portSubstring = endpoint[endpoint.index(after: colonIndex)...]
                        if let port = Int(portSubstring) {
                            if pidToPorts[pid] == nil {
                                pidToPorts[pid] = []
                            }
                            if !pidToPorts[pid]!.contains(port) {
                                pidToPorts[pid]!.append(port)
                            }
                        }
                    }
                }
            }
        } catch {
            // Fallback or permission restricted
        }
        
        return pidToPorts
    }
    
    /// Checks a specific port and returns the PID holding it
    public nonisolated func inspectPort(_ targetPort: Int) -> pid_t? {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-iTCP:\(targetPort)", "-sTCP:LISTEN", "-n", "-P", "-F", "p"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            for line in output.components(separatedBy: "\n") {
                if line.hasPrefix("p") {
                    let pidStr = String(line.dropFirst())
                    if let pid = pid_t(pidStr) {
                        return pid
                    }
                }
            }
        } catch {}
        
        return nil
    }
}
