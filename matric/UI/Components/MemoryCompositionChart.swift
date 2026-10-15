import SwiftUI

public struct MemoryCompositionChart: View {
    let activeBytes: UInt64
    let wiredBytes: UInt64
    let compressedBytes: UInt64
    let freeBytes: UInt64
    let totalPhysicalBytes: UInt64
    let swapUsedBytes: UInt64
    let swapTotalBytes: UInt64
    let pressureState: MemoryPressureState
    
    public init(
        activeBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        freeBytes: UInt64,
        totalPhysicalBytes: UInt64,
        swapUsedBytes: UInt64,
        swapTotalBytes: UInt64,
        pressureState: MemoryPressureState
    ) {
        self.activeBytes = activeBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.freeBytes = freeBytes
        self.totalPhysicalBytes = max(totalPhysicalBytes, 1)
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
        self.pressureState = pressureState
    }
    
    private var activePct: Double {
        Double(activeBytes) / Double(totalPhysicalBytes)
    }
    
    private var wiredPct: Double {
        Double(wiredBytes) / Double(totalPhysicalBytes)
    }
    
    private var compressedPct: Double {
        Double(compressedBytes) / Double(totalPhysicalBytes)
    }
    
    private var freePct: Double {
        max(1.0 - (activePct + wiredPct + compressedPct), 0.0)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MEMORY COMPOSITION & PRESSURE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text("\(formatBytes(activeBytes + wiredBytes + compressedBytes)) used of \(formatBytes(totalPhysicalBytes))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Pressure Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(pressureColor)
                        .frame(width: 8, height: 8)
                    Text("\(pressureState.rawValue) Pressure")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(pressureColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(pressureColor.opacity(0.12))
                )
            }
            
            // Segmented Proportion Bar
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 2) {
                    // App Memory (Active)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: max(w * activePct, 4))
                    
                    // Wired Memory
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: max(w * wiredPct, 4))
                    
                    // Compressed Memory
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: max(w * compressedPct, 4))
                    
                    // Free Memory
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: max(w * freePct, 4))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 12)
            
            // Legend Row
            HStack(spacing: 16) {
                legendItem(title: "App Memory", bytes: activeBytes, color: .blue)
                legendItem(title: "Wired", bytes: wiredBytes, color: .purple)
                legendItem(title: "Compressed", bytes: compressedBytes, color: .orange)
                legendItem(title: "Free", bytes: freeBytes, color: Color.primary.opacity(0.4))
                
                Spacer()
                
                // Swap stats
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Swap Used")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(formatBytes(swapUsedBytes)) / \(formatBytes(swapTotalBytes))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(swapUsedBytes > 0 ? .orange : .primary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func legendItem(title: String, bytes: UInt64, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(formatBytes(bytes))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private var pressureColor: Color {
        switch pressureState {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
