import Foundation

/// Pure functions for computing Euclidean rhythm patterns using Bjorklund's algorithm.
enum EuclideanEngine {

    /// Compute pulse positions using Bjorklund's algorithm.
    /// Distributes `pulses` as evenly as possible across `steps`.
    /// - Returns: Sorted array of step indices (0-based) where pulses occur.
    static func computePulsePositions(steps: Int, pulses: Int) -> [Int] {
        guard steps > 0 else { return [] }
        let k = min(max(pulses, 0), steps)
        guard k > 0 else { return [] }
        guard k < steps else { return Array(0..<steps) }

        // Bjorklund's algorithm using the Euclidean method
        var pattern = [Bool](repeating: false, count: steps)

        // Build groups
        var groups: [[Bool]] = Array(repeating: [true], count: k) +
                                Array(repeating: [false], count: steps - k)

        while true {
            let lastType = groups.last!
            // Find how many trailing groups match the last type
            var tailCount = 0
            for i in stride(from: groups.count - 1, through: 0, by: -1) {
                if groups[i] == lastType {
                    tailCount += 1
                } else {
                    break
                }
            }

            let headCount = groups.count - tailCount

            if tailCount <= 1 || headCount == 0 { break }

            let mergeCount = min(headCount, tailCount)
            var newGroups: [[Bool]] = []

            for i in 0..<mergeCount {
                newGroups.append(groups[i] + groups[headCount + i])
            }

            // Remaining head groups
            for i in mergeCount..<headCount {
                newGroups.append(groups[i])
            }

            // Remaining tail groups
            for i in (headCount + mergeCount)..<groups.count {
                newGroups.append(groups[i])
            }

            groups = newGroups
        }

        // Flatten groups into pattern
        var idx = 0
        for group in groups {
            for bit in group {
                if idx < steps {
                    pattern[idx] = bit
                    idx += 1
                }
            }
        }

        return pattern.enumerated().compactMap { $0.element ? $0.offset : nil }
    }

    /// Rotate pulse positions by shifting the start point.
    /// - Returns: Sorted array of rotated step indices.
    static func rotate(_ positions: [Int], by offset: Int, totalSteps: Int) -> [Int] {
        guard totalSteps > 0, !positions.isEmpty else { return positions }
        let effectiveOffset = ((offset % totalSteps) + totalSteps) % totalSteps
        guard effectiveOffset > 0 else { return positions }
        return positions.map { ($0 - effectiveOffset + totalSteps) % totalSteps }.sorted()
    }

    /// Compute full pattern with rotation applied.
    /// - Returns: Sorted array of step indices where pulses occur.
    static func pattern(steps: Int, pulses: Int, rotation: Int) -> [Int] {
        let base = computePulsePositions(steps: steps, pulses: pulses)
        return rotate(base, by: rotation, totalSteps: steps)
    }
}
