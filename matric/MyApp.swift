import SwiftUI

@main
struct MyApp: App {
    @State private var appState = AppState()
    @State private var telemetryHub = SystemTelemetryHub.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(telemetryHub)
                .onAppear {
                    telemetryHub.startMonitoring(interval: appState.refreshInterval)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .textEditing) {
                Button("Filter Applications...") {
                    if appState.selectedItem != .overview {
                        appState.select(.overview)
                    }
                    appState.searchFocusTrigger += 1
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            CommandMenu("Navigation") {
                Button("Overview") { appState.select(.overview) }.keyboardShortcut("1", modifiers: .command)
                Button("CPU") { appState.select(.cpu) }.keyboardShortcut("2", modifiers: .command)
                Button("Memory") { appState.select(.memory) }.keyboardShortcut("3", modifiers: .command)
                Button("Disk") { appState.select(.disk) }.keyboardShortcut("4", modifiers: .command)
                Button("Network") { appState.select(.network) }.keyboardShortcut("5", modifiers: .command)
                Button("Storage") { appState.select(.storage) }.keyboardShortcut("6", modifiers: .command)
                Button("Graphics") { appState.select(.graphics) }.keyboardShortcut("7", modifiers: .command)
                Button("Battery") { appState.select(.battery) }.keyboardShortcut("8", modifiers: .command)
                Button("Projects") { appState.select(.projects) }.keyboardShortcut("9", modifiers: .command)
                Button("System Cleanup") { appState.select(.cleanup) }.keyboardShortcut("0", modifiers: .command)
            }
            CommandMenu("Diagnostics") {
                Button("Refresh Sensors Now") { appState.triggerManualRefresh() }.keyboardShortcut("r", modifiers: .command)
                Button("Toggle Desktop Floating HUD") { FloatingHUDWindowController.shared.toggle() }.keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
                .environment(appState)
                .environment(telemetryHub)
        }
        
        MenuBarExtra {
            MenuBarPopupView()
                .environment(appState)
                .environment(telemetryHub)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }
    
    @ViewBuilder
    private var menuBarLabel: some View {
        switch appState.menuBarMode {
        case .iconAndCpu:
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                Text("\(Int(telemetryHub.cpu.totalPercent))%")
            }
        case .iconOnly:
            Image(systemName: "waveform.path.ecg")
        case .cpuOnly:
            Text("\(Int(telemetryHub.cpu.totalPercent))%")
        case .iconCpuRam:
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                Text("\(Int(telemetryHub.cpu.totalPercent))% · \(Int(telemetryHub.memory.usedPercentage))%")
            }
        }
    }
}
