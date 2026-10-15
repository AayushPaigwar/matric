import SwiftUI
import AppKit

public struct StorageSpaceView: View {
    @Environment(AppState.self) private var appState
    @State private var storageManager = StorageManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 20) {
                    // Full Disk Access Banner (if needed)
                    if !storageManager.breakdown.hasFullDiskAccess {
                        fdaBannerView
                    }
                    
                    // Main Disk Capacity Bar & Breakdown
                    capacityOverviewCard
                    
                    // Storage Categories Grid
                    categoriesSection
                    
                    // Largest Consumers List
                    largestItemsSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Spacer(minLength: 0)
            
            StatusFooterView()
        }
        .onAppear {
            storageManager.startScan()
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.purple)
                    
                    Text("Storage Space")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Macintosh HD · APFS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.purple.opacity(0.12)))
                }
                
                Text("Local APFS Container Allocation, Categorized Workspaces & Largest Space Consumers")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Rescan Button
            Button {
                storageManager.startScan()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(storageManager.isScanning ? 360 : 0))
                        .animation(storageManager.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: storageManager.isScanning)
                    
                    Text(storageManager.isScanning ? "Scanning..." : "Rescan")
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
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var fdaBannerView: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Recommended")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Grant Full Disk Access in System Settings to allow Matric to inspect system caches, containers, and Time Machine backups.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Open Privacy Settings") {
                storageManager.openFullDiskAccessSettings()
            }
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var capacityOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("APFS CONTAINER ALLOCATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(storageManager.breakdown.formattedUsed)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Used of \(storageManager.breakdown.formattedTotal)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("AVAILABLE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text(storageManager.breakdown.formattedFree)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            
            // Segmented Progress Bar
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let usedBytes = max(1, storageManager.breakdown.usedDiskBytes)
                let totalBytes = max(usedBytes, storageManager.breakdown.totalDiskBytes)
                let usedFraction = CGFloat(usedBytes) / CGFloat(totalBytes)
                let usedWidth = max(6, totalWidth * usedFraction)
                
                let activeCategories = StorageCategory.allCases.filter {
                    (storageManager.breakdown.categorySizes[$0] ?? 0) > 0
                }
                let spacingTotal = CGFloat(max(0, activeCategories.count - 1)) * 1.5
                let contentWidth = max(0, usedWidth - spacingTotal)
                
                ZStack(alignment: .leading) {
                    // Background track (Free space)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: totalWidth, height: 16)
                    
                    // Segments for categories inside used region
                    HStack(spacing: 1.5) {
                        ForEach(activeCategories) { cat in
                            let catSize = storageManager.breakdown.categorySizes[cat] ?? 0
                            let catFraction = CGFloat(catSize) / CGFloat(usedBytes)
                            let catWidth = max(2, contentWidth * catFraction)
                            
                            Rectangle()
                                .fill(cat.themeColor)
                                .frame(width: catWidth, height: 16)
                        }
                    }
                    .frame(width: usedWidth, height: 16, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .frame(height: 16)
            
            // Legends
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 8)], spacing: 8) {
                ForEach(StorageCategory.allCases) { cat in
                    let size = storageManager.breakdown.categorySizes[cat] ?? 0
                    if size > 0 {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cat.themeColor)
                                .frame(width: 8, height: 8)
                            
                            Text(cat.rawValue)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(Self.formatBytes(size))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
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
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EXPLORE WORKSPACES & DIRECTORIES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(StorageCategory.allCases) { cat in
                    let size = storageManager.breakdown.categorySizes[cat] ?? 0
                    let pct = storageManager.breakdown.percentage(for: cat)
                    
                    StorageCategoryCard(
                        category: cat,
                        sizeBytes: size,
                        percentageOfUsed: pct,
                        onReveal: {
                            if let first = cat.defaultPaths.first {
                                storageManager.revealInFinder(path: first)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var largestItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LARGEST SPACE CONSUMERS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            if storageManager.breakdown.largestItems.isEmpty {
                HStack {
                    Spacer()
                    Text(storageManager.isScanning ? "Scanning storage directories..." : "No unusually large individual files discovered.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(storageManager.breakdown.largestItems) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(item.category.themeColor)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.primary.opacity(0.04)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Text(item.path)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Text(item.formattedSize)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                            
                            Button {
                                storageManager.revealInFinder(path: item.path)
                            } label: {
                                Image(systemName: "folder")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.primary.opacity(0.04)))
                            }
                            .buttonStyle(.plain)
                            .help("Reveal in Finder")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        )
                    }
                }
            }
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
    
    public static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

private struct StorageCategoryCard: View {
    let category: StorageCategory
    let sizeBytes: UInt64
    let percentageOfUsed: Double
    let onReveal: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(category.themeColor)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(category.themeColor.opacity(0.12)))
                
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: onReveal) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Directory in Finder")
            }
            
            HStack(alignment: .lastTextBaseline) {
                Text(StorageSpaceView.formatBytes(sizeBytes))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f%% of used", percentageOfUsed))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            // Bar
            ProgressView(value: min(1.0, percentageOfUsed / 100.0))
                .tint(category.themeColor)
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
    StorageSpaceView()
        .environment(AppState())
}
