import SwiftUI
import Cocoa

// MARK: - Mac Notch Shape
struct MacNotchShape: Shape {
    var isExpanded: Bool

    var animatableData: Double {
        get { isExpanded ? 1.0 : 0.0 }
        set { isExpanded = newValue > 0.5 }
    }

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
            // Minimal expanded content - just empty space with subtle indicator
            HStack {
                Spacer()

                // Subtle activity indicator
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isExpanded)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } else {
            // Collapsed content - completely minimal
            EmptyView()
        }
    }
}

// MARK: - Dynamic Island View
struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering = false

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
        .scaleEffect(isHovering && !isExpanded ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1), value: isExpanded)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering

            // Cancel previous hover task
            hoverTask?.cancel()

            hoverTask = Task {
                // Add a small delay to prevent rapid toggling
                try? await Task.sleep(nanoseconds: hovering ? 150_000_000 : 100_000_000) // 150ms for expand, 100ms for collapse

                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isExpanded = hovering
                            onExpansionChange?(hovering)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            // Manual toggle on tap
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
                onExpansionChange?(isExpanded)
            }
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
