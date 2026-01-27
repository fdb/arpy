import AppKit
import Combine

/// Monitors keyboard events for global shortcuts and Shift key detection.
class KeyboardMonitor: ObservableObject {
    @Published var isShiftPressed = false

    var onShiftChanged: ((Bool) -> Void)?
    var onKeyDown: ((UInt16) -> Void)?

    private var flagsMonitor: Any?
    private var keyDownMonitor: Any?

    func startMonitoring() {
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let shiftDown = event.modifierFlags.contains(.shift)
            self?.isShiftPressed = shiftDown
            self?.onShiftChanged?(shiftDown)
            return event
        }

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Ignore key repeats
            guard !event.isARepeat else { return event }
            self?.onKeyDown?(event.keyCode)

            // Consume space so it doesn't trigger buttons
            if event.keyCode == 49 { return nil }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
