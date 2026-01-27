import Foundation
import CoreMIDI

/// Service for receiving input from the AKAI LPD8 MKII controller.
class MIDIControllerService: ObservableObject {
    @Published var isConnected = false

    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0

    /// Callback for pad presses (note number, velocity).
    var onPadPress: ((Int, Int) -> Void)?
    /// Callback for pad releases (note number).
    var onPadRelease: ((Int) -> Void)?
    /// Callback for knob changes (CC number, value 0-127).
    var onKnobChange: ((Int, Int) -> Void)?

    // LPD8 MKII Default Program 1 mapping
    private static let padNoteRange = 36...43  // Notes 36-43 for pads 1-8
    private static let knobCCRange = 1...8     // CC 1-8 for knobs 1-8

    func setup() throws {
        var status = MIDIClientCreateWithBlock("Arpy Controller" as CFString, &client) { [weak self] notification in
            if notification.pointee.messageID == .msgSetupChanged {
                DispatchQueue.main.async {
                    self?.reconnect()
                }
            }
        }
        guard status == noErr else {
            throw MIDIServiceError.clientCreationFailed(status)
        }

        status = MIDIInputPortCreateWithProtocol(
            client,
            "Arpy Controller Input" as CFString,
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
        let count = MIDIGetNumberOfSources()
        var found = false
        for i in 0..<count {
            let source = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)

            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
            if let n = name?.takeRetainedValue() as? String,
               n.lowercased().contains("lpd8") {
                found = true
            }
        }
        DispatchQueue.main.async {
            self.isConnected = found
        }
    }

    private func reconnect() {
        connectAllSources()
    }

    private func handleEventList(_ eventListPtr: UnsafePointer<MIDIEventList>) {
        let eventList = eventListPtr.pointee
        var packet = eventList.packet

        for _ in 0..<eventList.numPackets {
            let word = packet.words.0
            let statusByte = UInt8((word >> 16) & 0xFF)
            let data1 = Int((word >> 8) & 0x7F)
            let data2 = Int(word & 0x7F)

            let messageType = statusByte & 0xF0

            switch messageType {
            case 0x90 where data2 > 0: // Note On
                if Self.padNoteRange.contains(data1) {
                    let padId = data1 - 36 + 1  // Convert to 1-8
                    DispatchQueue.main.async { self.onPadPress?(padId, data2) }
                }
            case 0x90, 0x80: // Note Off
                if Self.padNoteRange.contains(data1) {
                    let padId = data1 - 36 + 1
                    DispatchQueue.main.async { self.onPadRelease?(padId) }
                }
            case 0xB0: // CC
                if Self.knobCCRange.contains(data1) {
                    DispatchQueue.main.async { self.onKnobChange?(data1, data2) }
                }
            default:
                break
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
        isConnected = false
    }

    deinit {
        teardown()
    }
}
