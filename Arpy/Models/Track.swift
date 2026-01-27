import Foundation

/// A single sequencer track with pattern, melodic, and playback settings.
struct Track: Codable, Equatable, Identifiable {
    /// Track identifier (1-4).
    let id: Int

    /// Euclidean pattern configuration.
    var pattern: EuclideanPattern

    /// Melodic/pitch configuration.
    var melodic: MelodicConfig

    /// Note velocity (1-127).
    var velocity: Int

    /// Note sustain as percentage of division (0.0-1.0).
    var sustain: Double

    /// Number of note repeats (0-8).
    var repeats: Int

    /// Whether track output is muted.
    var isMuted: Bool

    /// MIDI output channel (equals track id).
    var midiChannel: Int

    static func defaultTrack(id: Int) -> Track {
        Track(
            id: id,
            pattern: .default,
            melodic: .default,
            velocity: 100,
            sustain: 0.8,
            repeats: 0,
            isMuted: false,
            midiChannel: id
        )
    }
}
