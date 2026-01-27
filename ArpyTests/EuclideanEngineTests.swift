import XCTest
@testable import Arpy

final class EuclideanEngineTests: XCTestCase {

    func testE8_3() {
        // Cuban tresillo: X..X..X.
        let result = EuclideanEngine.pattern(steps: 8, pulses: 3, rotation: 0)
        XCTAssertEqual(result, [0, 3, 6])
    }

    func testE8_5() {
        // Cuban cinquillo: X.XX.XX.
        let result = EuclideanEngine.pattern(steps: 8, pulses: 5, rotation: 0)
        XCTAssertEqual(result, [0, 2, 3, 5, 6])
    }

    func testE16_4() {
        // X...X...X...X...
        let result = EuclideanEngine.pattern(steps: 16, pulses: 4, rotation: 0)
        XCTAssertEqual(result, [0, 4, 8, 12])
    }

    func testE16_7() {
        let result = EuclideanEngine.pattern(steps: 16, pulses: 7, rotation: 0)
        // Bjorklund's algorithm distributes 7 pulses in 16 steps
        XCTAssertEqual(result.count, 7)
        // Verify even distribution: gaps should be 2 or 3
        let sorted = result.sorted()
        for i in 0..<sorted.count {
            let next = (i + 1) % sorted.count
            let gap = next == 0
                ? (16 - sorted[i] + sorted[0])
                : (sorted[next] - sorted[i])
            XCTAssertTrue(gap == 2 || gap == 3, "Gap \(gap) at index \(i)")
        }
    }

    func testRotation() {
        // Base: [0, 3, 6] → rotated by 1 should shift pattern
        let rotated = EuclideanEngine.pattern(steps: 8, pulses: 3, rotation: 1)
        XCTAssertEqual(rotated.sorted(), [2, 5, 7])
    }

    func testZeroPulses() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 0, rotation: 0), [])
    }

    func testAllPulses() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 8, rotation: 0), [0, 1, 2, 3, 4, 5, 6, 7])
    }

    func testSingleStep() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 1, pulses: 1, rotation: 0), [0])
    }

    func testSinglePulse() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 1, rotation: 0), [0])
    }

    func testE4_1() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 4, pulses: 1, rotation: 0), [0])
    }

    func testE4_2() {
        XCTAssertEqual(EuclideanEngine.pattern(steps: 4, pulses: 2, rotation: 0), [0, 2])
    }

    func testE4_3() {
        let result = EuclideanEngine.pattern(steps: 4, pulses: 3, rotation: 0)
        XCTAssertEqual(result.count, 3)
        // 3 pulses in 4 steps: gaps should be 1 or 2
        let sorted = result.sorted()
        for i in 0..<sorted.count {
            let next = (i + 1) % sorted.count
            let gap = next == 0
                ? (4 - sorted[i] + sorted[0])
                : (sorted[next] - sorted[i])
            XCTAssertTrue(gap == 1 || gap == 2, "Gap \(gap) at index \(i)")
        }
    }
}
