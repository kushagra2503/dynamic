import SwiftUI
import Cocoa
import Combine

// MARK: - Mac Notch Shape
struct MacNotchShape: Shape {
    var isExpanded: Bool

    // Removed animatableData to prevent continuous animation

    func path(in rect: CGRect) -> Path {
        // Use detected notch corner radius for perfect matching
        let cornerRadius: CGFloat
        if isExpanded {
            cornerRadius = 24
        } else {
            cornerRadius = NotchDetector.getNotchCornerRadius()
        }

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: rect)
    }
}

// MARK: - Dynamic Island Content
struct DynamicIslandContent: View {
    let isExpanded: Bool
    let isCharging: Bool
    let batteryLevel: Int
    let chargingTimeRemaining: String
    let showChargingContent: Bool
    let forceExpanded: Bool

    var body: some View {
        if isExpanded {
            if isCharging && (forceExpanded || showChargingContent) {
                // Charging content
                HStack(spacing: 12) {
                    // Left side - charging icon and status
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Charging")
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .semibold))

                            if chargingTimeRemaining != "Unknown" && chargingTimeRemaining != "Calculating..." {
                                Text(chargingTimeRemaining)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }

                    Spacer()

                    // Right side - battery level
                    HStack(spacing: 8) {
                        // Battery percentage
                        Text("\(batteryLevel)%")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))

                        // Battery icon
                        ZStack {
                            // Battery outline
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                .frame(width: 24, height: 12)

                            // Battery fill
                            RoundedRectangle(cornerRadius: 1)
                                .fill(batteryLevel > 20 ? Color.green : Color.red)
                                .frame(width: CGFloat(batteryLevel) / 100 * 20, height: 8)
                                .offset(x: -CGFloat(100 - batteryLevel) / 100 * 10)

                            // Battery terminal
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 2, height: 6)
                                .offset(x: 13)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                // Non-charging expanded content - minimal
                HStack {
                    Spacer()

                    // Simple dot indicator
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        } else {
            if isCharging && (forceExpanded || showChargingContent) {
                // Collapsed charging indicator - only during automatic expansion
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 10, weight: .bold))

                    Text("\(batteryLevel)%")
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .opacity(0.9)
            } else {
                // Collapsed content - completely empty
                Color.clear
            }
        }
    }
}

// MARK: - Dynamic Island View
struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering = false
    @State private var lastHoverState = false
    @State private var forceExpanded = false
    @State private var forceExpandedTimer: Timer?
    @State private var showChargingContent = false

    // Battery monitoring
    @StateObject private var batteryMonitor = BatteryMonitor.shared
    @State private var chargingTimeRemaining = "Unknown"

    let onExpansionChange: ((Bool) -> Void)?

    init(onExpansionChange: ((Bool) -> Void)? = nil) {
        self.onExpansionChange = onExpansionChange
    }

    var body: some View {
        ZStack {
            // Background shape
            MacNotchShape(isExpanded: isExpanded)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    // Subtle inner shadow/highlight
                    MacNotchShape(isExpanded: isExpanded)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)

            // Content
            DynamicIslandContent(
                isExpanded: isExpanded || forceExpanded,
                isCharging: batteryMonitor.isCharging,
                batteryLevel: batteryMonitor.batteryLevel,
                chargingTimeRemaining: chargingTimeRemaining,
                showChargingContent: showChargingContent,
                forceExpanded: forceExpanded
            )
            .onChange(of: forceExpanded) { newValue in
                // Ensure AppDelegate is notified when forceExpanded changes
                onExpansionChange?(newValue || isExpanded)
            }
            .onChange(of: showChargingContent) { newValue in
                // Start auto-collapse timer when charging content appears
                if newValue {
                    startChargingAutoCollapse()
                }
            }
        }
        .frame(
            width: (isExpanded || forceExpanded) ? 380 : NotchDetector.getOptimalIslandSize(expanded: false).width,
            height: (isExpanded || forceExpanded) ? 64 : NotchDetector.getOptimalIslandSize(expanded: false).height
        )
        .onHover { hovering in
            // Immediate early return if same state
            guard lastHoverState != hovering else {
                return
            }

            lastHoverState = hovering
            isHovering = hovering

            // Cancel any existing task
            hoverTask?.cancel()

            // Handle transition from charging expansion to manual hover
            if hovering && forceExpanded {
                // User is hovering during charging expansion - transfer control to manual hover
                forceExpanded = false // Transfer control to manual hover
                isExpanded = true
                onExpansionChange?(true)
                return
            }

            // Only change if different from current expanded state
            guard isExpanded != hovering else {
                return
            }

            // Manual hover cancels force expansion and charging content
            if hovering && forceExpanded {
                forceExpanded = false
                showChargingContent = false
            }

            // Add smooth animation only during state change
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = hovering
            }
            onExpansionChange?(hovering || forceExpanded)
        }
        .onTapGesture {
            // Manual toggle on tap - cancel any hover tasks
            hoverTask?.cancel()
            let newState = !isExpanded
            lastHoverState = newState
            isHovering = newState

            // Manual tap cancels force expansion and charging content
            if forceExpanded {
                forceExpanded = false
                showChargingContent = false
            }

            // Add smooth animation for manual toggle
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = newState
            }
            onExpansionChange?(newState || forceExpanded)
        }
        // Accessibility
        .accessibilityElement()
        .accessibilityLabel("Dynamic Island")
        .accessibilityHint((isExpanded || forceExpanded) ? "Tap to collapse" : "Tap to expand")
        .accessibilityAddTraits((isExpanded || forceExpanded) ? .isSelected : [])
        .onAppear {
            setupBatteryMonitoring()
        }
        .onDisappear {
            cleanupBatteryMonitoring()
        }
    }

    // MARK: - Battery Monitoring Methods

    private func setupBatteryMonitoring() {
        // Listen for battery state changes
        NotificationCenter.default.addObserver(
            forName: .batteryStateChanged,
            object: nil,
            queue: .main
        ) { notification in
            handleBatteryStateChange(notification)
        }

        // Update charging time initially
        updateChargingTime()

        // Set up timer to update charging time regularly
        forceExpandedTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            updateChargingTime()
        }
    }

    private func cleanupBatteryMonitoring() {
        NotificationCenter.default.removeObserver(self, name: .batteryStateChanged, object: nil)
        forceExpandedTimer?.invalidate()
        forceExpandedTimer = nil
    }

    private func handleBatteryStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let wasCharging = userInfo["wasCharging"] as? Bool ?? false
        let isCharging = userInfo["isCharging"] as? Bool ?? false
        let wasPluggedIn = userInfo["wasPluggedIn"] as? Bool ?? false
        let isPluggedIn = userInfo["isPluggedIn"] as? Bool ?? false

        updateChargingTime()

        // Show charging animation when plugged in - instant content display
        if !wasPluggedIn && isPluggedIn {
            // Show charging content and expansion immediately
            showChargingContent = true
            forceExpanded = true
            onExpansionChange?(true)
        }

        // If we start actually charging after plugging in, ensure content is visible
        if !wasCharging && isCharging && isPluggedIn {
            showChargingContent = true
            if !forceExpanded {
                forceExpanded = true
                onExpansionChange?(true)
            }
        }

        // Hide when unplugged
        if wasPluggedIn && !isPluggedIn {
            showChargingContent = false
            hideChargingIndicator()
        }

        // If charging stops but still plugged in (battery full), hide after delay
        if wasCharging && !isCharging && isPluggedIn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !self.isHovering && self.forceExpanded && !self.batteryMonitor.isCharging {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        self.forceExpanded = false
                        self.showChargingContent = false
                    }
                    // Notify AppDelegate about collapse to return to exact notch size
                    self.onExpansionChange?(false)
                }
            }
        }
    }

    private func startChargingAutoCollapse() {
        // Auto-collapse after 2 seconds if actively charging, or 5 seconds if not charging
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.isHovering && self.forceExpanded && self.batteryMonitor.isCharging {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.forceExpanded = false
                    self.showChargingContent = false
                }
                // Notify AppDelegate about collapse to return to exact notch size
                self.onExpansionChange?(false)
            }
        }

        // Fallback: Auto-collapse after 5 seconds if not charging
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if !self.isHovering && self.forceExpanded && !self.batteryMonitor.isCharging {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.forceExpanded = false
                    self.showChargingContent = false
                }
                // Notify AppDelegate about collapse to return to exact notch size
                self.onExpansionChange?(false)
            }
        }
    }

    private func hideChargingIndicator() {
        if forceExpanded && !isHovering {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                forceExpanded = false
                showChargingContent = false
            }
            // Notify AppDelegate about collapse to return to exact notch size
            onExpansionChange?(false)
        }
    }

    private func updateChargingTime() {
        chargingTimeRemaining = batteryMonitor.getChargingTimeRemaining()
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct DynamicIslandView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicIslandView()
            .frame(width: 400, height: 100)
            .background(Color.black.opacity(0.1))
    }
}
#endif
