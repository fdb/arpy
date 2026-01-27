import Foundation

/// Represents a MIDI message with byte-level encoding.
enum MIDIMessage: Equatable {
    case noteOn(channel: Int, note: Int, velocity: Int)
    case noteOff(channel: Int, note: Int)
    case clock
    case start
    case stop
    case `continue`

    /// Raw MIDI bytes for this message.
    var bytes: [UInt8] {
        switch self {
        case .noteOn(let channel, let note, let velocity):
            return [
                UInt8(0x90 | ((channel - 1) & 0x0F)),
                UInt8(note & 0x7F),
                UInt8(velocity & 0x7F)
            ]
        case .noteOff(let channel, let note):
            return [
                UInt8(0x80 | ((channel - 1) & 0x0F)),
                UInt8(note & 0x7F),
                0
            ]
        case .clock:    return [0xF8]
        case .start:    return [0xFA]
        case .stop:     return [0xFC]
        case .continue: return [0xFB]
        }
    }
}
