import CoreHaptics
import SwiftUI

// MARK: - Score

/// Haptics are authored as a score against the same clock as the visuals, so a timing
/// change is a one-line edit rather than a hunt through view code.
///
/// Rule 5: fire on the *cause* (touch-down) and on the moment of visual commitment.
/// Never on the settle — a haptic after motion has stopped reads as a bug.
struct HapticEvent: Sendable, Identifiable {
    enum Kind: Sendable {
        case transient(intensity: Double, sharpness: Double)
        case continuous(duration: Double, intensity: Double, sharpness: Double, decay: Double)
    }

    var id = UUID()
    var offset: Double
    var kind: Kind
    var label: String
}

extension TaskCompletionStyle {
    /// Offsets are in seconds from commit, matching the timelines in each style view.
    var hapticScore: [HapticEvent] {
        switch self {
        case .strikeCascade:
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.5, sharpness: 0.35), label: "soft · impulse"),
                HapticEvent(offset: 0.21, kind: .transient(intensity: 0.8, sharpness: 0.7), label: "success · commit")
            ]
        case .stamp:
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.9, sharpness: 0.9), label: "rigid · press"),
                HapticEvent(offset: 0.155, kind: .transient(intensity: 0.75, sharpness: 0.6), label: "success · apex")
            ]
        case .liquidMetal:
            // The only style that earns CoreHaptics proper: a continuous event whose
            // intensity tracks the band's velocity, bookended by two transients.
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.45, sharpness: 0.5), label: "soft · impulse"),
                HapticEvent(
                    offset: 0.02,
                    kind: .continuous(duration: 0.45, intensity: 0.45, sharpness: 0.25, decay: 1.2),
                    label: "continuous · sweep"
                ),
                HapticEvent(offset: 0.47, kind: .transient(intensity: 0.7, sharpness: 0.65), label: "click · settle")
            ]
        case .settleRecede:
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.4, sharpness: 0.25), label: "soft · tip"),
                HapticEvent(offset: 0.195, kind: .transient(intensity: 0.65, sharpness: 0.8), label: "light · latch")
            ]
        case .swell:
            // Visual and haptic share literally the same exp(-decay·t) envelope.
            [
                HapticEvent(offset: 0, kind: .transient(intensity: 0.8, sharpness: 0.85), label: "rigid · pebble"),
                HapticEvent(
                    offset: 0.01,
                    kind: .continuous(duration: 0.6, intensity: 0.5, sharpness: 0.2, decay: 3.6),
                    label: "continuous · decay"
                )
            ]
        }
    }
}

// MARK: - Engine

@MainActor
@Observable
final class CompletionHaptics {
    struct Pulse: Identifiable, Sendable {
        let id = UUID()
        var label: String
        var intensity: Double
        var firedAt: Date
    }

    /// Recent events, so the timing is inspectable on a simulator that cannot vibrate.
    private(set) var pulses: [Pulse] = []
    private(set) var supportsHaptics = false

    private var engine: CHHapticEngine?
    private var scheduled: [Task<Void, Never>] = []

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = true
        engine?.playsHapticsOnly = true
        try? engine?.start()
    }

    func cancelPending() {
        for task in scheduled { task.cancel() }
        scheduled.removeAll()
    }

    /// Schedules a whole score. Re-tapping cancels anything still pending, so an
    /// interrupted animation never fires the haptics of the run it replaced.
    func play(_ score: [HapticEvent], speed: Double, enabled: Bool) {
        cancelPending()
        guard enabled else { return }

        let clock = max(speed, 0.05)
        for event in score {
            let delay = event.offset / clock
            let task = Task { @MainActor [weak self] in
                if delay > 0 {
                    try? await Task.sleep(for: .seconds(delay))
                }
                guard !Task.isCancelled else { return }
                self?.fire(event, speed: clock)
            }
            scheduled.append(task)
        }
    }

    /// Layers a score on top of whatever is already scheduled. A pill press during a
    /// completion is a second, separate thing the user pressed — it should not cancel the
    /// first the way one commit cancels another.
    func playAdditional(_ score: [HapticEvent], speed: Double, enabled: Bool) {
        guard enabled else { return }
        let pace = max(speed, 0.05)
        for event in score {
            let delay = event.offset / pace
            let task = Task { @MainActor [weak self] in
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
                guard !Task.isCancelled else { return }
                self?.fire(event, speed: pace)
            }
            scheduled.append(task)
        }
    }

    private func fire(_ event: HapticEvent, speed: Double) {
        let intensity: Double
        switch event.kind {
        case let .transient(value, _): intensity = value
        case let .continuous(_, value, _, _): intensity = value
        }

        pulses.append(Pulse(label: event.label, intensity: intensity, firedAt: .now))
        if pulses.count > 8 { pulses.removeFirst(pulses.count - 8) }

        guard supportsHaptics, let engine else { return }
        try? engine.start()
        guard let pattern = pattern(for: event, speed: speed) else { return }
        try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    }

    private func pattern(for event: HapticEvent, speed: Double) -> CHHapticPattern? {
        switch event.kind {
        case let .transient(intensity, sharpness):
            let haptic = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: Float(intensity)),
                    .init(parameterID: .hapticSharpness, value: Float(sharpness))
                ],
                relativeTime: 0
            )
            return try? CHHapticPattern(events: [haptic], parameters: [])

        case let .continuous(duration, intensity, sharpness, decay):
            let scaledDuration = duration / speed
            let haptic = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: Float(intensity)),
                    .init(parameterID: .hapticSharpness, value: Float(sharpness))
                ],
                relativeTime: 0,
                duration: scaledDuration
            )

            // Sample exp(-decay·t) so the felt envelope matches the drawn one.
            let samples = 10
            let points = (0..<samples).map { step -> CHHapticParameterCurve.ControlPoint in
                let t = Double(step) / Double(samples - 1)
                let value = exp(-decay * t)
                return .init(relativeTime: t * scaledDuration, value: Float(value))
            }
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: points,
                relativeTime: 0
            )
            return try? CHHapticPattern(events: [haptic], parameterCurves: [curve])
        }
    }
}
