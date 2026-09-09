import Foundation

/// The handoff between the two labs: the completion tuning you dialled in, plus which style
/// you had selected when you hit Save. All five tunings travel, so the move-down lab can
/// swap completion styles live and you can feel all twenty pairings.
struct CompletionPreset: Codable, Equatable, Sendable {
    var tuning: TaskCompletionTuning
    var style: TaskCompletionStyle
    var savedAt: Date

    static let storageKey = "componentlab.completionPreset"

    static func save(tuning: TaskCompletionTuning, style: TaskCompletionStyle) {
        let preset = CompletionPreset(tuning: tuning, style: style, savedAt: .now)
        guard let data = try? JSONEncoder().encode(preset) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func load() -> CompletionPreset? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(CompletionPreset.self, from: data)
    }

    static var exists: Bool { load() != nil }
}
