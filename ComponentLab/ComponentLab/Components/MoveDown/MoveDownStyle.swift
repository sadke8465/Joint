import SwiftUI

// MARK: - Style

enum MoveDownStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case closeRanks
    case drop
    case slot
    case undertow
    case vault

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closeRanks: "Close Ranks"
        case .drop: "Drop"
        case .slot: "Slot"
        case .undertow: "Undertow"
        case .vault: "Vault"
        }
    }

    /// What carries the meaning, and which plane the moving row travels on.
    var carrier: String {
        switch self {
        case .closeRanks: "Neighbours"
        case .drop: "Gravity"
        case .slot: "The gap"
        case .undertow: "Depth"
        case .vault: "Arc"
        }
    }

    /// A reorder has to answer "what plane is the moving row on?", and this is most of what
    /// separates the four. Close Ranks stays in the list; Drop and Slot ride above it;
    /// Undertow passes behind — the cards are opaque, so it genuinely disappears.
    var moverPlane: Double {
        switch self {
        case .closeRanks: 0
        case .drop, .slot: 10
        case .undertow: -10
        // Highest of all: it jumps clear over everything on its way down.
        case .vault: 20
        }
    }
}

extension MoveDownStyle {
    /// Vault waits for the completion to finish rather than overlapping its propagation
    /// beat, so its handoff is derived from the completion's own settling time minus an
    /// explicit overlap. Every other style starts mid-completion.
    var startsAfterCompletion: Bool { self == .vault }
}

// MARK: - Roles

/// A reorder is three animations: the mover, the rows it displaces, and the gap. The
/// failure mode is running all three on one spring at one instant — that reads as a
/// spreadsheet re-sorting. Physical means the displaced rows react *to the mover*.
enum MoveRole: Equatable {
    case mover
    /// `crossing` is when the mover passes this row, 0...1 along its travel. `rank` is how
    /// many rows out from the mover this one sits.
    case displaced(crossing: Double, rank: Int)
    case idle

    var isMover: Bool { self == .mover }
}

// MARK: - Phases

/// Position stays on a plain retargetable spring so rapid completions can interrupt each
/// other; only the decorative beats are phased. Splitting them is what keeps "interruptible"
/// true where it matters and "multi-beat" possible where it reads.
enum MovePhase: Int, CaseIterable, Comparable, Sendable {
    case rest
    case lift
    case travel
    case impact
    case settle

    static func < (lhs: MovePhase, rhs: MovePhase) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Everything a move style can do to a row that is not its slot position.
struct RowDecoration: Equatable, Sendable {
    var scaleX: Double = 1
    var scaleY: Double = 1
    var extraOffsetX: Double = 0
    var extraOffsetY: Double = 0
    var liftShadowRadius: Double = 0
    var liftShadowOpacity: Double = 0
    var opacity: Double = 1
    var blur: Double = 0
}

// MARK: - Haptics

extension MoveDownStyle {
    /// Offsets are relative to the handoff, not to the tap. The lab shifts them.
    func hapticScore(travel: Double, crouch: Double = 0.09, stagger: Double = 0.045) -> [HapticEvent] {
        switch self {
        case .closeRanks:
            [HapticEvent(offset: travel, kind: .transient(intensity: 0.35, sharpness: 0.3), label: "light · arrive")]
        case .drop:
            // Silence through the fall is what makes the landing hit. Fill it and the
            // impact evaporates.
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.4, sharpness: 0.35), label: "soft · unlatch"),
                HapticEvent(offset: travel, kind: .transient(intensity: 0.95, sharpness: 0.9), label: "rigid · impact")
            ]
        case .slot:
            // Two-part landing reads as "seated AND locked"; one transient cannot.
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.45, sharpness: 0.5), label: "light · lift out"),
                HapticEvent(offset: travel, kind: .transient(intensity: 0.85, sharpness: 0.85), label: "rigid · seat"),
                HapticEvent(offset: travel + 0.045, kind: .transient(intensity: 0.4, sharpness: 0.3), label: "soft · flush")
            ]
        case .undertow:
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.4, sharpness: 0.25), label: "soft · submerge"),
                HapticEvent(
                    offset: 0.02,
                    kind: .continuous(duration: max(travel - 0.05, 0.1), intensity: 0.28, sharpness: 0.12, decay: 0.8),
                    label: "muffled · beneath"
                ),
                HapticEvent(offset: travel, kind: .transient(intensity: 0.55, sharpness: 0.5), label: "light · surface")
            ]

        case .vault:
            // Load, tick at take-off, silence through the arc, land — then a short rattle as
            // the other rows stagger back. The rattle is the playful part, and it only works
            // because the stagger is a real timing value rather than a decorative flourish.
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.3, sharpness: 0.2), label: "soft · load"),
                HapticEvent(offset: crouch, kind: .transient(intensity: 0.5, sharpness: 0.75), label: "tick · take-off"),
                HapticEvent(offset: travel, kind: .transient(intensity: 0.8, sharpness: 0.8), label: "rigid · land"),
                HapticEvent(offset: travel + stagger, kind: .transient(intensity: 0.22, sharpness: 0.5), label: "rattle 1"),
                HapticEvent(offset: travel + stagger * 2, kind: .transient(intensity: 0.16, sharpness: 0.5), label: "rattle 2"),
                HapticEvent(offset: travel + stagger * 3, kind: .transient(intensity: 0.11, sharpness: 0.5), label: "rattle 3")
            ]
        }
    }
}
