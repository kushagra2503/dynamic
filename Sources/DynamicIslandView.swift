import SwiftUI

// MARK: - Mac Notch Shape
struct MacNotchShape: Shape {
    var isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = isExpanded ? 22 : min(rect.height / 2, 18)
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: rect)
    }
}

// MARK: - Dynamic Island View
struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var hoverTask: Task<Void, Never>?

    let onExpansionChange: ((Bool) -> Void)?

    init(onExpansionChange: ((Bool) -> Void)? = nil) {
        self.onExpansionChange = onExpansionChange
    }

    var body: some View {
        MacNotchShape(isExpanded: isExpanded)
            .fill(Color.black)
            .frame(width: isExpanded ? 380 : 200,
                   height: isExpanded ? 60 : 32)
            .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
            .offset(y: isExpanded ? 0 : -20) // slide behind notch when collapsed
            .onHover { hovering in
                hoverTask?.cancel()
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    if !Task.isCancelled {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded = hovering
                                onExpansionChange?(hovering)
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - Floating Dynamic Island Container
struct FloatingDynamicIslandContainer: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear.ignoresSafeArea() // optional: background

                DynamicIslandView()
                    // Position top center
                    .position(
                        x: geometry.size.width / 2,
                        y: safeTopInset() + 20 // 20 for overlap adjustment
                    )
            }
        }
    }

    // Automatically get top safe area inset for notch
    func safeTopInset() -> CGFloat {
        #if os(macOS)
        // macOS doesn't have safeAreaInsets in SwiftUI, so return a default notch offset
        return 10
        #else
        return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20
        #endif
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingDynamicIslandContainer()
            .frame(width: 800, height: 600)
    }
}
