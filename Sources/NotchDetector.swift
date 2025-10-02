import Cocoa
import CoreGraphics

class NotchDetector {

    // Cache for notch measurements to avoid repeated calculations
    private static var cachedNotchRect: NSRect?
    private static var cachedHasNotch: Bool?

    /// Detects the actual notch rectangle by analyzing screen geometry and safe areas
    static func getNotchRect() -> NSRect? {
        if let cached = cachedNotchRect {
            return cached
        }

        guard let screen = NSScreen.main else { return nil }

        let screenFrame = screen.frame
        let safeAreaTop = screen.safeAreaInsets.top

        // Check if device has a notch by examining safe area
        guard safeAreaTop > 5 else {
            // No notch detected - return fallback position at top center
            let fallbackRect = createFallbackRect(screenFrame: screenFrame)
            cachedNotchRect = fallbackRect
            return fallbackRect
        }

        // Detect actual notch dimensions based on Mac model
        let notchDimensions = detectNotchDimensions(screenFrame: screenFrame, safeAreaTop: safeAreaTop)

        // Position notch at top center of screen
        let notchX = (screenFrame.width - notchDimensions.width) / 2
        let notchY = screenFrame.height - notchDimensions.height

        let notchRect = NSRect(
            x: screenFrame.origin.x + notchX,
            y: screenFrame.origin.y + notchY,
            width: notchDimensions.width,
            height: notchDimensions.height
        )

        cachedNotchRect = notchRect
        return notchRect
    }

    /// Detects if the current Mac has a notch
    static func hasNotch() -> Bool {
        if let cached = cachedHasNotch {
            return cached
        }

        guard let screen = NSScreen.main else {
            cachedHasNotch = false
            return false
        }

        let hasNotchResult = screen.safeAreaInsets.top > 5
        cachedHasNotch = hasNotchResult
        return hasNotchResult
    }

    /// Returns optimal Dynamic Island size based on expansion state and detected notch
    static func getOptimalIslandSize(expanded: Bool) -> NSSize {
        if expanded {
            // Expanded state - wider for dramatic effect
            return NSSize(width: 380, height: 64)
        } else {
            // Collapsed state - match actual notch size
            guard let notchRect = getNotchRect() else {
                return NSSize(width: 160, height: 32)
            }

            // Use actual notch dimensions for perfect overlay
            return NSSize(
                width: notchRect.width,
                height: notchRect.height
            )
        }
    }

    /// Get the exact position where the Dynamic Island should be placed
    static func getDynamicIslandPosition(expanded: Bool) -> NSPoint? {
        guard let notchRect = getNotchRect() else { return nil }

        let islandSize = getOptimalIslandSize(expanded: expanded)

        // Center the island horizontally over the notch
        let x = notchRect.origin.x + (notchRect.width - islandSize.width) / 2

        // Position vertically to perfectly overlay the notch
        let y = notchRect.origin.y + (notchRect.height - islandSize.height) / 2

        return NSPoint(x: x, y: y)
    }

    // MARK: - Private Helper Methods

    /// Detects notch dimensions based on screen characteristics
    private static func detectNotchDimensions(screenFrame: NSRect, safeAreaTop: CGFloat) -> NSSize {
        let screenWidth = screenFrame.width
        let _ = screenFrame.height

        // MacBook Pro 14" and 16" have different notch sizes
        // Detect based on screen resolution

        if screenWidth >= 3456 { // MacBook Pro 16" (3456x2234 or 3024x1964)
            return NSSize(width: 216, height: 32)
        } else if screenWidth >= 3024 { // MacBook Pro 14" (3024x1964)
            return NSSize(width: 200, height: 30)
        } else if screenWidth >= 2560 { // Potential future models or scaled resolutions
            return NSSize(width: 190, height: 28)
        } else {
            // Fallback based on safe area ratio
            let estimatedWidth = max(160, min(220, screenWidth * 0.08))
            let estimatedHeight = max(24, min(35, safeAreaTop * 0.9))
            return NSSize(width: estimatedWidth, height: estimatedHeight)
        }
    }

    /// Creates a fallback rectangle for devices without notch
    private static func createFallbackRect(screenFrame: NSRect) -> NSRect {
        let fallbackWidth: CGFloat = 160
        let fallbackHeight: CGFloat = 32
        let fallbackX = (screenFrame.width - fallbackWidth) / 2
        let fallbackY = screenFrame.height - fallbackHeight - 8

        return NSRect(
            x: screenFrame.origin.x + fallbackX,
            y: screenFrame.origin.y + fallbackY,
            width: fallbackWidth,
            height: fallbackHeight
        )
    }

    /// Clears cached values (useful for screen changes or multi-monitor setups)
    static func clearCache() {
        cachedNotchRect = nil
        cachedHasNotch = nil
    }

    /// Gets notch corner radius based on detected size
    static func getNotchCornerRadius() -> CGFloat {
        guard let notchRect = getNotchRect() else { return 16 }

        // Corner radius should be proportional to notch height
        return min(notchRect.height / 2, 18)
    }

    /// Returns true if Dynamic Island should be visible (e.g., not in fullscreen apps)
    static func shouldShowDynamicIsland() -> Bool {
        // Check if any app is in fullscreen mode
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.isActive {
                // You could add more sophisticated logic here to detect fullscreen apps
                // For now, always show the island
                return true
            }
        }
        return true
    }
}

// MARK: - Screen Change Notifications
extension NotchDetector {

    /// Call this to monitor for screen changes and update notch detection
    static func startMonitoringScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            clearCache()
        }
    }

    /// Stop monitoring screen changes
    static func stopMonitoringScreenChanges() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
}
