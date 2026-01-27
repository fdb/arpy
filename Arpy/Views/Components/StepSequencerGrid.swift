import SwiftUI

/// Grid showing all 4 tracks with step visualization.
struct StepSequencerGrid: View {
    @ObservedObject var viewModel: SequencerViewModel

    var body: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.state.tracks) { track in
                TrackRow(
                    track: track,
                    pulsePositions: track.pattern.pulsePositions,
                    currentStep: viewModel.state.isPlaying
                        ? viewModel.state.playheadPositions[track.id]
                        : nil,
                    isSelected: track.id == viewModel.state.selectedTrackId
                )
                .onTapGesture {
                    viewModel.padPressed(track.id)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
        )
    }
}
