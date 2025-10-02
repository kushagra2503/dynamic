import Cocoa

class NotchDetector {
    static func getNotchRect() -> NSRect? {
        guard let screen = NSScreen.main else { return nil }

        // Check if the device has a notch by examining the safe area
        let safeAreaTop = screen.safeAreaInsets.top

        // If there's a significant top safe area, we likely have a notch
        if safeAreaTop > 10 {
            let screenFrame = screen.frame
            let notchWidth: CGFloat = 200 // Approximate notch width
            let notchHeight: CGFloat = safeAreaTop + 5 // Include some padding
            let notchX = (screenFrame.width - notchWidth) / 2
            let notchY = screenFrame.height - notchHeight

            return NSRect(
                x: screenFrame.origin.x + notchX,
                y: screenFrame.origin.y + notchY,
                width: notchWidth,
                height: notchHeight
            )
        }

        // Fallback for devices without notch - position at top center
        let screenFrame = screen.frame
        let fallbackWidth: CGFloat = 120
        let fallbackHeight: CGFloat = 35
        let fallbackX = (screenFrame.width - fallbackWidth) / 2
        let fallbackY = screenFrame.height - fallbackHeight - 10

        return NSRect(
            x: screenFrame.origin.x + fallbackX,
            y: screenFrame.origin.y + fallbackY,
            width: fallbackWidth,
            height: fallbackHeight
        )
    }

    static func hasNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 10
    }

    static func getOptimalIslandSize(expanded: Bool) -> NSSize {
        if expanded {
            return NSSize(width: 380, height: 60) // Wider expansion for more dramatic effect
        } else {
            return hasNotch() ? NSSize(width: 200, height: 32) : NSSize(width: 180, height: 32) // Match notch width more closely
        }
    }
}
