import SwiftUI

public struct StatusFooterView: View {
    @Environment(AppState.self) private var appState
    var customNote: String?
    
    @State private var hud = FloatingHUDWindowController.shared
    
    public init(customNote: String? = nil) {
        self.customNote = customNote
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.4)
            
            HStack(spacing: 16) {
                // Left badge: Local & private
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("Local & private")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // Middle: Contextual note or disclaimer
                if let note = customNote ?? appState.statusNote {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
                
                // Manual Refresh Button
                Button {
                    appState.triggerManualRefresh()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Refresh")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh telemetry metrics immediately (⌘R)")
                
                // Floating HUD toggle button
                Button {
                    hud.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: hud.isVisible ? "pip.exit" : "pip.enter")
                            .font(.system(size: 10))
                        Text(hud.isVisible ? "HUD On" : "HUD")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(hud.isVisible ? Color.cyan.opacity(0.15) : Color.primary.opacity(0.05))
                    )
                    .foregroundStyle(hud.isVisible ? Color.cyan : Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle Floating Mini Desktop HUD (⇧⌘H)")
                
                // Right badge: Live refresh status
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isLive ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    let intervalStr = appState.refreshInterval.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0fs", appState.refreshInterval)
                        : String(format: "%.1fs", appState.refreshInterval)
                    
                    Text(appState.isLive ? "Live · \(intervalStr) refresh" : "Paused")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

#Preview {
    StatusFooterView(customNote: "CPU: 100% per core. Memory: physical footprint.")
        .environment(AppState())
}
