import AppKit
import Combine
import SwiftUI

@MainActor
final class AppCoordinator: NSObject {
    private let appState = AppState()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panel = FloatingPanel()
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func start() {
        configurePanel()
        configureStatusItem()
        bindPresentation()

        Task {
            await appState.bootstrap()
        }
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.animationBehavior = .none
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentViewController = NSHostingController(rootView: MenuBarContentView(appState: appState))
        resizePanel(for: appState.panelMode, repositionIfVisible: false)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageLeading
        updateStatusItem(using: appState.menuBarPresentation)
    }

    private func bindPresentation() {
        appState.$menuBarPresentation
            .receive(on: RunLoop.main)
            .sink { [weak self] presentation in
                self?.updateStatusItem(using: presentation)
            }
            .store(in: &cancellables)

        appState.$panelMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.resizePanel(for: mode, repositionIfVisible: true)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem(using presentation: MenuBarPresentation) {
        guard let button = statusItem.button else { return }
        button.title = presentation.title
        button.toolTip = presentation.toolTip
        if let imageSystemName = presentation.imageSystemName {
            button.image = NSImage(systemSymbolName: imageSystemName, accessibilityDescription: presentation.toolTip)
            button.image?.isTemplate = true
        } else {
            button.image = nil
        }
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func resizePanel(for mode: PanelMode, repositionIfVisible: Bool) {
        let size = switch mode {
        case .dashboard: NSSize(width: 380, height: 350)
        case .importCredentials: NSSize(width: 380, height: 500)
        }

        var frame = panel.frame
        frame.size = size
        panel.setFrame(frame, display: false)

        if repositionIfVisible, panel.isVisible {
            positionPanel()
        }
    }

    private func showPanel() {
        positionPanel()
        panel.alphaValue = 1
        panel.makeKeyAndOrderFront(nil)
        installEventMonitorIfNeeded()
    }

    private func closePanel() {
        panel.orderOut(nil)
        removeEventMonitor()
    }

    private func positionPanel() {
        guard
            let button = statusItem.button,
            let buttonWindow = button.window,
            let screen = buttonWindow.screen ?? NSScreen.main
        else { return }

        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)
        let visibleFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let gap: CGFloat = 6

        var originX = buttonFrameOnScreen.midX - panelSize.width / 2
        originX = max(visibleFrame.minX + 8, min(originX, visibleFrame.maxX - panelSize.width - 8))

        let originY = buttonFrameOnScreen.minY - panelSize.height - gap
        let frame = NSRect(origin: CGPoint(x: originX, y: originY), size: panelSize)
        panel.setFrame(frame.integral, display: false)
    }

    private func installEventMonitorIfNeeded() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}

private final class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 350),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
