import Foundation

/// Command-line entry points for the lab, so a style can be opened, driven and captured
/// without tapping through the catalog:
///
///     xcrun simctl launch --terminate-running-process <device> com.example.ComponentLab \
///         -motionLab 1 -style liquidMetal -scrub 0.45 -completed 1
///
/// Two things are easy to get wrong here:
///
/// - `--terminate-running-process` is required. Without it `simctl launch` foregrounds the
///   running copy and silently ignores the new arguments.
/// - Every option is a `-key value` pair, never a bare flag. Foundation parses those pairs
///   into `UserDefaults`' argument domain, which is the path that actually works; bare
///   flags do not reliably survive.
enum LaunchOptions {
    static var opensMotionLab: Bool { boolean("motionLab") }
    static var opensMoveDownLab: Bool { boolean("moveDownLab") }
    static var opensFinalPlayground: Bool { boolean("final") }
    static var opensFilterLab: Bool { boolean("filterLab") }
    static var opensSuggestion: Bool { boolean("suggestion") }

    /// Opens straight into fullscreen, so a capture never has to tap the chrome away first.
    static var opensFullscreen: Bool { boolean("fullscreen") }

    static var filter: TaskFilter? {
        value(for: "filter").flatMap(TaskFilter.init(rawValue:))
    }

    static var filterStyle: FilterStyle? {
        value(for: "filterStyle").flatMap(FilterStyle.init(rawValue:))
    }

    static var moveStyle: MoveDownStyle? {
        value(for: "moveStyle").flatMap(MoveDownStyle.init(rawValue:))
    }
    static var autoLoop: Bool { boolean("autoLoop") }
    static var completed: Bool { boolean("completed") }
    static var stress: Bool { boolean("stress") }

    static var style: TaskCompletionStyle? {
        value(for: "style").flatMap(TaskCompletionStyle.init(rawValue:))
    }

    static var speed: Double? { value(for: "speed").flatMap(Double.init) }
    static var scrub: Double? { value(for: "scrub").flatMap(Double.init) }

    private static func boolean(_ key: String) -> Bool {
        guard let raw = value(for: key)?.lowercased() else { return false }
        return ["1", "yes", "true", "y"].contains(raw)
    }

    private static func value(for key: String) -> String? {
        if let stored = UserDefaults.standard.string(forKey: key), !stored.isEmpty {
            return stored
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-\(key)"), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}
