import SwiftUI

public struct WindowLayoutView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    
    public init() {}
    
    public var body: some View {
        @Bindable var state = appState
        
        NavigationSplitView {
            SidebarView()
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
                
                switch appState.selectedItem {
                case .overview:
                    OverviewDashboardView()
                case .cpu:
                    CPUDetailView()
                case .memory:
                    MemoryDetailView()
                case .disk:
                    DiskDetailView()
                case .network:
                    NetworkDetailView()
                case .graphics:
                    GPUDetailView()
                case .battery:
                    BatteryDetailView()
                case .projects:
                    ProjectsView()
                case .storage:
                    StorageSpaceView()
                case .cleanup:
                    SystemCleanupView()
                case .settings:
                    SettingsView()
                case .alerts:
                    AlertsView()
                case .savedMoments:
                    SavedMomentsView()
                case .history:
                    HistoryView()
                }
            }
        }
        .frame(minWidth: 960, idealWidth: 1180, maxWidth: .infinity,
               minHeight: 640, idealHeight: 780, maxHeight: .infinity)
        .sheet(item: $state.inspectedApp) { app in
            ProcessInspectorSheet(appGroup: app)
        }
        .background(
            // Invisible keyboard shortcut receivers
            Group {
                Button("") { appState.select(.overview) }.keyboardShortcut("1", modifiers: .command)
                Button("") { appState.select(.cpu) }.keyboardShortcut("2", modifiers: .command)
                Button("") { appState.select(.memory) }.keyboardShortcut("3", modifiers: .command)
                Button("") { appState.select(.disk) }.keyboardShortcut("4", modifiers: .command)
                Button("") { appState.select(.network) }.keyboardShortcut("5", modifiers: .command)
                Button("") { appState.select(.storage) }.keyboardShortcut("6", modifiers: .command)
                Button("") { appState.select(.graphics) }.keyboardShortcut("7", modifiers: .command)
                Button("") { appState.select(.battery) }.keyboardShortcut("8", modifiers: .command)
                Button("") { appState.select(.projects) }.keyboardShortcut("9", modifiers: .command)
                Button("") { appState.select(.cleanup) }.keyboardShortcut("0", modifiers: .command)
                Button("") { appState.select(.settings) }.keyboardShortcut(",", modifiers: .command)
                Button("") { appState.triggerManualRefresh() }.keyboardShortcut("r", modifiers: .command)
                Button("") {
                    if appState.selectedItem != .overview {
                        appState.select(.overview)
                    }
                    appState.searchFocusTrigger += 1
                }.keyboardShortcut("k", modifiers: .command)
            }
            .opacity(0)
            .frame(width: 0, height: 0)
        )
    }
}

#Preview {
    WindowLayoutView()
        .environment(AppState())
        .environment(SystemTelemetryHub.shared)
}
