import Foundation

/// High-precision clock engine for sequencer timing.
class ClockEngine: ObservableObject {
    @Published private(set) var currentTick: Int = 0
    @Published private(set) var isRunning: Bool = false

    /// Pulses per quarter note (MIDI standard).
    let ppq: Int = 24

    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.arpy.clock", qos: .userInteractive)

    /// Called on every MIDI clock tick.
    var onTick: ((Int) -> Void)?

    /// Called when a step boundary is crossed for a track: (trackId, stepIndex).
    var onStep: ((Int, Int) -> Void)?

    /// Start the clock at the given BPM.
    func start(bpm: Double) {
        guard !isRunning else { return }

        currentTick = 0
        isRunning = true

        let interval = ClockEngine.tickInterval(bpm: bpm, ppq: ppq)

        let source = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        source.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(interval)),
            leeway: .nanoseconds(0)
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let tick = self.currentTick
            DispatchQueue.main.async {
                self.currentTick = tick + 1
            }
            self.onTick?(tick)
        }
        source.resume()
        timer = source
    }

    /// Stop the clock.
    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }

    /// Reset the clock to tick 0.
    func reset() {
        currentTick = 0
    }

    /// Update the tempo while running.
    func updateTempo(bpm: Double) {
        guard isRunning else { return }
        stop()
        start(bpm: bpm)
    }

    /// Calculate the interval between ticks in nanoseconds.
    /// - Parameters:
    ///   - bpm: Beats per minute.
    ///   - ppq: Pulses per quarter note.
    /// - Returns: Tick interval in nanoseconds.
    static func tickInterval(bpm: Double, ppq: Int) -> UInt64 {
        // seconds per beat = 60 / bpm
        // seconds per tick = 60 / (bpm * ppq)
        // nanoseconds per tick = 60_000_000_000 / (bpm * ppq)
        let nanosPerTick = 60_000_000_000.0 / (bpm * Double(ppq))
        return UInt64(nanosPerTick)
    }

    deinit {
        stop()
    }
}
