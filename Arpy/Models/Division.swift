import Foundation

/// Time division for step sequencer timing.
enum Division: String, Codable, CaseIterable, Identifiable {
    case whole = "1/1"
    case half = "1/2"
    case quarter = "1/4"
    case eighth = "1/8"
    case sixteenth = "1/16"
    case thirtySecond = "1/32"

    var id: String { rawValue }

    /// Number of MIDI clock ticks per step at this division.
    /// Based on 24 PPQ (MIDI standard).
    var ticksPerStep: Int {
        switch self {
        case .whole:        return 96  // 24 * 4
        case .half:         return 48  // 24 * 2
        case .quarter:      return 24  // 24 * 1
        case .eighth:       return 12  // 24 / 2
        case .sixteenth:    return 6   // 24 / 4
        case .thirtySecond: return 3   // 24 / 8
        }
    }
}
