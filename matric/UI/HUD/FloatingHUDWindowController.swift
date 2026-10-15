import AppKit
import SwiftUI
import Observation

@Observable
@MainActor
public final class FloatingHUDWindowController {
    public static let shared = FloatingHUDWindowController()
    
    public var isVisible: Bool = false
    public var isPinned: Bool = true
    
    private var panel: NSPanel?
    
    private init() {}
    
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        if panel == nil {
            createPanel()
        }
        
        panel?.orderFrontRegardless()
        isVisible = true
    }
    
    public func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
    
    public func togglePin() {
        isPinned.toggle()
        if let panel = panel {
            panel.level = isPinned ? .floating : .normal
        }
        // Update content view to reflect pin state
        updateContentView()
    }
    
    private func createPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 230, height: 110),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        p.isFloatingPanel = true
        p.level = isPinned ? .floating : .normal
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = true
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.hidesOnDeactivate = false
        
        // Position at top right by default if not previously moved
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 250
            let y = screenRect.maxY - 140
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.panel = p
        updateContentView()
    }
    
    private func updateContentView() {
        guard let panel = panel else { return }
        
        let hudView = FloatingHUDView(
            isPinned: isPinned,
            onClose: { [weak self] in
                self?.hide()
            },
            onTogglePin: { [weak self] in
                self?.togglePin()
            }
        )
        .environment(SystemTelemetryHub.shared)
        .environment(AppState())
        
        let hostingView = NSHostingView(rootView: hudView)
        panel.contentView = hostingView
    }
}
