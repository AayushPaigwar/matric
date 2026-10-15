import SwiftUI
import AppKit

public struct SystemCleanupView: View {
    @Environment(AppState.self) private var appState
    @State private var cleaner = CleanerManager.shared
    @State private var showConfirmModal: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 16) {
                    // Success Banner
                    if cleaner.showSuccessBanner, let freed = cleaner.lastCleanedBytes {
                        successBannerView(freedBytes: freed)
                    }
                    
                    // Main Action & Summary Card
                    cleanupSummaryCard
                    
                    // Itemized Checklist
                    targetsListView
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
        .onAppear {
            cleaner.startScan()
        }
        .confirmationDialog(
            "Purge Selected Items?",
            isPresented: $showConfirmModal,
            titleVisibility: .visible
        ) {
            Button("Clean Selected (\(cleaner.formattedSelectedReclaimable))", role: .destructive) {
                cleaner.cleanSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove selected build caches, package downloads, and empty the system Trash. Intermediate files will be regenerated as needed by their respective tools.")
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(.pink)
                    
                    Text("System Cleanup")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(cleaner.formattedTotalReclaimable) Cleanable")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.pink.opacity(0.12)))
                }
                
                Text("Reclaim Disk Space by Safely Purging Build Artifacts, Package Caches & Temporary Logs")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Rescan Button
            Button {
                cleaner.startScan()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(cleaner.isScanning ? 360 : 0))
                        .animation(cleaner.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: cleaner.isScanning)
                    
                    Text("Scan System")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                )
            }
            .buttonStyle(.plain)
            .disabled(cleaner.isCleaning)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private func successBannerView(freedBytes: UInt64) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Successfully Reclaimed \(Self.formatBytes(freedBytes))!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Your disk space has been freed. Targets have been re-indexed.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    private var cleanupSummaryCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("RECLAIMABLE DISK SPACE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(cleaner.formattedSelectedReclaimable)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("selected of \(cleaner.formattedTotalReclaimable) total")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button("Select All") {
                        cleaner.selectAll(true)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    
                    Text("·")
                        .foregroundStyle(.secondary)
                    
                    Button("Deselect All") {
                        cleaner.selectAll(false)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Clean Button
            Button {
                showConfirmModal = true
            } label: {
                HStack(spacing: 8) {
                    if cleaner.isCleaning {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    
                    Text(cleaner.isCleaning ? "Cleaning..." : "Clean Selected (\(cleaner.formattedSelectedReclaimable))")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(cleaner.selectedReclaimableBytes > 0 && !cleaner.isCleaning ? Color.pink : Color.secondary.opacity(0.2))
                )
                .foregroundStyle(cleaner.selectedReclaimableBytes > 0 && !cleaner.isCleaning ? Color.white : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(cleaner.selectedReclaimableBytes == 0 || cleaner.isCleaning)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var targetsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLEANUP TARGETS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 10) {
                ForEach(cleaner.items) { item in
                    CleanupTargetRow(
                        item: item,
                        onToggle: { cleaner.toggleItem(item.id) },
                        onReveal: {
                            if let first = item.paths.first {
                                cleaner.revealInFinder(path: first)
                            }
                        }
                    )
                }
            }
        }
    }
    
    public static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

private struct CleanupTargetRow: View {
    let item: CleanTargetItem
    let onToggle: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(item.isSelected ? item.category.themeColor : Color.secondary)
            }
            .buttonStyle(.plain)
            
            // Icon
            Image(systemName: item.category.iconName)
                .font(.system(size: 13))
                .foregroundStyle(item.category.themeColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(item.category.themeColor.opacity(0.12)))
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(item.category.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(item.category.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(item.category.themeColor.opacity(0.1)))
                }
                
                Text(item.descriptionText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Size & Reveal
            HStack(spacing: 12) {
                Text(item.formattedSize)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(item.sizeBytes > 0 ? Color.primary : Color.secondary)
                
                Button(action: onReveal) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.primary.opacity(0.04)))
                }
                .buttonStyle(.plain)
                .help("Reveal Target in Finder")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SystemCleanupView()
        .environment(AppState())
}
