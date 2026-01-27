import Foundation

/// Pure functions for converting sequencer state into MIDI messages.
enum MIDIEngine {

    /// Generate a MIDI note-on message for a step if it's a pulse position.
    /// - Returns: A noteOn message if the step is active, nil otherwise.
    static func noteForStep(
        track: Track,
        step: Int,
        pulsePositions: [Int]
    ) -> MIDIMessage? {
        guard pulsePositions.contains(step), !track.isMuted else { return nil }

        let baseNote = 60 + track.melodic.rootNote.rawValue + track.melodic.transpose
        let midiNote = max(0, min(127, baseNote))

        return .noteOn(
            channel: track.midiChannel,
            note: midiNote,
            velocity: track.velocity
        )
    }

    /// Compute MIDI note number from melodic configuration.
    /// - Parameters:
    ///   - baseNote: Base MIDI note number.
    ///   - config: Melodic configuration.
    ///   - stepInPhrase: Current step within the phrase.
    ///   - totalSteps: Total steps in the pattern.
    /// - Returns: Computed MIDI note number (0-127).
    static func computeMIDINote(
        baseNote: Int,
        config: MelodicConfig,
        stepInPhrase: Int,
        totalSteps: Int
    ) -> Int {
        guard totalSteps > 0 else { return max(0, min(127, baseNote)) }

        let phraseOffset = PhraseEngine.pitchOffset(
            shape: config.phraseShape,
            step: stepInPhrase,
            totalSteps: totalSteps,
            range: config.phraseRange,
            amount: config.voicingAmount
        )

        let note = baseNote + config.transpose + phraseOffset
        let quantized = ScaleEngine.quantizeToScale(
            midiNote: note,
            scale: config.scale,
            root: config.rootNote
        )

        return max(0, min(127, quantized))
    }

    /// Generate a note-off message for a track.
    static func noteOffForTrack(_ track: Track, note: Int) -> MIDIMessage {
        .noteOff(channel: track.midiChannel, note: max(0, min(127, note)))
    }
}
