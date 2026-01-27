import SwiftUI

/// A single step cell in the sequencer grid.
struct StepCell: View {
    let isActive: Bool
    let isPlayhead: Bool
    let trackColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isActive ? trackColor.opacity(0.9) : Color.stepInactive)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isPlayhead ? Color.playhead : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .frame(height: 28)
    }
}
