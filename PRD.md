# Arpy Euclidean Sequencer PRD

> Native macOS Algorithmic Sequencer | Torso T-1 Inspired | AKAI LPD8 MKII Control  
> **LIVE STAGE USE** — Stability is critical. This is not an MVP.

---

## Quick Reference

| Aspect | Specification |
|--------|---------------|
| Platform | macOS (native) |
| Framework | Swift + SwiftUI |
| MIDI Controller | AKAI LPD8 MKII (8 knobs, 8 velocity pads) |
| Tracks | 4 independent Euclidean tracks |
| Output | Virtual MIDI port → DAW (Ableton, etc.) |
| Audio | None (sequencer only, like T-1) |

---

## 1. Product Overview

### 1.1 Core Concept

Generates Euclidean rhythms: distributes N pulses across M steps as evenly as possible.

```
8 steps, 3 pulses → [X . . X . . X .]
16 steps, 5 pulses → [X . . X . . X . . X . . X . . .]
```

### 1.2 Hardware Mapping Summary

**Pads 1-4:** Track select (with visual feedback)  
**Pad 5:** Play/Stop  
**Pad 6:** Tap Tempo  
**Pad 7:** Mute selected track  
**Pad 8:** MELODIC SHIFT (hold for secondary knob functions)

**Knobs (Normal Mode):**
| Knob | Function | Range |
|------|----------|-------|
| 1 | Steps | 1-16 |
| 2 | Pulses | 0-16 |
| 3 | Rotate | 0-15 |
| 4 | Division | 1/1 to 1/32 |
| 5 | Repeats | 0-8 |
| 6 | Velocity | 1-127 |
| 7 | Sustain | 1-100% |
| 8 | Tempo | 40-240 BPM |

**Knobs (Melodic Shift - Hold Pad 8):**
| Knob | Function | Range |
|------|----------|-------|
| 1 | Pitch (transpose) | -24 to +24 semitones |
| 2 | Scale | Chromatic, Major, Minor, Pentatonic, etc. |
| 3 | Root Note | C to B |
| 4 | Voicing Amount | 0-100% |
| 5 | Style | Fixed, Ramp, Climb |
| 6 | Phrase | Cadence 1-4, Saw, Tri, Sine, Pulse |
| 7 | Range | -3 to +3 octaves |
| 8 | (Reserved) | — |

### 1.3 MIDI Output

- Track 1 → MIDI Channel 1
- Track 2 → MIDI Channel 2
- Track 3 → MIDI Channel 3
- Track 4 → MIDI Channel 4

Clock: Configurable as master (internal) or slave (external MIDI clock).

### 1.4 UI Requirements

1. **Controller Replica:** Visual representation of LPD8 (8 pads + 8 knobs)
2. **Step Sequencer Grid:** All 4 tracks visible, color-coded, rounded corners, subtle shadows
3. **Transport Bar:** Play/Stop, Tempo, Clock source indicator
4. **SF Symbols:** Use macOS system icons throughout

**Keyboard Shortcuts:**
- `Space` = Play/Stop
- `Shift` (hold) = Melodic Shift mode (mirrors Pad 8)
- `1-4` = Track select
- `M` = Mute selected track

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  (ControllerView, StepSequencerView, TransportBar, etc.)    │
└─────────────────────────┬───────────────────────────────────┘
                          │ Observes
┌─────────────────────────▼───────────────────────────────────┐
│                    SequencerViewModel                        │
│         (Bridges UI ↔ Functional Core, handles input)       │
└─────────────────────────┬───────────────────────────────────┘
                          │ Calls
┌─────────────────────────▼───────────────────────────────────┐
│                     Functional Core                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Euclidean   │  │   MIDI      │  │   Clock/Timing      │  │
│  │  Engine     │  │  Engine     │  │     Engine          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│         Pure functions, fully testable, no side effects     │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                      Data Model                              │
│    SequencerState, Track, EuclideanPattern, MelodicConfig   │
└─────────────────────────────────────────────────────────────┘
```

**Key Principle:** The functional core is pure—given inputs, it produces deterministic outputs. All state mutation happens in the ViewModel. This makes testing straightforward.

---

## 3. Development Phases

Each phase follows this structure:
1. **Explanation** — What and why
2. **Tasks** — Checkboxes for agent to mark progress  
3. **Verification** — How to confirm completion

**Agent Workflow ("Ralph Loop"):**
1. Find first unchecked task
2. Implement it
3. Run verification criteria
4. If passing, mark checkbox `[x]`
5. Commit with message referencing task
6. Repeat

---

## Phase 0: Project Setup

### Explanation
Create Xcode project with proper structure, dependencies, and build configuration.

### Tasks

- [ ] Create new Xcode project: "Arpy", macOS App, SwiftUI, Swift
- [ ] Set deployment target to macOS 13.0 (Ventura) minimum
- [ ] Create folder structure:
  ```
  Arpy/
  ├── App/
  │   └── Arpy.swift
  ├── Models/
  ├── Core/
  │   ├── Euclidean/
  │   ├── MIDI/
  │   └── Clock/
  ├── ViewModels/
  ├── Views/
  │   ├── Components/
  │   └── Screens/
  ├── Extensions/
  └── Resources/
  ```
- [ ] Add CoreMIDI framework to project
- [ ] Create ArpyTests target
- [ ] Create ArpyUITests target
- [ ] Add `.gitignore` for Xcode projects
- [ ] Initial commit with empty structure

### Verification

```bash
# Project builds without errors
xcodebuild -scheme Arpy -configuration Debug build

# Test targets exist and run (even if empty)
xcodebuild test -scheme ArpyTests -destination 'platform=macOS'
```

---

## Phase 1: Data Model

### Explanation
Define all data structures. These are the source of truth. Pure value types (structs) where possible. The model should be serializable for later persistence.

### Tasks

- [ ] Create `Division.swift` — enum for time divisions
  ```swift
  enum Division: String, Codable, CaseIterable {
      case whole = "1/1"
      case half = "1/2"
      case quarter = "1/4"
      case eighth = "1/8"
      case sixteenth = "1/16"
      case thirtySecond = "1/32"
      
      var ticksPerStep: Int { /* PPQ-based calculation */ }
  }
  ```

- [ ] Create `Scale.swift` — enum with note intervals
  ```swift
  enum Scale: String, Codable, CaseIterable {
      case chromatic, major, minor, pentatonic, 
           hirajoshi, iwato, tetratonic
      
      var intervals: [Int] { /* semitone intervals from root */ }
  }
  ```

- [ ] Create `Note.swift` — represents root notes
  ```swift
  enum Note: Int, Codable, CaseIterable {
      case C = 0, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B
  }
  ```

- [ ] Create `VoicingStyle.swift`
  ```swift
  enum VoicingStyle: String, Codable, CaseIterable {
      case fixed, ramp, climb
  }
  ```

- [ ] Create `PhraseShape.swift`
  ```swift
  enum PhraseShape: String, Codable, CaseIterable {
      case cadence1, cadence2, cadence3, cadence4
      case saw, triangle, sine, pulse
  }
  ```

- [ ] Create `EuclideanPattern.swift`
  ```swift
  struct EuclideanPattern: Codable, Equatable {
      var steps: Int          // 1-16
      var pulses: Int         // 0-steps
      var rotation: Int       // 0 to steps-1
      var division: Division
      
      // Computed: array of step indices where pulses occur
      var pulsePositions: [Int] { get }
  }
  ```

- [ ] Create `MelodicConfig.swift`
  ```swift
  struct MelodicConfig: Codable, Equatable {
      var transpose: Int      // -24 to +24 semitones
      var scale: Scale
      var rootNote: Note
      var voicingAmount: Double   // 0.0-1.0
      var voicingStyle: VoicingStyle
      var phraseShape: PhraseShape
      var phraseRange: Int    // -3 to +3 octaves
  }
  ```

- [ ] Create `Track.swift`
  ```swift
  struct Track: Codable, Equatable, Identifiable {
      let id: Int             // 1-4
      var pattern: EuclideanPattern
      var melodic: MelodicConfig
      var velocity: Int       // 1-127
      var sustain: Double     // 0.0-1.0 (percentage of division)
      var repeats: Int        // 0-8
      var isMuted: Bool
      var midiChannel: Int    // Fixed: equals id
  }
  ```

- [ ] Create `ClockSource.swift`
  ```swift
  enum ClockSource: String, Codable {
      case `internal`
      case external
  }
  ```

- [ ] Create `SequencerState.swift` — root state object
  ```swift
  struct SequencerState: Codable, Equatable {
      var tracks: [Track]     // Always 4 tracks
      var tempo: Double       // 40-240 BPM
      var isPlaying: Bool
      var clockSource: ClockSource
      var selectedTrackId: Int
      var isMelodicShiftActive: Bool
      
      // Current playback position per track
      var playheadPositions: [Int: Int]  // trackId -> step index
      
      static var `default`: SequencerState { /* factory */ }
  }
  ```

- [ ] Create `SequencerStateTests.swift` — verify defaults and encoding
  ```swift
  func testDefaultStateHas4Tracks()
  func testStateIsEncodable()
  func testStateIsDecodable()
  func testTrackMidiChannelMatchesId()
  ```

### Verification

```bash
# All model tests pass
xcodebuild test -scheme Arpy -only-testing:ArpyTests/SequencerStateTests
```

- [ ] All model types compile without errors
- [ ] All model tests pass
- [ ] JSON encode/decode round-trips successfully

---

## Phase 2: Functional Core — Euclidean Engine

### Explanation
Pure functions that compute Euclidean patterns. No state, no side effects. Given parameters, returns pulse positions.

### Tasks

- [ ] Create `EuclideanEngine.swift`
  ```swift
  enum EuclideanEngine {
      /// Bjorklund's algorithm: distribute pulses evenly across steps
      /// - Returns: Array of step indices (0-based) where pulses occur
      static func computePulsePositions(steps: Int, pulses: Int) -> [Int]
      
      /// Apply rotation (shift start point)
      static func rotate(_ positions: [Int], by offset: Int, totalSteps: Int) -> [Int]
      
      /// Full computation with rotation applied
      static func pattern(steps: Int, pulses: Int, rotation: Int) -> [Int]
  }
  ```

- [ ] Implement Bjorklund's algorithm
  ```swift
  // The algorithm distributes pulses as evenly as possible
  // E.g., (8, 3) → indices [0, 3, 6] → pattern "X..X..X."
  ```

- [ ] Create `EuclideanEngineTests.swift`
  ```swift
  // Test known Euclidean patterns:
  func testE8_3() { // "X..X..X." 
      XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 3, rotation: 0), [0, 3, 6])
  }
  func testE8_5() { // "X.XX.XX."
      XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 5, rotation: 0), [0, 2, 3, 5, 6])
  }
  func testE16_4() { // "X...X...X...X..."
      XCTAssertEqual(EuclideanEngine.pattern(steps: 16, pulses: 4, rotation: 0), [0, 4, 8, 12])
  }
  func testE16_7() {
      XCTAssertEqual(EuclideanEngine.pattern(steps: 16, pulses: 7, rotation: 0), [0, 2, 4, 7, 9, 11, 14])
  }
  func testRotation() {
      // Rotation shifts the pattern start
      let base = EuclideanEngine.pattern(steps: 8, pulses: 3, rotation: 0) // [0,3,6]
      let rotated = EuclideanEngine.pattern(steps: 8, pulses: 3, rotation: 1) // [7,2,5]
      XCTAssertEqual(rotated, [2, 5, 7].sorted()) // Will wrap around
  }
  func testEdgeCases() {
      XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 0, rotation: 0), [])
      XCTAssertEqual(EuclideanEngine.pattern(steps: 8, pulses: 8, rotation: 0), [0,1,2,3,4,5,6,7])
      XCTAssertEqual(EuclideanEngine.pattern(steps: 1, pulses: 1, rotation: 0), [0])
  }
  ```

- [ ] Create `RepeatEngine.swift`
  ```swift
  enum RepeatEngine {
      /// Given a pulse position and repeat count, compute all trigger times
      /// Returns array of (stepIndex, subdivisionOffset) tuples
      static func computeRepeats(
          pulseStep: Int,
          repeatCount: Int,
          division: Division,
          repeatDivision: Division
      ) -> [(step: Int, offset: Double)]
  }
  ```

- [ ] Create `RepeatEngineTests.swift`

### Verification

```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/EuclideanEngineTests
```

- [ ] All Euclidean algorithm tests pass
- [ ] Known patterns verified against T-1 reference
- [ ] Edge cases (0 pulses, full pulses) handled

---

## Phase 3: Functional Core — MIDI Engine

### Explanation
Functions to convert sequencer state into MIDI messages. Still pure—takes state, returns messages.

### Tasks

- [ ] Create `MIDIMessage.swift`
  ```swift
  enum MIDIMessage: Equatable {
      case noteOn(channel: Int, note: Int, velocity: Int)
      case noteOff(channel: Int, note: Int)
      case clock          // 0xF8
      case start          // 0xFA  
      case stop           // 0xFC
      case continue_      // 0xFB
      
      var bytes: [UInt8] { get }
  }
  ```

- [ ] Create `MIDIEngine.swift`
  ```swift
  enum MIDIEngine {
      /// Convert track state + step index to MIDI note
      static func noteForStep(
          track: Track,
          step: Int,
          pulsePositions: [Int]
      ) -> MIDIMessage?
      
      /// Compute MIDI note number from melodic config
      static func computeMIDINote(
          baseNote: Int,
          config: MelodicConfig,
          stepInPhrase: Int,
          totalSteps: Int
      ) -> Int
      
      /// Generate note-off for previous note
      static func noteOffForTrack(_ track: Track, note: Int) -> MIDIMessage
  }
  ```

- [ ] Create `ScaleEngine.swift`
  ```swift
  enum ScaleEngine {
      /// Get the nth note in a scale from a root
      static func noteInScale(
          scale: Scale,
          root: Note,
          degree: Int,
          octaveOffset: Int
      ) -> Int  // Returns MIDI note number 0-127
      
      /// Quantize a MIDI note to the nearest scale degree
      static func quantizeToScale(
          midiNote: Int,
          scale: Scale,
          root: Note
      ) -> Int
  }
  ```

- [ ] Create `MIDIEngineTests.swift`
  ```swift
  func testNoteOnMessageBytes()
  func testNoteOffMessageBytes()
  func testChannelEncoding()  // Channel 1 = 0x90, Channel 2 = 0x91, etc.
  func testScaleQuantization()
  func testTransposition()
  ```

- [ ] Create `MIDIOutputService.swift` — the only impure MIDI code
  ```swift
  class MIDIOutputService: ObservableObject {
      private var client: MIDIClientRef = 0
      private var outputPort: MIDIPortRef = 0
      private var virtualSource: MIDIEndpointRef = 0
      
      func setup() throws
      func send(_ message: MIDIMessage)
      func teardown()
  }
  ```

- [ ] Create `MIDIInputService.swift` — for external clock
  ```swift
  class MIDIInputService: ObservableObject {
      @Published var receivedClock: Bool = false
      @Published var receivedStart: Bool = false
      @Published var receivedStop: Bool = false
      
      func setup() throws
      func teardown()
  }
  ```

### Verification

```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/MIDIEngineTests
```

- [ ] MIDI message bytes are correct per MIDI spec
- [ ] Scale calculations produce correct note numbers
- [ ] Virtual MIDI port appears in system (manual verification)

---

## Phase 4: Clock Engine & Timing

### Explanation
Precise timing is critical for live use. The clock must be rock-solid.

### Tasks

- [ ] Create `ClockEngine.swift`
  ```swift
  class ClockEngine: ObservableObject {
      @Published private(set) var currentTick: Int = 0
      @Published private(set) var isRunning: Bool = false
      
      private let ppq: Int = 24  // Pulses per quarter note (MIDI standard)
      private var timer: DispatchSourceTimer?
      
      var onTick: ((Int) -> Void)?
      var onStep: ((Int, Int) -> Void)?  // (trackId, stepIndex)
      
      func start(bpm: Double)
      func stop()
      func reset()
      
      /// Calculate interval between ticks in nanoseconds
      static func tickInterval(bpm: Double, ppq: Int) -> UInt64
  }
  ```

- [ ] Create `ClockEngineTests.swift`
  ```swift
  func testTickIntervalAt120BPM() {
      // 120 BPM = 2 beats/sec = 48 ticks/sec at PPQ 24
      // Interval = 1/48 sec ≈ 20.833ms = 20_833_333 ns
      let interval = ClockEngine.tickInterval(bpm: 120, ppq: 24)
      XCTAssertEqual(interval, 20_833_333, accuracy: 1000)
  }
  func testTickIntervalAt60BPM()
  func testTickIntervalAt240BPM()
  ```

- [ ] Implement high-precision timer using `DispatchSourceTimer`
- [ ] Add external clock sync support
  ```swift
  func syncToExternalClock(_ message: MIDIMessage)
  ```

### Verification

```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/ClockEngineTests
```

- [ ] Tick intervals mathematically correct
- [ ] Timer drift test: run for 60 seconds, verify < 10ms cumulative drift

---

## Phase 5: UI Foundation

### Explanation
Build the SwiftUI view hierarchy. Focus on structure first, then polish. Views should be "dumb"—all logic in ViewModel.

### Tasks

- [ ] Create `SequencerViewModel.swift`
  ```swift
  @MainActor
  class SequencerViewModel: ObservableObject {
      @Published var state: SequencerState
      @Published var knobValues: [Int: Double]  // knobId -> 0.0-1.0
      
      private let midiOutput: MIDIOutputService
      private let clock: ClockEngine
      
      // Input handlers (called by UI or MIDI input)
      func padPressed(_ padId: Int)
      func padReleased(_ padId: Int)
      func knobChanged(_ knobId: Int, value: Double)
      
      // Computed for UI
      var selectedTrack: Track { get }
      var currentKnobLabels: [String] { get }  // Changes based on melodic shift
      
      // Actions
      func togglePlayStop()
      func tapTempo()
      func toggleMute()
  }
  ```

- [ ] Create `ContentView.swift` — main layout
  ```swift
  struct ContentView: View {
      @StateObject private var viewModel = SequencerViewModel()
      
      var body: some View {
          VStack(spacing: 20) {
              TransportBar(viewModel: viewModel)
              StepSequencerGrid(viewModel: viewModel)
              ControllerView(viewModel: viewModel)
          }
          .padding()
          .background(Color(.windowBackgroundColor))
      }
  }
  ```

- [ ] Create `TransportBar.swift`
  ```swift
  struct TransportBar: View {
      // Play/Stop button with SF Symbol
      // Tempo display (editable)
      // Clock source indicator (internal/external icon)
      // Current step position display
  }
  ```

- [ ] Create `StepSequencerGrid.swift`
  ```swift
  struct StepSequencerGrid: View {
      // 4 rows (tracks), up to 16 columns (steps)
      // Each cell: rounded rectangle with subtle shadow
      // Active pulses: filled with track color
      // Current playhead: highlighted border
      // Muted tracks: dimmed opacity
  }
  ```

- [ ] Create `TrackRow.swift` — single track in grid
  ```swift
  struct TrackRow: View {
      let track: Track
      let pulsePositions: [Int]
      let currentStep: Int?
      let isSelected: Bool
  }
  ```

- [ ] Create `StepCell.swift` — single step in track
  ```swift
  struct StepCell: View {
      let isActive: Bool      // Has pulse
      let isPlayhead: Bool    // Currently playing
      let trackColor: Color
  }
  ```

- [ ] Create `ControllerView.swift` — LPD8 replica
  ```swift
  struct ControllerView: View {
      // Top row: 8 knobs with labels
      // Bottom row: 8 pads with labels
      // Visual feedback for pad presses
      // Knob rotation visualization
  }
  ```

- [ ] Create `PadView.swift`
  ```swift
  struct PadView: View {
      let label: String
      let color: Color
      let isPressed: Bool
      let sfSymbol: String?
      let action: () -> Void
  }
  ```

- [ ] Create `KnobView.swift`
  ```swift
  struct KnobView: View {
      let label: String
      @Binding var value: Double
      let range: ClosedRange<Double>
      let displayValue: String  // Formatted for display
  }
  ```

- [ ] Set up keyboard shortcuts
  ```swift
  .keyboardShortcut(.space, modifiers: [])  // Play/Stop
  .onKeyPress { /* handle 1-4 for track select */ }
  // Shift key for melodic mode via NSEvent monitoring
  ```

- [ ] Create `KeyboardMonitor.swift` for Shift key detection
  ```swift
  class KeyboardMonitor: ObservableObject {
      @Published var isShiftPressed: Bool = false
      
      func startMonitoring()
      func stopMonitoring()
  }
  ```

### Verification

```bash
xcodebuild build -scheme Arpy
```

- [ ] App launches without crash
- [ ] All views render (visual inspection)
- [ ] Keyboard shortcuts respond (manual test)
- [ ] Shift key toggles melodic mode indicator

---

## Phase 6: Tier 1 Integration — Core Euclidean

### Explanation
Wire up the core Euclidean functionality end-to-end. After this phase, the sequencer should play basic patterns.

### Tasks

- [ ] Connect knobs 1-4 to track parameters (Steps, Pulses, Rotate, Division)
- [ ] Connect pads 1-4 to track selection
- [ ] Connect pad 5 to Play/Stop
- [ ] Implement clock → step sequencer → MIDI output pipeline
- [ ] Update StepSequencerGrid in real-time during playback
- [ ] Add playhead visualization (current step highlighted)
- [ ] Wire tempo knob (knob 8)
- [ ] Create `Tier1IntegrationTests.swift`
  ```swift
  func testPlayStartsClockAndSendsMIDI()
  func testStopSendsAllNotesOff()
  func testKnobChangesUpdatePattern()
  func testPadSelectsTrack()
  ```

### Verification

**Automated:**
```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/Tier1IntegrationTests
```

**Manual Testing Checkpoint — see [Tier 1 Checklist](#tier-1-manual-testing-checklist)**

- [ ] Pattern plays audibly through DAW
- [ ] Changing Steps/Pulses updates pattern in real-time
- [ ] All 4 tracks can be selected and edited independently
- [ ] Play/Stop works reliably
- [ ] No stuck notes on stop

---

## Phase 7: Tier 2 Integration — Essential Variation

### Explanation
Add velocity, sustain, repeats, mute, and tap tempo.

### Tasks

- [ ] Wire knob 5 (Repeats) to track
- [ ] Wire knob 6 (Velocity) to track
- [ ] Wire knob 7 (Sustain) to track  
- [ ] Implement repeat note generation
- [ ] Implement note duration based on sustain %
- [ ] Wire pad 6 (Tap Tempo)
  ```swift
  // Track last 4 tap times, calculate average BPM
  func tapTempo() {
      let now = Date()
      tapTimes.append(now)
      if tapTimes.count > 4 { tapTimes.removeFirst() }
      if tapTimes.count >= 2 {
          // Calculate BPM from intervals
      }
  }
  ```
- [ ] Wire pad 7 (Mute toggle)
- [ ] Update UI to show muted tracks (dimmed)
- [ ] Create `Tier2IntegrationTests.swift`
  ```swift
  func testVelocityAffectsMIDI()
  func testSustainAffectsNoteDuration()
  func testRepeatsGenerateMultipleNotes()
  func testMuteStopsTrackOutput()
  func testTapTempoCalculation()
  ```

### Verification

**Automated:**
```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/Tier2IntegrationTests
```

**Manual Testing Checkpoint — see [Tier 2 Checklist](#tier-2-manual-testing-checklist)**

- [ ] Velocity changes audible in DAW
- [ ] Sustain affects note length
- [ ] Repeats create ratchet effects
- [ ] Tap tempo responds to tapping

---

## Phase 8: Tier 3 Integration — Melodic Features

### Explanation
Implement Melodic Shift mode (Pad 8 hold) with pitch, scale, voicing, and phrase.

### Tasks

- [ ] Implement Pad 8 hold detection (melodic shift mode)
- [ ] Connect Shift key to melodic shift mode
- [ ] Update knob labels when melodic shift active
- [ ] Wire melodic knobs to MelodicConfig:
  - [ ] Knob 1 → Transpose
  - [ ] Knob 2 → Scale
  - [ ] Knob 3 → Root Note
  - [ ] Knob 4 → Voicing Amount
  - [ ] Knob 5 → Voicing Style
  - [ ] Knob 6 → Phrase Shape
  - [ ] Knob 7 → Phrase Range
- [ ] Implement phrase-based pitch modulation
  ```swift
  // Apply phrase shape to pitch over pattern length
  func pitchForStep(step: Int, pattern: EuclideanPattern, config: MelodicConfig) -> Int
  ```
- [ ] Implement voicing (chord inversions)
- [ ] Implement scale quantization
- [ ] Create `Tier3IntegrationTests.swift`
  ```swift
  func testMelodicShiftChangesKnobFunction()
  func testTransposeAffectsPitch()
  func testScaleQuantization()
  func testPhraseShapeModulation()
  ```

### Verification

**Automated:**
```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/Tier3IntegrationTests
```

**Manual Testing Checkpoint — see [Tier 3 Checklist](#tier-3-manual-testing-checklist)**

- [ ] Holding Pad 8 changes knob functions
- [ ] Releasing Pad 8 restores normal knobs
- [ ] Transpose audibly shifts pitch
- [ ] Different scales produce different note selections

---

## Phase 9: State Persistence

### Explanation
Save/restore sequencer state using Core Data or simple JSON file. Essential for rehearsal → performance workflow.

### Tasks

- [ ] Create `PersistenceController.swift`
  ```swift
  class PersistenceController {
      static let shared = PersistenceController()
      
      func save(_ state: SequencerState) throws
      func load() throws -> SequencerState?
      func loadOrDefault() -> SequencerState
  }
  ```

- [ ] Option A: JSON file persistence
  ```swift
  // Simple approach: save to Application Support folder
  let url = FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Arpy")
      .appendingPathComponent("state.json")
  ```

- [ ] Option B: Core Data (if complex queries needed later)
  ```swift
  // Create .xcdatamodeld with entities matching model structs
  ```

- [ ] Auto-save on quit
- [ ] Auto-load on launch
- [ ] Add "Reset to Default" menu item
- [ ] Create `PersistenceTests.swift`
  ```swift
  func testSaveAndLoad()
  func testLoadMissingFileReturnsDefault()
  func testCorruptFileReturnsDefault()
  ```

### Verification

```bash
xcodebuild test -scheme Arpy -only-testing:ArpyTests/PersistenceTests
```

- [ ] Quit app, relaunch → state preserved
- [ ] Delete state file → app launches with defaults
- [ ] Corrupt state file → app launches with defaults (no crash)

---

## Phase 10: Polish & Live Performance Hardening

### Explanation
Final hardening for live use. No crashes, no stuck notes, graceful error handling.

### Tasks

- [ ] Implement panic button (all notes off)
  ```swift
  func panic() {
      for channel in 1...4 {
          for note in 0...127 {
              midiOutput.send(.noteOff(channel: channel, note: note))
          }
      }
  }
  ```

- [ ] Add panic keyboard shortcut (Cmd+Shift+P or Escape)

- [ ] Implement stuck note detection and recovery
  ```swift
  // Track all active notes, send note-off on stop
  private var activeNotes: Set<(channel: Int, note: Int)> = []
  ```

- [ ] Add MIDI device reconnection handling
  ```swift
  // Monitor for MIDI device disconnection/reconnection
  MIDIClientCreateWithBlock(...) { notification in
      if notification.messageID == .msgSetupChanged {
          // Re-enumerate devices
      }
  }
  ```

- [ ] Add external clock sync with tempo detection
- [ ] Implement clock source switching without stopping playback
- [ ] Add CPU usage monitoring (ensure < 5% during playback)
- [ ] Memory leak testing with Instruments
- [ ] Stress test: run for 30 minutes continuous
- [ ] UI responsiveness test during playback
- [ ] Add About window with version info
- [ ] Add minimal menu bar (File, Edit, Window, Help)

### Verification

**Automated:**
```bash
# Run all tests
xcodebuild test -scheme Arpy
```

**Performance:**
```bash
# Run Instruments for leaks
xcrun xctrace record --template 'Leaks' --launch -- ./Build/Products/Debug/Arpy.app
```

**Manual Testing:**
- [ ] Play continuously for 30 minutes → no crashes, no stuck notes
- [ ] Rapidly start/stop → no issues
- [ ] Change all parameters during playback → no glitches
- [ ] Disconnect/reconnect MIDI controller → recovers gracefully
- [ ] Switch clock source during playback → syncs correctly

---

## Phase 11: MIDI Controller Integration

### Explanation
Connect the physical AKAI LPD8 MKII. This is tested last because the UI should be fully functional first.

### Tasks

- [ ] Create `MIDIControllerService.swift`
  ```swift
  class MIDIControllerService: ObservableObject {
      @Published var isConnected: Bool = false
      
      // LPD8 sends CC messages for knobs, Note On/Off for pads
      func setup() throws
      func handleMIDIInput(_ packet: MIDIPacket)
  }
  ```

- [ ] Map LPD8 MIDI messages to actions
  ```swift
  // LPD8 Default Mapping (Program 1):
  // Pads 1-8: Notes 36-43
  // Knobs 1-8: CC 1-8
  
  func handleCC(_ cc: Int, value: Int)
  func handleNoteOn(_ note: Int, velocity: Int)
  func handleNoteOff(_ note: Int)
  ```

- [ ] Handle pad velocity for track selection visual feedback
- [ ] Handle Pad 8 hold detection (Note On vs Note Off timing)
- [ ] Add controller connection status indicator in UI
- [ ] Create `MIDIControllerTests.swift` (mock MIDI input)

### Verification

**Manual Testing:**
- [ ] All 8 pads trigger correct actions
- [ ] All 8 knobs control correct parameters
- [ ] Pad 8 hold activates melodic mode
- [ ] Controller can be disconnected and reconnected

---

## UI Integration Tests

### Explanation
XCUITest tests for UI behavior.

### Tasks

- [ ] Create `UITestHelpers.swift`
  ```swift
  extension XCUIApplication {
      func tapPad(_ number: Int)
      func setKnob(_ number: Int, to value: Double)
      func waitForPlayhead(at step: Int)
  }
  ```

- [ ] Create `BasicUITests.swift`
  ```swift
  func testPlayStopButton()
  func testTrackSelection()
  func testKnobAdjustment()
  func testMelodicShiftWithShiftKey()
  ```

- [ ] Create `StepSequencerUITests.swift`
  ```swift
  func testPulseVisualization()
  func testPlayheadMovement()
  func testMutedTrackAppearance()
  ```

- [ ] Create `KeyboardShortcutTests.swift`
  ```swift
  func testSpacebarTogglesPlayback()
  func testNumberKeysSelectTrack()
  func testShiftKeyMelodicMode()
  ```

### Verification

```bash
xcodebuild test -scheme Arpy -only-testing:ArpyUITests
```

---

## Manual Testing Checklists

### Tier 1 Manual Testing Checklist

Perform after completing Phase 6.

**Setup:**
1. Launch app
2. Open DAW (Ableton/Logic) and create 4 MIDI tracks receiving from "Euclidean Sequencer" channels 1-4
3. Assign a drum sound to each track

**Tests:**

- [ ] **T1.1** Press Play → clock starts, MIDI output begins
- [ ] **T1.2** Press Stop → all notes stop immediately (no stuck notes)
- [ ] **T1.3** Adjust Steps knob → pattern length changes visually and audibly
- [ ] **T1.4** Adjust Pulses knob → number of hits changes
- [ ] **T1.5** Adjust Rotate knob → pattern shifts start position
- [ ] **T1.6** Adjust Division knob → playback speed changes
- [ ] **T1.7** Press Pad 1-4 → corresponding track highlights
- [ ] **T1.8** Each track outputs to correct MIDI channel
- [ ] **T1.9** Step sequencer grid shows correct pulse positions
- [ ] **T1.10** Playhead moves through grid during playback

### Tier 2 Manual Testing Checklist

Perform after completing Phase 7.

- [ ] **T2.1** Velocity knob changes loudness of notes
- [ ] **T2.2** Sustain knob changes note duration
- [ ] **T2.3** Repeats knob creates ratchet/roll effect
- [ ] **T2.4** Tap Pad 6 multiple times → tempo adjusts
- [ ] **T2.5** Press Pad 7 → selected track mutes (visual + audio)
- [ ] **T2.6** Press Pad 7 again → track unmutes
- [ ] **T2.7** Muted tracks show dimmed in grid

### Tier 3 Manual Testing Checklist

Perform after completing Phase 8.

- [ ] **T3.1** Hold Pad 8 → knob labels change to melodic functions
- [ ] **T3.2** Release Pad 8 → knob labels return to normal
- [ ] **T3.3** Hold Shift key → same as holding Pad 8
- [ ] **T3.4** Adjust Transpose while holding Pad 8 → pitch shifts
- [ ] **T3.5** Change Scale → notes quantize differently
- [ ] **T3.6** Change Root Note → scale shifts
- [ ] **T3.7** Adjust Phrase Shape → melodic pattern changes
- [ ] **T3.8** Adjust Range → pitch variation increases/decreases

### Live Performance Stress Test

Perform after completing Phase 10.

- [ ] **LP.1** Run continuously for 30+ minutes → no crashes
- [ ] **LP.2** Rapidly press Play/Stop 50 times → no stuck notes
- [ ] **LP.3** Move all knobs simultaneously → no UI lag
- [ ] **LP.4** Change patterns on all tracks while playing → smooth transitions
- [ ] **LP.5** CPU usage stays under 10% during playback
- [ ] **LP.6** Memory usage stable (no growth over time)

---

## Appendix A: Euclidean Algorithm Reference

### Bjorklund's Algorithm

```
Input: steps (n), pulses (k)
Output: binary pattern where k ones are distributed as evenly as possible among n positions

Algorithm (simplified):
1. Create k sequences of "1" and (n-k) sequences of "0"
2. Repeatedly distribute the shorter sequences among the longer ones
3. Continue until only one or two different sequence types remain
4. Concatenate all sequences

Example: E(8,3)
Initial: [1] [1] [1] [0] [0] [0] [0] [0]
Step 1:  [1,0] [1,0] [1,0] [0] [0]
Step 2:  [1,0,0] [1,0,0] [1,0]
Result:  1 0 0 1 0 0 1 0 → positions [0, 3, 6]
```

### Common Euclidean Rhythms

| Pattern | Rhythm | Musical Context |
|---------|--------|-----------------|
| E(8,3) | X..X..X. | Cuban tresillo |
| E(8,5) | X.XX.XX. | Cuban cinquillo |
| E(16,5) | X..X..X..X..X... | Bossa nova |
| E(12,5) | X..X.X..X.X. | Khafif-e-ramal |
| E(16,9) | X.XX.X.X.XX.X.X. | West African |

---

## Appendix B: SF Symbols Reference

Use these system symbols for UI consistency:

| Function | SF Symbol |
|----------|-----------|
| Play | `play.fill` |
| Stop | `stop.fill` |
| Pause | `pause.fill` |
| Mute | `speaker.slash.fill` |
| Unmute | `speaker.wave.2.fill` |
| Tap Tempo | `metronome.fill` |
| Internal Clock | `clock.fill` |
| External Clock | `clock.arrow.2.circlepath` |
| Settings | `gearshape.fill` |
| Track 1-4 | `1.circle.fill` ... `4.circle.fill` |
| Melodic Mode | `music.note` |
| Connected | `cable.connector` |
| Disconnected | `cable.connector.slash` |

---

## Appendix C: Color Palette

```swift
extension Color {
    static let track1 = Color(red: 0.98, green: 0.36, blue: 0.35)  // Coral
    static let track2 = Color(red: 0.30, green: 0.69, blue: 0.31)  // Green
    static let track3 = Color(red: 0.25, green: 0.47, blue: 0.85)  // Blue
    static let track4 = Color(red: 0.61, green: 0.35, blue: 0.71)  // Purple
    
    static let playhead = Color.white
    static let background = Color(nsColor: .windowBackgroundColor)
    static let stepInactive = Color.gray.opacity(0.2)
    static let stepActive = Color.white.opacity(0.9)
}
```

**Step Cell Styling:**
- Corner radius: 4pt
- Shadow: 2pt blur, 1pt y-offset, 10% opacity
- Active pulse: track color with 90% opacity
- Inactive step: gray with 20% opacity
- Playhead: white border, 2pt width

---

## Development Notes for Coding Agent

### Code Style Requirements

1. **Readable Swift**: Prefer clarity over cleverness
2. **Documentation**: Public APIs must have doc comments
3. **Naming**: Follow Swift API Design Guidelines
4. **No force unwraps** except in tests with explanation
5. **No magic numbers**: Use named constants

### Commit Convention

```
[Phase X] Task description

- Detail 1
- Detail 2

Verification: [x] Test name passed
```

### When Stuck

1. Re-read the task requirements
2. Check if prerequisite phases are complete
3. Run existing tests to ensure nothing is broken
4. If a task is blocked, document why and move to next available task

### Testing Philosophy

- **Unit tests**: Fast, isolated, test pure functions
- **Integration tests**: Test component interaction
- **UI tests**: Test user-facing behavior
- **Manual tests**: Verify audio/MIDI output (cannot be automated)

The functional core should be so well-tested that bugs are almost always in the UI layer or MIDI I/O.

---

When done building all functionality, write <promise>DONE</promise> to Claude Code. It will then know that all tasks are complete. Only send this signal when the entire PRD is complete.

*End of PRD*
