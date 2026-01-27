import SwiftUI

@main
struct ArpyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Reset to Default") {
                    PersistenceController.shared.reset()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // Auto-save handled by ViewModel
    }
}
