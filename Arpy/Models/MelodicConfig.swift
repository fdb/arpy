import Foundation

/// Configuration for melodic/pitch features of a track.
struct MelodicConfig: Codable, Equatable {
    /// Transpose in semitones (-24 to +24).
    var transpose: Int

    /// Musical scale.
    var scale: Scale

    /// Root note.
    var rootNote: Note

    /// Voicing amount (0.0-1.0).
    var voicingAmount: Double

    /// Voicing style.
    var voicingStyle: VoicingStyle

    /// Phrase shape for melodic modulation.
    var phraseShape: PhraseShape

    /// Phrase range in octaves (-3 to +3).
    var phraseRange: Int

    static var `default`: MelodicConfig {
        MelodicConfig(
            transpose: 0,
            scale: .chromatic,
            rootNote: .C,
            voicingAmount: 0.0,
            voicingStyle: .fixed,
            phraseShape: .cadence1,
            phraseRange: 0
        )
    }
}
