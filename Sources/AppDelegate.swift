import Cocoa
import SwiftUI
import QuartzCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the dynamic island window
        createDynamicIslandWindow()

        // Create a status bar item to keep the app running
        createStatusItem()
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
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Position over the notch initially
        positionWindowOverNotch()

        window?.makeKeyAndOrderFront(nil)
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🏝️"
        statusItem?.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func handleIslandExpansion(_ expanded: Bool) {
        guard let window = window else { return }

        let newSize = NotchDetector.getOptimalIslandSize(expanded: expanded)
        guard let notchRect = NotchDetector.getNotchRect() else { return }

        // Calculate new frame centered on the notch
        let newFrame = NSRect(
            x: notchRect.origin.x + (notchRect.width - newSize.width) / 2,
            y: notchRect.origin.y,
            width: newSize.width,
            height: newSize.height
        )

        // Use a more performant animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = false
            window.animator().setFrame(newFrame, display: false)
        }
    }

    private func positionWindowOverNotch() {
        guard let window = window else { return }

        // Use NotchDetector to get the optimal position
        guard let notchRect = NotchDetector.getNotchRect() else { return }

        // Set initial size to compact version
        let initialSize = NotchDetector.getOptimalIslandSize(expanded: false)

        let windowFrame = NSRect(
            x: notchRect.origin.x + (notchRect.width - initialSize.width) / 2,
            y: notchRect.origin.y,
            width: initialSize.width,
            height: initialSize.height
        )

        window.setFrame(windowFrame, display: true)
    }
}
