import Foundation

/// Root state object for the entire sequencer.
struct SequencerState: Codable, Equatable {
    /// Four independent tracks.
    var tracks: [Track]

    /// Tempo in BPM (40-240).
    var tempo: Double

    /// Whether the sequencer is playing.
    var isPlaying: Bool

    /// Clock source (internal or external).
    var clockSource: ClockSource

    /// Currently selected track ID (1-4).
    var selectedTrackId: Int

    /// Whether melodic shift mode is active.
    var isMelodicShiftActive: Bool

    /// Current playhead position per track (trackId -> step index).
    var playheadPositions: [Int: Int]

    static var `default`: SequencerState {
        SequencerState(
            tracks: (1...4).map { Track.defaultTrack(id: $0) },
            tempo: 120.0,
            isPlaying: false,
            clockSource: .internal,
            selectedTrackId: 1,
            isMelodicShiftActive: false,
            playheadPositions: [1: 0, 2: 0, 3: 0, 4: 0]
        )
    }
}
