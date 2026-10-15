import Foundation
import Darwin

public final class WorkingDirResolver: Sendable {
    public nonisolated init() {}
    
    /// Resolves the current working directory for a given PID
    public nonisolated func resolveCWD(for pid: pid_t) -> String? {
        // First try proc_pidinfo with PROC_PIDVNODEPATHINFO
        var vpi = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vpi, size)
        
        if result == size {
            let path = withUnsafePointer(to: &vpi.pvi_cdir.vip_path) { ptr -> String in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cStr in
                    String(cString: cStr)
                }
            }
            if !path.isEmpty && path != "/" {
                return path
            }
        }
        
        // Fallback to lsof -a -p <pid> -d cwd -Fn
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    if line.hasPrefix("n/") {
                        let path = String(line.dropFirst())
                        if path != "/" {
                            return path
                        }
                    }
                }
            }
        } catch {}
        
        return nil
    }
    
    /// Resolves git branch by reading .git/HEAD upward from the path without spawning any child processes.
    /// Supports standard repositories, Git worktrees, submodules, and detached HEAD commits.
    public nonisolated func resolveGitBranch(for path: String) -> String? {
        guard !path.isEmpty && path != "/" else { return nil }
        var url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        for _ in 0..<5 {
            let gitPath = url.appendingPathComponent(".git")
            var isDir: ObjCBool = false
            
            if fileManager.fileExists(atPath: gitPath.path, isDirectory: &isDir) {
                var actualGitDirURL = gitPath
                
                // If .git is a file (e.g. Git worktree or submodule pointer)
                if !isDir.boolValue {
                    if let gitFileContent = try? String(contentsOf: gitPath, encoding: .utf8) {
                        for line in gitFileContent.components(separatedBy: "\n") {
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.hasPrefix("gitdir:") {
                                let targetDir = trimmed.dropFirst("gitdir:".count).trimmingCharacters(in: .whitespacesAndNewlines)
                                if targetDir.hasPrefix("/") {
                                    actualGitDirURL = URL(fileURLWithPath: targetDir)
                                } else {
                                    actualGitDirURL = url.appendingPathComponent(targetDir).standardized
                                }
                                break
                            }
                        }
                    }
                }
                
                let headURL = actualGitDirURL.appendingPathComponent("HEAD")
                if let content = try? String(contentsOf: headURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                    if content.hasPrefix("ref: refs/heads/") {
                        let branch = String(content.dropFirst("ref: refs/heads/".count))
                        return branch
                    } else if !content.isEmpty {
                        // Detached HEAD commit SHA
                        return String(content.prefix(7))
                    }
                }
                break
            }
            
            let parent = url.deletingLastPathComponent()
            if parent.path == url.path || parent.path == "/" { break }
            url = parent
        }
        return nil
    }
    
    /// Extracts a user-friendly project name from a directory path
    public nonisolated func projectName(from path: String, fallback: String = "Project") -> String {
        if path == "/" || path.isEmpty {
            return fallback
        }
        let url = URL(fileURLWithPath: path)
        let last = url.lastPathComponent
        return last.isEmpty ? fallback : last
    }
}
