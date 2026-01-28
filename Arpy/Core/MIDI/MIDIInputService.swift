import Foundation
import CoreMIDI

/// Service for receiving MIDI input (external clock, controller).
class MIDIInputService: ObservableObject {
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0

    @Published var receivedClock = false
    @Published var receivedStart = false
    @Published var receivedStop = false

    /// Callback for received MIDI messages.
    var onMessage: ((MIDIMessage) -> Void)?

    /// Set up CoreMIDI input.
    func setup() throws {
        var status = MIDIClientCreateWithBlock("Arpy Input" as CFString, &client) { [weak self] notification in
            if notification.pointee.messageID == .msgSetupChanged {
                self?.reconnectSources()
            }
        }
        guard status == noErr else {
            throw MIDIServiceError.clientCreationFailed(status)
        }

        status = MIDIInputPortCreateWithProtocol(
            client,
            "Arpy Input Port" as CFString,
            ._1_0,
            &inputPort
        ) { [weak self] eventList, _ in
            self?.handleEventList(eventList)
        }
        guard status == noErr else {
            throw MIDIServiceError.portCreationFailed(status)
        }

        connectAllSources()
    }

    private func connectAllSources() {
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)
        }
    }

    private func reconnectSources() {
        connectAllSources()
    }

    private func handleEventList(_ eventListPtr: UnsafePointer<MIDIEventList>) {
        let eventList = eventListPtr.pointee
        var packet = eventList.packet

        for _ in 0..<eventList.numPackets {
            let word = packet.words.0
            let statusByte = UInt8((word >> 16) & 0xFF)

            switch statusByte {
            case 0xF8:
                DispatchQueue.main.async { self.receivedClock = true }
                onMessage?(.clock)
            case 0xFA:
                DispatchQueue.main.async { self.receivedStart = true }
                onMessage?(.start)
            case 0xFC:
                DispatchQueue.main.async { self.receivedStop = true }
                onMessage?(.stop)
            case 0xFB:
                onMessage?(.continue)
            default:
                let messageType = statusByte & 0xF0
                let channel = Int(statusByte & 0x0F) + 1
                let data1 = Int((word >> 8) & 0x7F)
                let data2 = Int(word & 0x7F)

                switch messageType {
                case 0x90 where data2 > 0:
                    onMessage?(.noteOn(channel: channel, note: data1, velocity: data2))
                case 0x90, 0x80:
                    onMessage?(.noteOff(channel: channel, note: data1))
                case 0xB0:
                    onMessage?(.controlChange(channel: channel, cc: data1, value: data2))
                default:
                    break
                }
            }

            packet = MIDIEventPacketNext(&packet).pointee
        }
    }

    func teardown() {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
            inputPort = 0
        }
        if client != 0 {
            MIDIClientDispose(client)
            client = 0
        }
    }

    deinit {
        teardown()
    }
}
