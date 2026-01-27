import Foundation

/// Clock source for sequencer timing.
enum ClockSource: String, Codable {
    case `internal`
    case external
}
