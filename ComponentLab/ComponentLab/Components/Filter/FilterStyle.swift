import SwiftUI

// MARK: - Style

enum FilterStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case sift
    case deal
    case focus
    case zip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sift: "Sift"
        case .deal: "Deal"
        case .focus: "Focus"
        case .zip: "Zip"
        }
    }

    var carrier: String {
        switch self {
        case .sift: "Settling"
        case .deal: "Objects"
        case .focus: "Depth"
        case .zip: "Wavefront"
        }
    }
}

// MARK: - Presentation

/// What a filter style does to a row that is leaving or arriving. Everything here is
/// *presentation only* — slot position is still owned by the reorder engine, so filtering and
/// completing share one settling behaviour instead of fighting over it.
struct FilterPresentation: Equatable, Sendable {
    var opacity: Double = 1
    var scale: Double = 1
    var offsetX: Double = 0
    var offsetY: Double = 0
    var rotation: Double = 0
    var blur: Double = 0
}

// MARK: - Haptics

extension FilterStyle {
    /// The pill press is always felt; what the list adds is what differs. Deal and Zip report
    /// *how many* rows left, which is information rather than mere confirmation.
    func hapticScore(leavingDelays: [Double], tuning: FilterTuning) -> [HapticEvent] {
        let pill = HapticEvent(
            offset: 0,
            kind: .transient(intensity: 0.45, sharpness: 0.6),
            label: "light · pill"
        )

        switch self {
        case .sift:
            return [pill]

        case .deal:
            // One tick per card as it clears the edge.
            return [pill] + leavingDelays.enumerated().map { index, delay in
                HapticEvent(
                    offset: delay + tuning.deal.exitSpring.duration * 0.7,
                    kind: .transient(intensity: 0.5, sharpness: 0.8),
                    label: "tick · card \(index + 1)"
                )
            }

        case .focus:
            return [
                pill,
                HapticEvent(
                    offset: 0.04,
                    kind: .transient(intensity: 0.25, sharpness: 0.2),
                    label: "soft · recede"
                ),
                HapticEvent(
                    offset: tuning.focus.ghostFrame,
                    kind: .transient(intensity: 0.4, sharpness: 0.45),
                    label: "light · close"
                )
            ]

        case .zip:
            let front = leavingDelays.max() ?? 0.2
            return [
                pill,
                HapticEvent(
                    offset: 0.02,
                    kind: .continuous(
                        duration: max(front, 0.12),
                        intensity: 0.3,
                        sharpness: 0.25,
                        decay: 0.6
                    ),
                    label: "rumble · wavefront"
                )
            ] + leavingDelays.enumerated().map { index, delay in
                HapticEvent(
                    offset: delay,
                    kind: .transient(intensity: 0.35, sharpness: 0.7),
                    label: "tick \(index + 1)"
                )
            }
        }
    }
}
