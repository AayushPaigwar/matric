import SwiftUI

public struct SidebarView: View {
    @Environment(AppState.self) private var appState
    private var alertsManager = AlertsManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / App Title
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("Matric")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Navigation Groups
            List(selection: Binding(
                get: { appState.selectedItem },
                set: { if let item = $0 { appState.select(item) } }
            )) {
                // RESOURCES Section
                Section {
                    ForEach(NavigationItem.allCases.filter { $0.group == .resources }) { item in
                        NavigationLink(value: item) {
                            Label {
                                Text(item.rawValue)
                                    .font(.system(size: 13, weight: .regular))
                            } icon: {
                                Image(systemName: item.iconName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(appState.selectedItem == item ? Color.accentColor : .secondary)
                                    .frame(width: 18)
                            }
                        }
                    }
                } header: {
                    Text("RESOURCES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                        .padding(.top, 6)
                }
                
                // WORKSPACE Section
                Section {
                    ForEach(NavigationItem.allCases.filter { $0.group == .workspace }) { item in
                        NavigationLink(value: item) {
                            HStack {
                                Label {
                                    Text(item.rawValue)
                                        .font(.system(size: 13, weight: .regular))
                                } icon: {
                                    Image(systemName: item.iconName)
                                        .font(.system(size: 12))
                                        .foregroundStyle(appState.selectedItem == item ? Color.accentColor : .secondary)
                                        .frame(width: 18)
                                }
                                
                                Spacer()
                                
                                if item == .alerts && alertsManager.activeAlertsCount > 0 {
                                    Text("\(alertsManager.activeAlertsCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Capsule().fill(Color.red))
                                }
                            }
                        }
                    }
                } header: {
                    Text("WORKSPACE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                        .padding(.top, 10)
                }
            }
            .listStyle(.sidebar)
            
            // Hardware Badge Card Footer
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Mac")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        Text("\(appState.hardwareInfo.coreCount) cores · \(appState.hardwareInfo.ramGB) GB")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        appState.select(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundStyle(appState.selectedItem == .settings ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open Preferences (⌘,)")
                }
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("All systems nominal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
    }
}
