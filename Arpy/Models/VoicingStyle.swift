import Foundation

/// Voicing style for melodic variation.
enum VoicingStyle: String, Codable, CaseIterable, Identifiable {
    case fixed
    case ramp
    case climb

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
