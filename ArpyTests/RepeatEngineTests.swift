import XCTest
@testable import Arpy

final class RepeatEngineTests: XCTestCase {

    func testNoRepeats() {
        let result = RepeatEngine.computeRepeats(pulseStep: 0, repeatCount: 0, division: .eighth)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].step, 0)
        XCTAssertEqual(result[0].offset, 0.0, accuracy: 0.001)
    }

    func testOneRepeat() {
        let result = RepeatEngine.computeRepeats(pulseStep: 0, repeatCount: 1, division: .eighth)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].offset, 0.0, accuracy: 0.001)
        XCTAssertEqual(result[1].offset, 0.5, accuracy: 0.001)
    }

    func testThreeRepeats() {
        let result = RepeatEngine.computeRepeats(pulseStep: 0, repeatCount: 3, division: .eighth)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].offset, 0.0, accuracy: 0.001)
        XCTAssertEqual(result[1].offset, 0.25, accuracy: 0.001)
        XCTAssertEqual(result[2].offset, 0.5, accuracy: 0.001)
        XCTAssertEqual(result[3].offset, 0.75, accuracy: 0.001)
    }
}
