import Foundation

/// Pure functions for computing note repeats (ratchets).
enum RepeatEngine {

    /// Compute all trigger times for a pulse with repeats.
    /// - Parameters:
    ///   - pulseStep: The step index where the initial pulse occurs.
    ///   - repeatCount: Number of additional repeats (0 = no repeats, just the original).
    ///   - division: The track's time division.
    /// - Returns: Array of (step, fractional offset within step) tuples.
    static func computeRepeats(
        pulseStep: Int,
        repeatCount: Int,
        division: Division
    ) -> [(step: Int, offset: Double)] {
        guard repeatCount >= 0 else { return [(step: pulseStep, offset: 0.0)] }

        let totalTriggers = repeatCount + 1
        var triggers: [(step: Int, offset: Double)] = []

        for i in 0..<totalTriggers {
            let offset = Double(i) / Double(totalTriggers)
            triggers.append((step: pulseStep, offset: offset))
        }

        return triggers
    }
}
