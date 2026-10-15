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
    case ports = "Port Number"
    case cpu = "CPU Usage"
    case memory = "Memory"
    case name = "Name"
    
    public var id: String { rawValue }
}

public enum DevProjectViewMode: String, CaseIterable, Identifiable, Sendable {
    case cards = "Cards"
    case table = "Ports Table"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cards: return "square.grid.2x2.fill"
        case .table: return "tablecells.fill"
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
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .fastapi: return "bolt.horizontal.fill"
        case .django: return "leaf.fill"
        case .flask: return "testtube.2"
        case .go: return "paperplane.fill"
        case .rust: return "gearshape.2.fill"
        case .ruby: return "diamond.fill"
        case .docker: return "ferry.fill"
        case .postgres: return "cylinder.split.1x2.fill"
        case .redis: return "layers.fill"
        case .mongodb: return "leaf.arrow.circlepath"
        case .mysql: return "cylinder.split.1x2.fill"
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
        case .python: return Color.yellow
        case .fastapi: return Color.teal
        case .django: return Color.mint
        case .flask: return Color(red: 0.2, green: 0.75, blue: 0.6)
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
    
    public init(
        id: UUID = UUID(),
        projectName: String,
        projectPath: String,
        gitBranch: String? = nil,
        runtime: DevRuntime,
        pid: pid_t,
        command: String,
        fullCommand: String,
        listeningPorts: [Int],
        cpuPercent: Double,
        memoryBytes: UInt64
    ) {
        self.id = id
        self.projectName = projectName
        self.projectPath = projectPath
        self.gitBranch = gitBranch
        self.runtime = runtime
        self.pid = pid
        self.command = command
        self.fullCommand = fullCommand
        self.listeningPorts = listeningPorts
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
    }
    
    public var category: DevProjectCategory {
        runtime.category
    }
    
    public var isListening: Bool {
        !listeningPorts.isEmpty
    }
    
    public var formattedMemory: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryBytes))
    }
}

public struct PortInspectionItem: Identifiable, Sendable {
    public var id: String { "\(port)-\(pid)" }
    public let port: Int
    public let status: String
    public let projectName: String
    public let projectPath: String
    public let gitBranch: String?
    public let runtime: DevRuntime
    public let pid: pid_t
    public let processName: String
    public var cpuPercent: Double
    public var memoryBytes: UInt64
    
    public init(
        port: Int,
        status: String,
        projectName: String,
        projectPath: String,
        gitBranch: String?,
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
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
    }
    
    public var isHTTP: Bool {
        port == 80 || port == 443 || port >= 1000
    }
    
    public var memoryFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryBytes))
    }
}
