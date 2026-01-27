import SwiftUI

/// Transport controls: Play/Stop, Tempo, Clock source.
struct TransportBar: View {
    @ObservedObject var viewModel: SequencerViewModel

    var body: some View {
        HStack(spacing: 20) {
            // Play/Stop
            Button(action: { viewModel.togglePlayStop() }) {
                Image(systemName: viewModel.state.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.state.isPlaying ? .red : .green)
            }
            .buttonStyle(.plain)

            Divider().frame(height: 24)

            // Tempo
            HStack(spacing: 4) {
                Image(systemName: "metronome.fill")
                    .foregroundColor(.secondary)
                Text("\(Int(viewModel.state.tempo)) BPM")
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 80, alignment: .leading)
            }

            Divider().frame(height: 24)

            // Clock source (click to toggle)
            Button(action: {
                viewModel.state.clockSource = viewModel.state.clockSource == .internal
                    ? .external : .internal
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.state.clockSource == .internal
                        ? "clock.fill"
                        : "clock.arrow.2.circlepath")
                        .foregroundColor(.secondary)
                    Text(viewModel.state.clockSource == .internal ? "INT" : "EXT")
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .buttonStyle(.plain)
            .help("Clock source: click to toggle Internal/External")

            Spacer()

            // Melodic shift indicator
            if viewModel.state.isMelodicShiftActive {
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                    Text("MELODIC")
                }
                .font(.caption)
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.yellow.opacity(0.2)))
            }

            // Panic button
            Button(action: { viewModel.panic() }) {
                Image(systemName: "xmark.octagon")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Panic — Send All Notes Off on all channels (use if notes get stuck)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.15))
        )
    }
}
