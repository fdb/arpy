import SwiftUI

/// A pad button that responds to press and release.
struct PadView: View {
    let label: String
    let color: Color
    let isActive: Bool
    let sfSymbol: String?
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? color : color.opacity(0.4))
                .frame(width: 52, height: 52)
                .overlay(
                    Group {
                        if let symbol = sfSymbol {
                            Image(systemName: symbol)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 4)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                onPress()
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            onRelease()
                        }
                )
                .animation(.easeInOut(duration: 0.1), value: isPressed)

            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
