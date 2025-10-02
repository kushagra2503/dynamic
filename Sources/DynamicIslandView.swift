import SwiftUI
import Cocoa

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

    var body: some View {
        if isExpanded {
            // Minimal expanded content
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
        } else {
            // Collapsed content - completely empty
            Color.clear
        }
    }
}

// MARK: - Dynamic Island View
struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering = false
    @State private var lastHoverState = false

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
            DynamicIslandContent(isExpanded: isExpanded)
        }
        .frame(
            width: isExpanded ? 380 : NotchDetector.getOptimalIslandSize(expanded: false).width,
            height: isExpanded ? 64 : NotchDetector.getOptimalIslandSize(expanded: false).height
        )
        .onHover { hovering in
            // Immediate early return if same state
            guard lastHoverState != hovering else {
                return
            }

            // Update state immediately
            lastHoverState = hovering
            isHovering = hovering

            // Cancel previous task
            hoverTask?.cancel()

            // Only change if different from current expanded state
            guard isExpanded != hovering else {
                return
            }

            // Add smooth animation only during state change
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = hovering
            }
            onExpansionChange?(hovering)
        }
        .onTapGesture {
            // Manual toggle on tap - cancel any hover tasks
            hoverTask?.cancel()
            let newState = !isExpanded
            lastHoverState = newState
            isHovering = newState

            // Add smooth animation for manual toggle
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = newState
            }
            onExpansionChange?(newState)
        }
        // Accessibility
        .accessibilityElement()
        .accessibilityLabel("Dynamic Island")
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
        .accessibilityAddTraits(isExpanded ? .isSelected : [])
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
