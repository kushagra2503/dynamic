import Cocoa
import SwiftUI
import QuartzCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    private var islandExpanded = false

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start monitoring for screen changes
        NotchDetector.startMonitoringScreenChanges()

        // Create the dynamic island window
        createDynamicIslandWindow()

        // Create a status bar item to keep the app running
        createStatusItem()

        // Monitor for screen parameter changes to reposition the island
        setupScreenChangeMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotchDetector.stopMonitoringScreenChanges()
    }

    private func createDynamicIslandWindow() {
        let contentView = DynamicIslandView { [weak self] expanded in
            self?.handleIslandExpansion(expanded)
        }

        let initialSize = NotchDetector.getOptimalIslandSize(expanded: false)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = false
        window?.ignoresMouseEvents = false
        window?.level = .statusBar
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Position perfectly over the notch
        positionWindowOverNotch(animated: false)

        window?.makeKeyAndOrderFront(nil)
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🏝️"
        statusItem?.button?.toolTip = "Dynamic Island"

        let menu = createMenu()
        statusItem?.menu = menu
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Add repositioning option
        menu.addItem(NSMenuItem(
            title: "Reposition Island",
            action: #selector(repositionIsland),
            keyEquivalent: "r"
        ))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        return menu
    }



    @objc private func repositionIsland() {
        NotchDetector.clearCache()
        positionWindowOverNotch(animated: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func handleIslandExpansion(_ expanded: Bool) {
        guard let window = window else { return }

        // Only update if state actually changed to prevent unnecessary animations
        guard islandExpanded != expanded else { return }

        print("DEBUG: handleIslandExpansion - expanded: \(expanded), current islandExpanded: \(islandExpanded)")

        islandExpanded = expanded

        let newSize = NotchDetector.getOptimalIslandSize(expanded: expanded)
        print("DEBUG: newSize - width: \(newSize.width), height: \(newSize.height)")

        // Get the optimal position for the new size
        guard let newPosition = NotchDetector.getDynamicIslandPosition(expanded: expanded) else {
            print("DEBUG: Failed to get optimal position")
            return
        }

        let newFrame = NSRect(
            x: newPosition.x,
            y: newPosition.y,
            width: newSize.width,
            height: newSize.height
        )

        print("DEBUG: newFrame - x: \(newFrame.origin.x), y: \(newFrame.origin.y), w: \(newFrame.width), h: \(newFrame.height)")

        // Always animate window frame changes for smooth transitions
        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.5 : 0.4
            context.timingFunction = CAMediaTimingFunction(name: expanded ? .easeOut : .easeInEaseOut)
            context.allowsImplicitAnimation = false

            window.animator().setFrame(newFrame, display: true)
        }

        print("DEBUG: Animation completed for expanded: \(expanded)")
    }

    private func positionWindowOverNotch(animated: Bool) {
        guard let window = window else { return }

        let currentSize = NotchDetector.getOptimalIslandSize(expanded: islandExpanded)

        guard let position = NotchDetector.getDynamicIslandPosition(expanded: islandExpanded) else {
            // Fallback positioning if notch detection fails
            guard let screen = NSScreen.main else { return }
            let screenFrame = screen.frame
            let fallbackFrame = NSRect(
                x: (screenFrame.width - currentSize.width) / 2,
                y: screenFrame.height - currentSize.height - 8,
                width: currentSize.width,
                height: currentSize.height
            )
            window.setFrame(fallbackFrame, display: true, animate: animated)
            return
        }

        let windowFrame = NSRect(
            x: position.x,
            y: position.y,
            width: currentSize.width,
            height: currentSize.height
        )

        window.setFrame(windowFrame, display: true, animate: animated)
    }

    private func setupScreenChangeMonitoring() {
        // Monitor for display configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delay repositioning to ensure screen parameters are fully updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.positionWindowOverNotch(animated: true)
            }
        }

        // Monitor for space changes (Mission Control, switching desktops)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Ensure the island stays visible when switching spaces
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.window?.orderFront(nil)
            }
        }
    }
}

// MARK: - Window Delegate
extension AppDelegate: NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Prevent the window from being closed
        return false
    }

    func windowDidBecomeKey(_ notification: Notification) {
        // Keep the island at the correct level
        window?.level = .statusBar
    }
}
