import SwiftUI

/// A single track row in the step sequencer grid.
struct TrackRow: View {
    let track: Track
    let pulsePositions: [Int]
    let currentStep: Int?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            // Track label
            Image(systemName: "\(track.id).circle.fill")
                .foregroundColor(Color.trackColor(for: track.id))
                .font(.title3)
                .frame(width: 24)

            // Step cells
            ForEach(0..<track.pattern.steps, id: \.self) { step in
                StepCell(
                    isActive: pulsePositions.contains(step),
                    isPlayhead: currentStep == step,
                    trackColor: Color.trackColor(for: track.id)
                )
            }
        }
        .opacity(track.isMuted ? 0.3 : 1.0)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
        )
    }
}
