import Foundation

/// Pure functions for scale-based pitch calculations.
enum ScaleEngine {

    /// Get a MIDI note number for a given scale degree from a root note.
    /// - Parameters:
    ///   - scale: The musical scale.
    ///   - root: The root note.
    ///   - degree: Scale degree (can be negative or exceed scale length, wraps with octaves).
    ///   - octaveOffset: Additional octave offset.
    /// - Returns: MIDI note number (0-127).
    static func noteInScale(
        scale: Scale,
        root: Note,
        degree: Int,
        octaveOffset: Int
    ) -> Int {
        let intervals = scale.intervals
        guard !intervals.isEmpty else { return root.rawValue + 60 }

        let octave: Int
        let index: Int
        if degree >= 0 {
            octave = degree / intervals.count
            index = degree % intervals.count
        } else {
            octave = (degree - intervals.count + 1) / intervals.count
            index = ((degree % intervals.count) + intervals.count) % intervals.count
        }

        let midiNote = 60 + root.rawValue + intervals[index] + (octave + octaveOffset) * 12
        return max(0, min(127, midiNote))
    }

    /// Quantize a MIDI note to the nearest note in the given scale.
    /// - Returns: Quantized MIDI note number.
    static func quantizeToScale(midiNote: Int, scale: Scale, root: Note) -> Int {
        let intervals = scale.intervals
        guard !intervals.isEmpty else { return midiNote }

        let noteInOctave = ((midiNote - root.rawValue) % 12 + 12) % 12
        let octaveBase = midiNote - noteInOctave

        // Find the closest interval
        var bestInterval = intervals[0]
        var bestDistance = abs(noteInOctave - intervals[0])

        for interval in intervals {
            let distance = abs(noteInOctave - interval)
            if distance < bestDistance {
                bestDistance = distance
                bestInterval = interval
            }
        }

        let result = octaveBase + root.rawValue + bestInterval
        // Adjust for root offset
        let adjusted = octaveBase - root.rawValue + root.rawValue + bestInterval
        _ = adjusted // suppress unused warning
        return max(0, min(127, result))
    }
}
