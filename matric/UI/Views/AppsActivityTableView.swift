import SwiftUI

public enum AppSortCriteria: String, CaseIterable, Identifiable {
    case cpu = "CPU %"
    case memory = "Memory"
    
    public var id: String { rawValue }
}

public struct AppsActivityTableView: View {
    @Environment(AppState.self) private var appState
    let appGroups: [AppGroupRecord]
    let title: String
    
    @State private var searchFilter: String = ""
    @State private var sortCriteria: AppSortCriteria
    @FocusState private var isSearchFocused: Bool
    
    public init(
        appGroups: [AppGroupRecord],
        defaultSort: AppSortCriteria = .cpu,
        title: String = "TOP APPLICATIONS"
    ) {
        self.appGroups = appGroups
        self._sortCriteria = State(initialValue: defaultSort)
        self.title = title
    }
    
    private var maxMemory: UInt64 {
        appGroups.map(\.totalMemoryBytes).max() ?? 1
    }
    
    private var filteredAndSortedApps: [AppGroupRecord] {
        var list = appGroups
        
        // Search filter
        let query = searchFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                ($0.bundleIdentifier?.localizedCaseInsensitiveContains(query) ?? false) ||
                String($0.rootPid).contains(query)
            }
        }
        
        // Sorting
        switch sortCriteria {
        case .cpu:
            list.sort {
                if $0.totalCpuPercent != $1.totalCpuPercent {
                    return $0.totalCpuPercent > $1.totalCpuPercent
                }
                return $0.totalMemoryBytes > $1.totalMemoryBytes
            }
        case .memory:
            list.sort {
                if $0.totalMemoryBytes != $1.totalMemoryBytes {
                    return $0.totalMemoryBytes > $1.totalMemoryBytes
                }
                return $0.totalCpuPercent > $1.totalCpuPercent
            }
        }
        
        return list
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Table Header Toolbar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text("\(filteredAndSortedApps.count) apps active")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    TextField("Filter apps... (⌘K)", text: $searchFilter)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($isSearchFocused)
                        .frame(width: 140)
                    
                    if !searchFilter.isEmpty {
                        Button {
                            searchFilter = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                )
                
                // Sort Segmented Control
                HStack(spacing: 2) {
                    ForEach(AppSortCriteria.allCases) { criteria in
                        Button {
                            sortCriteria = criteria
                        } label: {
                            Text(criteria.rawValue)
                                .font(.system(size: 11, weight: sortCriteria == criteria ? .bold : .medium))
                                .foregroundStyle(sortCriteria == criteria ? Color.primary : Color.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(sortCriteria == criteria ? Color(nsColor: .controlColor) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .opacity(0.4)
            
            // Apps List
            if filteredAndSortedApps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.folder")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("No matching applications found")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredAndSortedApps) { app in
                        AppRowItemView(
                            app: app,
                            maxMemory: maxMemory,
                            onInspect: {
                                appState.presentInspector(for: app)
                            }
                        )
                        
                        if app.id != filteredAndSortedApps.last?.id {
                            Divider()
                                .opacity(0.2)
                                .padding(.leading, 42)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .onChange(of: appState.searchFocusTrigger) { _, _ in
            isSearchFocused = true
        }
    }
}

// MARK: - App Row View
private struct AppRowItemView: View {
    let app: AppGroupRecord
    let maxMemory: UInt64
    let onInspect: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
            }
            
            // App Name & Process Count
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if app.processes.count > 1 {
                        Text("\(app.processes.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                }
                
                if let bundle = app.bundleIdentifier {
                    Text(bundle)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 220, alignment: .leading)
            
            Spacer()
            
            // CPU Load Bar & Percent
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.cyan.opacity(0.15))
                        
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: min(geo.size.width * CGFloat(min(app.totalCpuPercent / 100.0, 1.0)), geo.size.width))
                    }
                }
                .frame(width: 70, height: 6)
                
                Text(String(format: "%.1f%%", app.totalCpuPercent))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(width: 50, alignment: .trailing)
            }
            
            // Memory Footprint Bar & Size
            HStack(spacing: 8) {
                GeometryReader { geo in
                    let fraction = CGFloat(app.totalMemoryBytes) / CGFloat(maxMemory)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.purple.opacity(0.15))
                        
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: min(geo.size.width * fraction, geo.size.width))
                    }
                }
                .frame(width: 70, height: 6)
                
                Text(app.formattedMemory)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 65, alignment: .trailing)
            }
            
            // Inspector Detail Action
            Button(action: onInspect) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("Inspect Process Hierarchy")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onInspect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
