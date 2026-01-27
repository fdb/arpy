import XCTest
@testable import Arpy

final class SequencerStateTests: XCTestCase {

    func testDefaultStateHas4Tracks() {
        let state = SequencerState.default
        XCTAssertEqual(state.tracks.count, 4)
        XCTAssertEqual(state.tracks.map(\.id), [1, 2, 3, 4])
    }

    func testTrackMidiChannelMatchesId() {
        let state = SequencerState.default
        for track in state.tracks {
            XCTAssertEqual(track.midiChannel, track.id)
        }
    }

    func testStateIsEncodable() throws {
        let state = SequencerState.default
        let data = try JSONEncoder().encode(state)
        XCTAssertFalse(data.isEmpty)
    }

    func testStateIsDecodable() throws {
        let state = SequencerState.default
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SequencerState.self, from: data)
        XCTAssertEqual(state, decoded)
    }

    func testDefaultTempo() {
        XCTAssertEqual(SequencerState.default.tempo, 120.0)
    }

    func testDefaultNotPlaying() {
        XCTAssertFalse(SequencerState.default.isPlaying)
    }

    func testDefaultInternalClock() {
        XCTAssertEqual(SequencerState.default.clockSource, .internal)
    }

    func testDefaultTrackPattern() {
        let track = Track.defaultTrack(id: 1)
        XCTAssertEqual(track.pattern.steps, 8)
        XCTAssertEqual(track.pattern.pulses, 3)
        XCTAssertEqual(track.pattern.rotation, 0)
        XCTAssertEqual(track.pattern.division, .eighth)
    }
}
