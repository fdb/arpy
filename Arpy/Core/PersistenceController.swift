import Foundation

/// Handles saving and loading sequencer state to/from JSON.
class PersistenceController {
    static let shared = PersistenceController()

    private var stateURL: URL {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Arpy", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        return appSupport.appendingPathComponent("state.json")
    }

    /// Save sequencer state to disk.
    func save(_ state: SequencerState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: .atomic)
    }

    /// Load sequencer state from disk.
    func load() throws -> SequencerState? {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return nil }
        let data = try Data(contentsOf: stateURL)
        return try JSONDecoder().decode(SequencerState.self, from: data)
    }

    /// Load state or return default if missing/corrupt.
    func loadOrDefault() -> SequencerState {
        do {
            if let state = try load() {
                return state
            }
        } catch {
            print("Failed to load state, using default: \(error)")
        }
        return .default
    }

    /// Delete saved state.
    func reset() {
        try? FileManager.default.removeItem(at: stateURL)
    }
}
