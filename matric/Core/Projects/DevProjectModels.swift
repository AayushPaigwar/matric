import Foundation
import SwiftUI

public enum DevProjectCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case web = "Web & APIs"
    case databases = "Databases"
    case tooling = "Tunnels & Tooling"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .web: return "globe"
        case .databases: return "cylinder.split.1x2"
        case .tooling: return "wrench.and.screwdriver"
        }
    }
}

public enum DevProjectSortOption: String, CaseIterable, Identifiable, Sendable {
    case ports = "Ports"
    case cpu = "CPU Usage"
    case memory = "Memory"
    case name = "Name"
    
    public var id: String { rawValue }
}

public enum DevProjectViewMode: String, CaseIterable, Identifiable, Sendable {
    case cards = "Cards"
    case portsTable = "Ports Table"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cards: return "square.grid.2x2.fill"
        case .portsTable: return "tablecells.fill"
        }
    }
}

public enum DevRuntime: String, CaseIterable, Sendable {
    case nextjs = "Next.js"
    case vite = "Vite"
    case react = "React"
    case node = "Node.js"
    case bun = "Bun"
    case deno = "Deno"
    case python = "Python"
    case fastapi = "FastAPI"
    case django = "Django"
    case flask = "Flask"
    case go = "Go"
    case rust = "Rust / Cargo"
    case ruby = "Ruby / Rails"
    case docker = "Docker"
    case postgres = "PostgreSQL"
    case redis = "Redis"
    case mongodb = "MongoDB"
    case mysql = "MySQL"
    case vscodeTunnel = "VS Code Forwarding"
    case t3code = "T3 Code Server"
    case cloudflare = "Cloudflare Tunnel"
    case sshTunnel = "SSH Tunnel"
    case generic = "Development Server"
    
    public var category: DevProjectCategory {
        switch self {
        case .nextjs, .vite, .react, .node, .bun, .deno, .python, .fastapi, .django, .flask, .go, .rust, .ruby:
            return .web
        case .postgres, .redis, .mongodb, .mysql:
            return .databases
        case .docker, .vscodeTunnel, .t3code, .cloudflare, .sshTunnel, .generic:
            return .tooling
        }
    }
    
    public var iconName: String {
        switch self {
        case .nextjs: return "triangle.fill"
        case .vite: return "bolt.fill"
        case .react: return "atom"
        case .node: return "shippingbox.fill"
        case .bun: return "flame.fill"
        case .deno: return "tortoise.fill"
        case .python, .fastapi, .django, .flask: return "chevron.left.forwardslash.chevron.right"
        case .go: return "paperplane.fill"
        case .rust: return "gearshape.2.fill"
        case .ruby: return "diamond.fill"
        case .docker: return "ferry.fill"
        case .postgres, .redis, .mongodb, .mysql: return "cylinder.split.1x2.fill"
        case .vscodeTunnel: return "chevron.left.forwardslash.chevron.right"
        case .t3code: return "sparkles"
        case .cloudflare: return "cloud.fill"
        case .sshTunnel: return "network"
        case .generic: return "hammer.fill"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .nextjs: return Color.primary
        case .vite: return Color.purple
        case .react: return Color.cyan
        case .node: return Color.green
        case .bun: return Color.orange
        case .deno: return Color.blue
        case .python, .fastapi, .django, .flask: return Color.yellow
        case .go: return Color.cyan
        case .rust: return Color.red
        case .ruby: return Color.pink
        case .docker: return Color.blue
        case .postgres: return Color.indigo
        case .redis: return Color.red
        case .mongodb: return Color.green
        case .mysql: return Color.orange
        case .vscodeTunnel: return Color.blue
        case .t3code: return Color.purple
        case .cloudflare: return Color.orange
        case .sshTunnel: return Color.teal
        case .generic: return Color.accentColor
        }
    }
}

public struct DevProjectRecord: Identifiable, Sendable {
    public let id: UUID
    public let projectName: String
    public let projectPath: String
    public let gitBranch: String?
    public let runtime: DevRuntime
    public let pid: pid_t
    public let command: String
    public let fullCommand: String
    public let listeningPorts: [Int]
    public var cpuPercent: Double
    public var memoryBytes: UInt64
    public let detectedAt: Date
    
    public nonisolated init(
        id: UUID = UUID(),
        projectName: String,
        projectPath: String,
        gitBranch: String? = nil,
        runtime: DevRuntime,
        pid: pid_t,
        command: String,
        fullCommand: String = "",
        listeningPorts: [Int],
        cpuPercent: Double = 0.0,
        memoryBytes: UInt64 = 0,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.projectName = projectName
        self.projectPath = projectPath
        self.gitBranch = gitBranch
        self.runtime = runtime
        self.pid = pid
        self.command = command
        self.fullCommand = fullCommand.isEmpty ? command : fullCommand
        self.listeningPorts = listeningPorts
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.detectedAt = detectedAt
    }
    
    public nonisolated var isListening: Bool {
        !listeningPorts.isEmpty
    }
    
    public nonisolated var primaryURL: URL? {
        guard let firstPort = listeningPorts.first else { return nil }
        return URL(string: "http://localhost:\(firstPort)")
    }
    
    public nonisolated var formattedMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryBytes))
    }
    
    public nonisolated var category: DevProjectCategory {
        runtime.category
    }
}

public struct PortInspectionItem: Identifiable, Sendable {
    public var id: String { "\(pid)-\(port)" }
    public let port: Int
    public let status: String
    public let pid: pid_t
    public let processName: String
    public let projectName: String
    public let projectPath: String
    public let gitBranch: String?
    public let runtime: DevRuntime
    public let isHTTP: Bool
    public var cpuPercent: Double
    public var memoryBytes: UInt64
    
    public var memoryFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryBytes))
    }
    
    public nonisolated init(
        port: Int,
        status: String = "LISTEN",
        projectName: String,
        projectPath: String,
        gitBranch: String? = nil,
        runtime: DevRuntime,
        pid: pid_t,
        processName: String,
        cpuPercent: Double,
        memoryBytes: UInt64
    ) {
        self.port = port
        self.status = status
        self.projectName = projectName
        self.projectPath = projectPath
        self.gitBranch = gitBranch
        self.runtime = runtime
        self.pid = pid
        self.processName = processName
        self.isHTTP = (port == 80 || port == 443 || port == 3000 || port == 5173 || port == 8080 || port == 8000 || port == 4200 || port == 5000 || port >= 1024)
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
    }
}
