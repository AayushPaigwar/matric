import Foundation

public final class DevRuntimeClassifier: Sendable {
    public nonisolated init() {}
    
    /// Classifies the runtime given process name, full command string, and working directory
    public nonisolated func classify(processName: String, command: String, workingDir: String?) -> DevRuntime {
        let lowerName = processName.lowercased()
        let lowerCmd = command.lowercased()
        
        // 1. Next.js
        if lowerCmd.contains("next-server") || lowerCmd.contains("next dev") || lowerCmd.contains("next start") {
            return .nextjs
        }
        
        // 2. Vite
        if lowerCmd.contains("vite") {
            return .vite
        }
        
        // 3. React Scripts / webpack
        if lowerCmd.contains("react-scripts") || lowerCmd.contains("webpack-dev-server") {
            return .react
        }
        
        // 4. Bun
        if lowerName == "bun" || lowerCmd.contains("bun run") || lowerCmd.contains("bun dev") {
            return .bun
        }
        
        // 5. Deno
        if lowerName == "deno" || lowerCmd.contains("deno run") {
            return .deno
        }
        
        // 6. Python frameworks
        if lowerCmd.contains("uvicorn") || lowerCmd.contains("fastapi") {
            return .fastapi
        }
        if lowerCmd.contains("manage.py runserver") || lowerCmd.contains("django") {
            return .django
        }
        if lowerCmd.contains("flask") {
            return .flask
        }
        if lowerName.hasPrefix("python") {
            return .python
        }
        
        // 7. Go
        if lowerCmd.contains("go run") || lowerName == "go" {
            return .go
        }
        
        // 8. Rust / Cargo
        if lowerCmd.contains("cargo run") || lowerName == "cargo" {
            return .rust
        }
        
        // 9. Ruby / Rails
        if lowerCmd.contains("rails server") || lowerCmd.contains("puma") || lowerName == "ruby" {
            return .ruby
        }
        
        // 10. Databases & Containers
        if lowerName.contains("docker") || lowerCmd.contains("docker") {
            return .docker
        }
        if lowerName.contains("postgres") || lowerName.contains("postmaster") {
            return .postgres
        }
        if lowerName.contains("redis-server") || lowerName == "redis" {
            return .redis
        }
        if lowerName.contains("mongod") || lowerCmd.contains("mongod") {
            return .mongodb
        }
        if lowerName.contains("mysqld") || lowerCmd.contains("mysqld") {
            return .mysql
        }
        
        // 11. Tunnels and Tooling
        if lowerName.contains("cloudflared") || lowerCmd.contains("cloudflared") {
            return .cloudflare
        }
        if lowerName == "ssh" {
            return .sshTunnel
        }
        if lowerName.contains("t3 code") || lowerCmd.contains("t3 code") {
            return .t3code
        }
        if lowerName.contains("code helper") || lowerCmd.contains("visual studio code") || lowerCmd.contains("vscode") {
            return .vscodeTunnel
        }
        
        // 12. Check project directory files if available
        if let dir = workingDir, let dirURL = URL(string: "file://" + dir) {
            let fileManager = FileManager.default
            
            let nextConfig = dirURL.appendingPathComponent("next.config.js")
            let nextConfigMjs = dirURL.appendingPathComponent("next.config.mjs")
            let nextConfigTs = dirURL.appendingPathComponent("next.config.ts")
            if fileManager.fileExists(atPath: nextConfig.path) ||
               fileManager.fileExists(atPath: nextConfigMjs.path) ||
               fileManager.fileExists(atPath: nextConfigTs.path) {
                return .nextjs
            }
            
            let viteConfigJs = dirURL.appendingPathComponent("vite.config.js")
            let viteConfigTs = dirURL.appendingPathComponent("vite.config.ts")
            if fileManager.fileExists(atPath: viteConfigJs.path) ||
               fileManager.fileExists(atPath: viteConfigTs.path) {
                return .vite
            }
            
            let cargoToml = dirURL.appendingPathComponent("Cargo.toml")
            if fileManager.fileExists(atPath: cargoToml.path) {
                return .rust
            }
            
            let goMod = dirURL.appendingPathComponent("go.mod")
            if fileManager.fileExists(atPath: goMod.path) {
                return .go
            }
        }
        
        // 13. Generic Node
        if lowerName == "node" {
            return .node
        }
        
        return .generic
    }
}
