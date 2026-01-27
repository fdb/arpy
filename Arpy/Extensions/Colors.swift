import SwiftUI

extension Color {
    static let track1 = Color(red: 0.98, green: 0.36, blue: 0.35)    // Coral
    static let track2 = Color(red: 0.30, green: 0.69, blue: 0.31)    // Green
    static let track3 = Color(red: 0.25, green: 0.47, blue: 0.85)    // Blue
    static let track4 = Color(red: 0.61, green: 0.35, blue: 0.71)    // Purple

    static let playhead = Color.white
    static let stepInactive = Color.gray.opacity(0.2)
    static let stepActive = Color.white.opacity(0.9)

    static func trackColor(for id: Int) -> Color {
        switch id {
        case 1: return .track1
        case 2: return .track2
        case 3: return .track3
        case 4: return .track4
        default: return .gray
        }
    }
}
