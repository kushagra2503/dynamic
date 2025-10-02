import SwiftUI

// MARK: - iOS-style Notch Shape
struct MacNotchShape: Shape {
    let isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = isExpanded ? 22 : min(rect.height / 2, 18)

        // Use RoundedRectangle for guaranteed correct shape
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: rect)
    }
}

// MARK: - Dynamic Island View
struct DynamicIslandView: View {
    @State private var isExpanded = false
    @State private var hoverTask: Task<Void, Never>?

    var onSizeChange: ((Bool) -> Void)?

    var body: some View {
        MacNotchShape(isExpanded: isExpanded)
            .fill(Color.black)
            .frame(
                width: isExpanded ? 380 : 200,
                height: isExpanded ? 60 : 32
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
            .onHover { hovering in
                hoverTask?.cancel()
                hoverTask = Task {
                    // Shorter delay for more responsive feel
                    try? await Task.sleep(nanoseconds: 40_000_000) // 40ms delay
                    if !Task.isCancelled {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isExpanded = hovering
                                onSizeChange?(hovering)
                            }
                        }
                    }
                }
            }
    }
}

