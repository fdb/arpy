import Foundation
import CoreMIDI
import os

private let midiLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Arpy", category: "MIDI")

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
    private static let knobCCRange = 70...77   // CC 70-77 for knobs 1-8

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
        midiLog.info("Scanning MIDI sources (\(count) available)")
        for i in 0..<count {
            let source = MIDIGetSource(i)
            let status = MIDIPortConnectSource(inputPort, source, nil)

            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
            let sourceName = (name?.takeRetainedValue() as? String) ?? "Unknown"

            if status == noErr {
                midiLog.info("Connected to MIDI source: \(sourceName)")
            } else {
                midiLog.error("Failed to connect to MIDI source: \(sourceName) (status \(status))")
            }

            if sourceName.lowercased().contains("lpd8") {
                found = true
                midiLog.info("Found LPD8 device: \(sourceName)")
            }
        }
        let wasConnected = isConnected
        DispatchQueue.main.async {
            self.isConnected = found
        }
        if found != wasConnected {
            midiLog.info("LPD8 \(found ? "connected" : "disconnected")")
        }
    }

    private func reconnect() {
        midiLog.info("MIDI setup changed, reconnecting")
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
            let channel = statusByte & 0x0F

            let ch = Int(channel) + 1  // 1-based for logging

            switch (messageType, channel) {
            case (0x90, 9) where data2 > 0: // Note On, channel 10
                if Self.padNoteRange.contains(data1) {
                    let padId = data1 - 36 + 1
                    midiLog.debug("✓ Pad \(padId) ON  (note \(data1), vel \(data2), ch \(ch))")
                    DispatchQueue.main.async { self.onPadPress?(padId, data2) }
                } else {
                    midiLog.debug("✗ Ignored Note On (note \(data1), vel \(data2), ch \(ch)) — note not in pad range 36-43")
                }
            case (0x90, 9), (0x80, 9): // Note Off, channel 10
                if Self.padNoteRange.contains(data1) {
                    let padId = data1 - 36 + 1
                    midiLog.debug("✓ Pad \(padId) OFF (note \(data1), ch \(ch))")
                    DispatchQueue.main.async { self.onPadRelease?(padId) }
                } else {
                    midiLog.debug("✗ Ignored Note Off (note \(data1), ch \(ch)) — note not in pad range 36-43")
                }
            case (0xB0, 0): // CC, channel 1
                if Self.knobCCRange.contains(data1) {
                    let knobId = data1 - 70 + 1
                    midiLog.debug("✓ Knob \(knobId) = \(data2) (CC \(data1), ch \(ch))")
                    DispatchQueue.main.async { self.onKnobChange?(knobId, data2) }
                } else {
                    midiLog.debug("✗ Ignored CC (CC \(data1), val \(data2), ch \(ch)) — CC not in knob range 70-77")
                }
            case (0x90, _), (0x80, _):
                midiLog.debug("✗ Ignored Note (note \(data1), vel \(data2), ch \(ch)) — wrong channel (expected 10)")
            case (0xB0, _):
                midiLog.debug("✗ Ignored CC (CC \(data1), val \(data2), ch \(ch)) — wrong channel (expected 1)")
            default:
                midiLog.debug("✗ Ignored MIDI (status 0x\(String(statusByte, radix: 16)), d1 \(data1), d2 \(data2))")
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
