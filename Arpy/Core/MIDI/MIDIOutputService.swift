import Foundation
import CoreMIDI

/// Service for sending MIDI messages via a virtual MIDI source.
class MIDIOutputService: ObservableObject {
    private var client: MIDIClientRef = 0
    private var outputPort: MIDIPortRef = 0
    private var virtualSource: MIDIEndpointRef = 0

    @Published private(set) var isSetup = false

    /// Set up CoreMIDI client and virtual source.
    func setup() throws {
        var status = MIDIClientCreateWithBlock("Arpy" as CFString, &client) { _ in }
        guard status == noErr else {
            throw MIDIServiceError.clientCreationFailed(status)
        }

        status = MIDISourceCreateWithProtocol(
            client,
            "Arpy Sequencer" as CFString,
            ._1_0,
            &virtualSource
        )
        guard status == noErr else {
            throw MIDIServiceError.sourceCreationFailed(status)
        }

        isSetup = true
    }

    /// Send a MIDI message through the virtual source.
    func send(_ message: MIDIMessage) {
        guard isSetup else { return }

        let bytes = message.bytes
        var eventList = MIDIEventList()
        let packet = MIDIEventListInit(&eventList, ._1_0)

        let words: [UInt32]
        switch bytes.count {
        case 1:
            words = [UInt32(bytes[0]) << 16 | 0x10_00_0000]
        case 2:
            words = [(UInt32(bytes[0]) << 8 | UInt32(bytes[1])) << 8 | 0x20_00_0000]
        case 3:
            words = [UInt32(0x20_00_0000) | UInt32(bytes[0]) << 16 | UInt32(bytes[1]) << 8 | UInt32(bytes[2])]
        default:
            return
        }

        _ = words.withUnsafeBufferPointer { ptr in
            MIDIEventListAdd(&eventList, 1024, packet, 0, ptr.count, ptr.baseAddress!)
        }

        MIDIReceivedEventList(virtualSource, &eventList)
    }

    /// Tear down MIDI resources.
    func teardown() {
        if virtualSource != 0 {
            MIDIEndpointDispose(virtualSource)
            virtualSource = 0
        }
        if client != 0 {
            MIDIClientDispose(client)
            client = 0
        }
        isSetup = false
    }

    deinit {
        teardown()
    }
}

enum MIDIServiceError: Error {
    case clientCreationFailed(OSStatus)
    case sourceCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
}
