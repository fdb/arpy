import XCTest
@testable import Arpy

final class PersistenceTests: XCTestCase {

    private let controller = PersistenceController()

    override func tearDown() {
        controller.reset()
        super.tearDown()
    }

    func testSaveAndLoad() throws {
        var state = SequencerState.default
        state.tempo = 140.0
        state.tracks[0].pattern.steps = 12

        try controller.save(state)
        let loaded = try controller.load()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.tempo, 140.0)
        XCTAssertEqual(loaded?.tracks[0].pattern.steps, 12)
    }

    func testLoadMissingFileReturnsNil() throws {
        controller.reset()
        let loaded = try controller.load()
        XCTAssertNil(loaded)
    }

    func testLoadOrDefaultWithMissingFile() {
        controller.reset()
        let state = controller.loadOrDefault()
        XCTAssertEqual(state.tempo, 120.0)
        XCTAssertEqual(state.tracks.count, 4)
    }
}
