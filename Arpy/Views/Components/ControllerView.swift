import SwiftUI

/// Visual replica of the AKAI LPD8 MKII controller.
struct ControllerView: View {
    @ObservedObject var viewModel: SequencerViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Knobs row
            HStack(spacing: 8) {
                ForEach(1...8, id: \.self) { knobId in
                    KnobView(
                        label: viewModel.currentKnobLabels[knobId - 1],
                        value: knobBinding(for: knobId),
                        displayValue: viewModel.currentKnobDisplayValues[knobId - 1]
                    )
                }
            }

            // Pads row
            HStack(spacing: 8) {
                ForEach(1...8, id: \.self) { padId in
                    PadView(
                        label: padLabel(padId),
                        color: padColor(padId),
                        isActive: padIsActive(padId),
                        sfSymbol: padSymbol(padId),
                        onPress: { viewModel.padPressed(padId) },
                        onRelease: { viewModel.padReleased(padId) }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.25))
        )
    }

    private func knobBinding(for id: Int) -> Binding<Double> {
        Binding(
            get: { viewModel.knobValues[id, default: 0.5] },
            set: { viewModel.knobChanged(id, value: $0) }
        )
    }

    private func padLabel(_ id: Int) -> String {
        switch id {
        case 1...4: return "Track \(id)"
        case 5:     return "Play"
        case 6:     return "Tap"
        case 7:     return "Mute"
        case 8:     return "Melodic"
        default:    return ""
        }
    }

    private func padColor(_ id: Int) -> Color {
        switch id {
        case 1...4: return Color.trackColor(for: id)
        case 5:     return viewModel.state.isPlaying ? .red : .green
        case 6:     return .orange
        case 7:     return .gray
        case 8:     return .yellow
        default:    return .gray
        }
    }

    private func padIsActive(_ id: Int) -> Bool {
        switch id {
        case 1...4: return viewModel.state.selectedTrackId == id
        case 5:     return viewModel.state.isPlaying
        case 7:     return viewModel.selectedTrack.isMuted
        case 8:     return viewModel.state.isMelodicShiftActive
        default:    return false
        }
    }

    private func padSymbol(_ id: Int) -> String? {
        switch id {
        case 1...4: return "\(id).circle.fill"
        case 5:     return viewModel.state.isPlaying ? "stop.fill" : "play.fill"
        case 6:     return "metronome.fill"
        case 7:     return viewModel.selectedTrack.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        case 8:     return "music.note"
        default:    return nil
        }
    }
}
