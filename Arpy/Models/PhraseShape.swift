import Foundation

/// Phrase shape for melodic pattern modulation.
enum PhraseShape: String, Codable, CaseIterable, Identifiable {
    case cadence1
    case cadence2
    case cadence3
    case cadence4
    case saw
    case triangle
    case sine
    case pulse

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cadence1: return "Cadence 1"
        case .cadence2: return "Cadence 2"
        case .cadence3: return "Cadence 3"
        case .cadence4: return "Cadence 4"
        case .saw:      return "Saw"
        case .triangle: return "Triangle"
        case .sine:     return "Sine"
        case .pulse:    return "Pulse"
        }
    }
}
