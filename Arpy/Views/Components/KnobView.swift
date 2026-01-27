import SwiftUI

/// Visual knob control with label and value display.
struct KnobView: View {
    let label: String
    @Binding var value: Double
    let displayValue: String

    private let knobSize: CGFloat = 48

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)

            ZStack {
                // Knob background
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: knobSize, height: knobSize)

                // Knob indicator arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + 0.7 * value)
                    .stroke(Color.white, lineWidth: 3)
                    .rotationEffect(.degrees(90))
                    .frame(width: knobSize - 8, height: knobSize - 8)

                // Center dot
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        let delta = -gesture.translation.height / 150.0
                        value = max(0, min(1, value + delta))
                    }
            )

            Text(displayValue)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}
