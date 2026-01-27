import XCTest
@testable import Arpy

final class ClockEngineTests: XCTestCase {

    func testTickIntervalAt120BPM() {
        // 120 BPM = 2 beats/sec = 48 ticks/sec at PPQ 24
        // Interval = 1/48 sec ≈ 20,833,333 ns
        let interval = ClockEngine.tickInterval(bpm: 120, ppq: 24)
        XCTAssertEqual(interval, 20_833_333, accuracy: 1000)
    }

    func testTickIntervalAt60BPM() {
        // 60 BPM = 1 beat/sec = 24 ticks/sec
        // Interval = 1/24 sec ≈ 41,666,667 ns
        let interval = ClockEngine.tickInterval(bpm: 60, ppq: 24)
        XCTAssertEqual(interval, 41_666_666, accuracy: 1000)
    }

    func testTickIntervalAt240BPM() {
        // 240 BPM = 4 beats/sec = 96 ticks/sec
        // Interval = 1/96 sec ≈ 10,416,667 ns
        let interval = ClockEngine.tickInterval(bpm: 240, ppq: 24)
        XCTAssertEqual(interval, 10_416_666, accuracy: 1000)
    }

    func testDivisionTicksPerStep() {
        XCTAssertEqual(Division.quarter.ticksPerStep, 24)
        XCTAssertEqual(Division.eighth.ticksPerStep, 12)
        XCTAssertEqual(Division.sixteenth.ticksPerStep, 6)
        XCTAssertEqual(Division.whole.ticksPerStep, 96)
        XCTAssertEqual(Division.half.ticksPerStep, 48)
        XCTAssertEqual(Division.thirtySecond.ticksPerStep, 3)
    }
}
