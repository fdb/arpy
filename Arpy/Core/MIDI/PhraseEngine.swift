import Foundation

/// Pure functions for computing phrase-based pitch modulation.
enum PhraseEngine {

    /// Compute a pitch offset based on phrase shape, position, and range.
    /// - Parameters:
    ///   - shape: The phrase shape to apply.
    ///   - step: Current step in the phrase.
    ///   - totalSteps: Total steps in the phrase.
    ///   - range: Octave range (-3 to +3).
    ///   - amount: Modulation amount (0.0-1.0).
    /// - Returns: Pitch offset in semitones.
    static func pitchOffset(
        shape: PhraseShape,
        step: Int,
        totalSteps: Int,
        range: Int,
        amount: Double
    ) -> Int {
        guard totalSteps > 0, amount > 0.0, range != 0 else { return 0 }

        let phase = Double(step) / Double(totalSteps)
        let maxOffset = Double(range * 12)
        let rawOffset: Double

        switch shape {
        case .cadence1:
            // Rising pattern: I-IV-V-I
            let degrees = [0.0, 5.0/12.0, 7.0/12.0, 0.0]
            let index = Int(phase * Double(degrees.count)) % degrees.count
            rawOffset = degrees[index] * maxOffset

        case .cadence2:
            // I-V-vi-IV
            let degrees = [0.0, 7.0/12.0, 9.0/12.0, 5.0/12.0]
            let index = Int(phase * Double(degrees.count)) % degrees.count
            rawOffset = degrees[index] * maxOffset

        case .cadence3:
            // I-vi-IV-V
            let degrees = [0.0, 9.0/12.0, 5.0/12.0, 7.0/12.0]
            let index = Int(phase * Double(degrees.count)) % degrees.count
            rawOffset = degrees[index] * maxOffset

        case .cadence4:
            // I-IV-vi-V
            let degrees = [0.0, 5.0/12.0, 9.0/12.0, 7.0/12.0]
            let index = Int(phase * Double(degrees.count)) % degrees.count
            rawOffset = degrees[index] * maxOffset

        case .saw:
            rawOffset = phase * maxOffset

        case .triangle:
            rawOffset = (phase < 0.5 ? phase * 2.0 : 2.0 - phase * 2.0) * maxOffset

        case .sine:
            rawOffset = sin(phase * .pi * 2.0) * maxOffset * 0.5 + maxOffset * 0.5

        case .pulse:
            rawOffset = phase < 0.5 ? maxOffset : 0.0
        }

        return Int(round(rawOffset * amount))
    }
}
