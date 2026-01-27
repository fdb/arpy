import Foundation

/// Represents a Euclidean rhythm pattern configuration.
struct EuclideanPattern: Codable, Equatable {
    /// Number of steps in the pattern (1-16).
    var steps: Int

    /// Number of pulses distributed across steps (0-steps).
    var pulses: Int

    /// Rotation offset (0 to steps-1).
    var rotation: Int

    /// Time division for each step.
    var division: Division

    /// Computed pulse positions using Bjorklund's algorithm with rotation applied.
    var pulsePositions: [Int] {
        EuclideanEngine.pattern(steps: steps, pulses: pulses, rotation: rotation)
    }

    static var `default`: EuclideanPattern {
        EuclideanPattern(steps: 8, pulses: 3, rotation: 0, division: .eighth)
    }
}
