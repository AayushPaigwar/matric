import SwiftUI
import AppKit

public struct FloatingHUDView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    var onClose: () -> Void
    var onTogglePin: () -> Void
    var isPinned: Bool
    
    @State private var isHovering: Bool = false
    
    public init(
        isPinned: Bool = true,
        onClose: @escaping () -> Void = {},
        onTogglePin: @escaping () -> Void = {}
    ) {
        self.isPinned = isPinned
        self.onClose = onClose
        self.onTogglePin = onTogglePin
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan)
                    
                    Text("MATRIC HUD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Controls visible on hover or pinned
                HStack(spacing: 8) {
                    Button(action: onTogglePin) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundStyle(isPinned ? .cyan : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isPinned ? "Unpin HUD" : "Keep HUD Always on Top")
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Close HUD")
                }
                .opacity(isHovering || !isPinned ? 1.0 : 0.4)
            }
            
            // Metrics Row
            HStack(spacing: 12) {
                // CPU Mini Gauge
                hudMetricTile(
                    title: "CPU",
                    value: "\(Int(hub.cpu.totalPercent))%",
                    icon: "cpu",
                    tint: .cyan,
                    progress: hub.cpu.totalPercent / 100.0
                )
                
                // RAM Mini Gauge
                hudMetricTile(
                    title: "RAM",
                    value: "\(Int(hub.memory.usedPercentage))%",
                    icon: "memorychip",
                    tint: .purple,
                    progress: hub.memory.usedPercentage / 100.0
                )
            }
            
            // Network & Battery Row
            HStack(spacing: 8) {
                // Network Down / Up
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                        Text(formatNetworkSpeed(hub.network.totalDownloadBps))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.blue)
                        Text(formatNetworkSpeed(hub.network.totalUploadBps))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                // Battery Pill (if Mac has battery)
                if hub.battery.hasBattery {
                    HStack(spacing: 4) {
                        Image(systemName: hub.battery.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 9))
                            .foregroundStyle(hub.battery.chargePercent < 20 ? .red : .secondary)
                        
                        Text("\(hub.battery.chargePercent)%")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .frame(width: 230)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(appState.hudOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    private func hudMetricTile(title: String, value: String, icon: String, tint: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(tint.opacity(0.2))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)))
                }
            }
            .frame(height: 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
    
    private func formatNetworkSpeed(_ bps: Double) -> String {
        if bps < 1024 {
            return "0 K"
        } else if bps < 1024 * 1024 {
            return String(format: "%.0f K", bps / 1024)
        } else {
            return String(format: "%.1f M", bps / (1024 * 1024))
        }
    }
}
