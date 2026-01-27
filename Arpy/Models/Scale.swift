import Foundation

/// Musical scale definitions with semitone intervals from root.
enum Scale: String, Codable, CaseIterable, Identifiable {
    case chromatic
    case major
    case minor
    case pentatonic
    case hirajoshi
    case iwato
    case tetratonic

    var id: String { rawValue }

    /// Semitone intervals from the root note.
    var intervals: [Int] {
        switch self {
        case .chromatic:   return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        case .major:       return [0, 2, 4, 5, 7, 9, 11]
        case .minor:       return [0, 2, 3, 5, 7, 8, 10]
        case .pentatonic:  return [0, 2, 4, 7, 9]
        case .hirajoshi:   return [0, 2, 3, 7, 8]
        case .iwato:       return [0, 1, 5, 6, 10]
        case .tetratonic:  return [0, 3, 5, 7]
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
