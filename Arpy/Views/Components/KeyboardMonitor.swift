import AppKit
import Combine

/// Monitors keyboard events for Shift key detection.
class KeyboardMonitor: ObservableObject {
    @Published var isShiftPressed = false

    var onShiftChanged: ((Bool) -> Void)?

    private var flagsMonitor: Any?

    func startMonitoring() {
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let shiftDown = event.modifierFlags.contains(.shift)
            self?.isShiftPressed = shiftDown
            self?.onShiftChanged?(shiftDown)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
