import Foundation
import SwiftUI

/// Main view model bridging UI and functional core.
@MainActor
class SequencerViewModel: ObservableObject {
    @Published var state: SequencerState
    @Published var knobValues: [Int: Double] = [:]

    private let midiOutput = MIDIOutputService()
    private let midiInput = MIDIInputService()
    private let clock = ClockEngine()

    /// Tracks active notes for note-off scheduling.
    private var activeNotes: [(channel: Int, note: Int, offTick: Int)] = []

    /// Tap tempo timestamps.
    private var tapTimes: [Date] = []

    /// Per-track tick accumulators for step advancement.
    private var trackTickAccumulators: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0]

    init() {
        state = SequencerState.default
        initializeKnobValues()
        setupClock()
        setupMIDI()
    }

    // MARK: - Setup

    private func initializeKnobValues() {
        // Normal mode knobs: map current track values to 0.0-1.0
        for i in 1...8 {
            knobValues[i] = 0.5
        }
        syncKnobsFromState()
    }

    private func setupClock() {
        clock.onTick = { [weak self] tick in
            Task { @MainActor in
                self?.handleTick(tick)
            }
        }
    }

    private func setupMIDI() {
        do {
            try midiOutput.setup()
        } catch {
            print("MIDI output setup failed: \(error)")
        }

        do {
            try midiInput.setup()
        } catch {
            print("MIDI input setup failed: \(error)")
        }

        midiInput.onMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.handleMIDIInput(message)
            }
        }
    }

    // MARK: - MIDI Input Handling

    // LPD8 MKII Default Program 1 mapping
    private static let padNoteRange = 36...43  // Notes 36-43 for pads 1-8
    private static let knobCCRange = 70...77   // CC 70-77 for knobs 1-8

    private func handleMIDIInput(_ message: MIDIMessage) {
        switch message {
        case .noteOn(let channel, let note, let velocity) where channel == 10 && Self.padNoteRange.contains(note):
            let padId = note - 36 + 1
            padPressed(padId)
        case .noteOff(let channel, let note) where channel == 10 && Self.padNoteRange.contains(note):
            let padId = note - 36 + 1
            padReleased(padId)
        case .noteOn(let channel, let note, _) where channel == 10:
            // Note on with velocity 0 = note off
            if Self.padNoteRange.contains(note) {
                let padId = note - 36 + 1
                padReleased(padId)
            }
        case .controlChange(let channel, let cc, let value) where channel == 1 && Self.knobCCRange.contains(cc):
            let knobId = cc - 70 + 1
            let normalized = Double(value) / 127.0
            knobChanged(knobId, value: normalized)
        default:
            break
        }
    }

    // MARK: - Computed Properties

    var selectedTrack: Track {
        state.tracks.first { $0.id == state.selectedTrackId } ?? state.tracks[0]
    }

    var currentKnobLabels: [String] {
        if state.isMelodicShiftActive {
            return ["Pitch", "Scale", "Root", "Voicing", "Style", "Phrase", "Range", "—"]
        } else {
            return ["Steps", "Pulses", "Rotate", "Division", "Repeats", "Velocity", "Sustain", "Tempo"]
        }
    }

    var currentKnobDisplayValues: [String] {
        if state.isMelodicShiftActive {
            let m = selectedTrack.melodic
            return [
                "\(m.transpose)",
                m.scale.displayName,
                m.rootNote.displayName,
                "\(Int(m.voicingAmount * 100))%",
                m.voicingStyle.displayName,
                m.phraseShape.displayName,
                "\(m.phraseRange)",
                "—"
            ]
        } else {
            let t = selectedTrack
            return [
                "\(t.pattern.steps)",
                "\(t.pattern.pulses)",
                "\(t.pattern.rotation)",
                t.pattern.division.rawValue,
                "\(t.repeats)",
                "\(t.velocity)",
                "\(Int(t.sustain * 100))%",
                "\(Int(state.tempo)) BPM"
            ]
        }
    }

    // MARK: - Input Handlers

    func padPressed(_ padId: Int) {
        switch padId {
        case 1...4:
            state.selectedTrackId = padId
            syncKnobsFromState()
        case 5:
            togglePlayStop()
        case 6:
            tapTempo()
        case 7:
            toggleMute()
        case 8:
            state.isMelodicShiftActive = true
            syncKnobsFromState()
        default:
            break
        }
    }

    func padReleased(_ padId: Int) {
        if padId == 8 {
            state.isMelodicShiftActive = false
            syncKnobsFromState()
        }
    }

    func knobChanged(_ knobId: Int, value: Double) {
        knobValues[knobId] = value
        let trackIndex = state.tracks.firstIndex { $0.id == state.selectedTrackId }!

        if state.isMelodicShiftActive {
            applyMelodicKnob(knobId, value: value, trackIndex: trackIndex)
        } else {
            applyNormalKnob(knobId, value: value, trackIndex: trackIndex)
        }
    }

    // MARK: - Actions

    func togglePlayStop() {
        if state.isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func tapTempo() {
        let now = Date()
        tapTimes.append(now)
        if tapTimes.count > 4 { tapTimes.removeFirst() }
        guard tapTimes.count >= 2 else { return }

        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i - 1])
        }
        let avgInterval = totalInterval / Double(tapTimes.count - 1)
        let bpm = 60.0 / avgInterval
        let clamped = max(40.0, min(240.0, bpm))
        state.tempo = clamped
        if state.isPlaying {
            clock.updateTempo(bpm: clamped)
        }
        syncKnobsFromState()
    }

    func toggleMute() {
        if let index = state.tracks.firstIndex(where: { $0.id == state.selectedTrackId }) {
            state.tracks[index].isMuted.toggle()
        }
    }

    /// Send all-notes-off on all channels (panic).
    func panic() {
        for channel in 1...4 {
            for note in 0...127 {
                midiOutput.send(.noteOff(channel: channel, note: note))
            }
        }
        activeNotes.removeAll()
    }

    // MARK: - Playback

    private func startPlayback() {
        state.isPlaying = true
        for key in trackTickAccumulators.keys {
            trackTickAccumulators[key] = 0
        }
        state.playheadPositions = [1: 0, 2: 0, 3: 0, 4: 0]
        midiOutput.send(.start)
        clock.start(bpm: state.tempo)
    }

    private func stopPlayback() {
        clock.stop()
        state.isPlaying = false
        midiOutput.send(.stop)

        // Send note-off for all active notes
        for active in activeNotes {
            midiOutput.send(.noteOff(channel: active.channel, note: active.note))
        }
        activeNotes.removeAll()
    }

    private func handleTick(_ tick: Int) {
        // Send MIDI clock
        midiOutput.send(.clock)

        // Check for note-offs
        let expired = activeNotes.filter { $0.offTick <= tick }
        for note in expired {
            midiOutput.send(.noteOff(channel: note.channel, note: note.note))
        }
        activeNotes.removeAll { $0.offTick <= tick }

        // Advance each track
        for i in 0..<state.tracks.count {
            let track = state.tracks[i]
            let ticksPerStep = track.pattern.division.ticksPerStep

            trackTickAccumulators[track.id, default: 0] += 1

            if trackTickAccumulators[track.id, default: 0] >= ticksPerStep {
                trackTickAccumulators[track.id] = 0
                let currentStep = state.playheadPositions[track.id, default: 0]
                let nextStep = (currentStep + 1) % track.pattern.steps

                state.playheadPositions[track.id] = nextStep

                // Check if this step has a pulse
                let positions = track.pattern.pulsePositions
                if positions.contains(currentStep) && !track.isMuted {
                    triggerNote(track: track, step: currentStep, tick: tick)
                }
            }
        }
    }

    private func triggerNote(track: Track, step: Int, tick: Int) {
        let baseNote = 60 + track.melodic.rootNote.rawValue + track.melodic.transpose
        let midiNote = MIDIEngine.computeMIDINote(
            baseNote: baseNote,
            config: track.melodic,
            stepInPhrase: step,
            totalSteps: track.pattern.steps
        )

        let ticksPerStep = track.pattern.division.ticksPerStep
        let sustainTicks = max(1, Int(Double(ticksPerStep) * track.sustain))

        // Handle repeats
        let triggers = RepeatEngine.computeRepeats(
            pulseStep: step,
            repeatCount: track.repeats,
            division: track.pattern.division
        )

        for (index, trigger) in triggers.enumerated() {
            let offsetTicks = Int(trigger.offset * Double(ticksPerStep))
            let noteTick = tick + offsetTicks
            let repeatSustain = max(1, sustainTicks / (triggers.count))
            let offTick = noteTick + repeatSustain

            // For the first trigger, send immediately
            if index == 0 {
                midiOutput.send(.noteOn(
                    channel: track.midiChannel,
                    note: midiNote,
                    velocity: track.velocity
                ))
                activeNotes.append((
                    channel: track.midiChannel,
                    note: midiNote,
                    offTick: offTick
                ))
            } else {
                // Schedule future triggers via activeNotes tracking
                // For simplicity, send immediately with adjusted timing
                let delayNs = ClockEngine.tickInterval(bpm: state.tempo, ppq: clock.ppq) * UInt64(offsetTicks)
                let channel = track.midiChannel
                let vel = track.velocity

                DispatchQueue.global(qos: .userInteractive).asyncAfter(
                    deadline: .now() + .nanoseconds(Int(delayNs))
                ) { [weak self] in
                    self?.midiOutput.send(.noteOn(channel: channel, note: midiNote, velocity: vel))
                    Task { @MainActor in
                        self?.activeNotes.append((channel: channel, note: midiNote, offTick: offTick))
                    }
                }
            }
        }
    }

    // MARK: - Knob Mapping

    private func applyNormalKnob(_ knobId: Int, value: Double, trackIndex: Int) {
        switch knobId {
        case 1: // Steps 1-16
            state.tracks[trackIndex].pattern.steps = Int(round(value * 15.0)) + 1
            let steps = state.tracks[trackIndex].pattern.steps
            state.tracks[trackIndex].pattern.pulses = min(state.tracks[trackIndex].pattern.pulses, steps)
            state.tracks[trackIndex].pattern.rotation = min(state.tracks[trackIndex].pattern.rotation, steps - 1)
        case 2: // Pulses 0-steps
            let steps = state.tracks[trackIndex].pattern.steps
            state.tracks[trackIndex].pattern.pulses = Int(round(value * Double(steps)))
        case 3: // Rotate 0 to steps-1
            let steps = state.tracks[trackIndex].pattern.steps
            state.tracks[trackIndex].pattern.rotation = Int(round(value * Double(steps - 1)))
        case 4: // Division
            let divisions = Division.allCases
            let index = Int(round(value * Double(divisions.count - 1)))
            state.tracks[trackIndex].pattern.division = divisions[index]
        case 5: // Repeats 0-8
            state.tracks[trackIndex].repeats = Int(round(value * 8.0))
        case 6: // Velocity 1-127
            state.tracks[trackIndex].velocity = max(1, Int(round(value * 127.0)))
        case 7: // Sustain 0-100%
            state.tracks[trackIndex].sustain = value
        case 8: // Tempo 40-240
            state.tempo = 40.0 + value * 200.0
            if state.isPlaying {
                clock.updateTempo(bpm: state.tempo)
            }
        default:
            break
        }
    }

    private func applyMelodicKnob(_ knobId: Int, value: Double, trackIndex: Int) {
        switch knobId {
        case 1: // Transpose -24 to +24
            state.tracks[trackIndex].melodic.transpose = Int(round(value * 48.0)) - 24
        case 2: // Scale
            let scales = Scale.allCases
            let index = Int(round(value * Double(scales.count - 1)))
            state.tracks[trackIndex].melodic.scale = scales[index]
        case 3: // Root Note
            let notes = Note.allCases
            let index = Int(round(value * Double(notes.count - 1)))
            state.tracks[trackIndex].melodic.rootNote = notes[index]
        case 4: // Voicing Amount 0-100%
            state.tracks[trackIndex].melodic.voicingAmount = value
        case 5: // Style
            let styles = VoicingStyle.allCases
            let index = Int(round(value * Double(styles.count - 1)))
            state.tracks[trackIndex].melodic.voicingStyle = styles[index]
        case 6: // Phrase
            let shapes = PhraseShape.allCases
            let index = Int(round(value * Double(shapes.count - 1)))
            state.tracks[trackIndex].melodic.phraseShape = shapes[index]
        case 7: // Range -3 to +3
            state.tracks[trackIndex].melodic.phraseRange = Int(round(value * 6.0)) - 3
        default:
            break
        }
    }

    private func syncKnobsFromState() {
        let track = selectedTrack
        if state.isMelodicShiftActive {
            knobValues[1] = Double(track.melodic.transpose + 24) / 48.0
            knobValues[2] = Double(Scale.allCases.firstIndex(of: track.melodic.scale) ?? 0) / Double(Scale.allCases.count - 1)
            knobValues[3] = Double(track.melodic.rootNote.rawValue) / 11.0
            knobValues[4] = track.melodic.voicingAmount
            knobValues[5] = Double(VoicingStyle.allCases.firstIndex(of: track.melodic.voicingStyle) ?? 0) / Double(VoicingStyle.allCases.count - 1)
            knobValues[6] = Double(PhraseShape.allCases.firstIndex(of: track.melodic.phraseShape) ?? 0) / Double(PhraseShape.allCases.count - 1)
            knobValues[7] = Double(track.melodic.phraseRange + 3) / 6.0
            knobValues[8] = 0.5
        } else {
            knobValues[1] = Double(track.pattern.steps - 1) / 15.0
            knobValues[2] = track.pattern.steps > 0 ? Double(track.pattern.pulses) / Double(track.pattern.steps) : 0
            knobValues[3] = track.pattern.steps > 1 ? Double(track.pattern.rotation) / Double(track.pattern.steps - 1) : 0
            knobValues[4] = Double(Division.allCases.firstIndex(of: track.pattern.division) ?? 0) / Double(Division.allCases.count - 1)
            knobValues[5] = Double(track.repeats) / 8.0
            knobValues[6] = Double(track.velocity) / 127.0
            knobValues[7] = track.sustain
            knobValues[8] = (state.tempo - 40.0) / 200.0
        }
    }
}
