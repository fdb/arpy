import XCTest
@testable import Arpy

final class MIDIEngineTests: XCTestCase {

    func testNoteOnMessageBytes() {
        let msg = MIDIMessage.noteOn(channel: 1, note: 60, velocity: 100)
        XCTAssertEqual(msg.bytes, [0x90, 60, 100])
    }

    func testNoteOffMessageBytes() {
        let msg = MIDIMessage.noteOff(channel: 1, note: 60)
        XCTAssertEqual(msg.bytes, [0x80, 60, 0])
    }

    func testChannelEncoding() {
        // Channel 1 = 0x90, Channel 2 = 0x91, etc.
        for ch in 1...4 {
            let msg = MIDIMessage.noteOn(channel: ch, note: 60, velocity: 100)
            XCTAssertEqual(msg.bytes[0], UInt8(0x90 + ch - 1))
        }
    }

    func testClockMessageBytes() {
        XCTAssertEqual(MIDIMessage.clock.bytes, [0xF8])
    }

    func testStartMessageBytes() {
        XCTAssertEqual(MIDIMessage.start.bytes, [0xFA])
    }

    func testStopMessageBytes() {
        XCTAssertEqual(MIDIMessage.stop.bytes, [0xFC])
    }

    func testContinueMessageBytes() {
        XCTAssertEqual(MIDIMessage.continue.bytes, [0xFB])
    }

    func testScaleQuantization() {
        // C major scale: C D E F G A B
        let quantized = ScaleEngine.quantizeToScale(midiNote: 61, scale: .major, root: .C)
        // 61 = C#, should quantize to C(60) or D(62)
        XCTAssertTrue(quantized == 60 || quantized == 62)
    }

    func testTransposition() {
        let track = Track.defaultTrack(id: 1)
        let msg = MIDIEngine.noteForStep(track: track, step: 0, pulsePositions: [0])
        XCTAssertNotNil(msg)
        if case .noteOn(_, let note, _) = msg! {
            XCTAssertEqual(note, 60) // C4 with no transpose
        }
    }

    func testMutedTrackReturnsNil() {
        var track = Track.defaultTrack(id: 1)
        track.isMuted = true
        let msg = MIDIEngine.noteForStep(track: track, step: 0, pulsePositions: [0])
        XCTAssertNil(msg)
    }

    func testNonPulseStepReturnsNil() {
        let track = Track.defaultTrack(id: 1)
        let msg = MIDIEngine.noteForStep(track: track, step: 1, pulsePositions: [0])
        XCTAssertNil(msg)
    }
}
