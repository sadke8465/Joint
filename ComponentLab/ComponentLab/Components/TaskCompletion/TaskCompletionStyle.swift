import SwiftUI

// MARK: - Style

enum TaskCompletionStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case strikeCascade
    case stamp
    case liquidMetal
    case settleRecede
    case swell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strikeCascade: "Strike Cascade"
        case .stamp: "Stamp"
        case .liquidMetal: "Liquid Metal"
        case .settleRecede: "Settle & Recede"
        case .swell: "Swell"
        }
    }

    /// Styles whose position comes from a Metal uniform, and so can be frozen and scrubbed.
    var isShaderDriven: Bool { self == .liquidMetal || self == .swell }

    /// What carries the meaning in this style.
    var carrier: String {
        switch self {
        case .strikeCascade: "Line"
        case .stamp: "Force"
        case .liquidMetal: "Material"
        case .settleRecede: "Space"
        case .swell: "Field"
        }
    }
}

/// Per-screen presentation choices that are not tuning values. Defaults reproduce exactly
/// what the completion and move-down labs already do; the final playground opts in.
struct CompletionOptions: Equatable, Sendable {
    /// Stamp normally opens its line from a hairline in Y — a stamp hits everything at once.
    /// The final build sweeps it left to right instead, like a pen.
    var strikeSweepsHorizontally = false
}

// MARK: - Spring

/// A spring described the way it is designed rather than the way it is solved:
/// a settling duration, a bounce amount, and a stagger offset from the impulse.
///
/// `Animation.spring(duration:bounce:)` retargets from current velocity when the value
/// it is bound to changes mid-flight, which is what makes every style here interruptible
/// without any manual velocity bookkeeping.
struct SpringSpec: Codable, Equatable, Sendable {
    var duration: Double
    var bounce: Double
    var delay: Double

    init(_ duration: Double, bounce: Double = 0, delay: Double = 0) {
        self.duration = duration
        self.bounce = bounce
        self.delay = delay
    }

    /// Rule 4 — undo is a correction, not an event. Reversing runs shorter, calmer, and
    /// with a compressed stagger so the row snaps back rather than replaying the show.
    func resolved(_ context: MotionContext) -> Animation {
        let speed = max(context.speed, 0.05)
        let reversing = context.reversing

        if context.reduceMotion {
            return .easeOut(duration: 0.22 / speed).delay(delay * 0.4 / speed)
        }

        let resolvedDuration = (reversing ? duration * 0.7 : duration) / speed
        let resolvedBounce = reversing ? bounce * 0.6 : bounce
        let resolvedDelay = (reversing ? delay * 0.35 : delay) / speed

        let animation = Animation.spring(duration: resolvedDuration, bounce: resolvedBounce)
        return resolvedDelay > 0 ? animation.delay(resolvedDelay) : animation
    }
}

// MARK: - Motion context

/// Everything that scales or suppresses motion globally, passed down once instead of
/// being read from the environment in a dozen places.
struct MotionContext: Equatable, Sendable {
    var speed: Double = 1.0
    var reversing: Bool = false
    var reduceMotion: Bool = false
    /// When set, the shader-driven styles read their position from here instead of from an
    /// animation. Scrubbing a shader by hand is how you actually tune one.
    var scrub: Double?

    /// Multiplier applied to every *displacement* (offsets, rotations, wave amplitude).
    /// Reduce Motion keeps the choreography and its timing but stops moving things,
    /// which degrades far better than removing the animation outright.
    var motionScale: Double { reduceMotion ? 0 : 1 }
}

// MARK: - Completion length

extension TaskCompletionStyle {
    /// Where the completion animation perceptually ends, computed from the current tuning so
    /// a sequential handoff follows your edits instead of drifting out of date.
    ///
    /// Swell's per-layer delays are derived at runtime from distance / speed rather than
    /// stored, so its wave duration stands in for them.
    func nominalDuration(_ tuning: TaskCompletionTuning) -> Double {
        func end(_ specs: [SpringSpec]) -> Double {
            specs.map { $0.delay + $0.duration }.max() ?? 0.5
        }

        switch self {
        case .strikeCascade:
            let t = tuning.strike
            return end([t.checkboxSpring, t.fillSpring, t.checkSpring, t.strikeSpring,
                        t.dueOutSpring, t.dueInSpring, t.cardSpring])
        case .stamp:
            let t = tuning.stamp
            return end([t.pressSpring, t.reboundSpring, t.fillSpring, t.checkSpring,
                        t.strikeSpring, t.titleSpring, t.dueSpring, t.cardSpring])
        case .liquidMetal:
            let t = tuning.metal
            return end([t.bandSpring, t.lightSpring, t.fillSpring, t.checkSpring,
                        t.dueSpring, t.cardSpring])
        case .settleRecede:
            let t = tuning.recede
            return end([t.tipSpring, t.returnSpring, t.brightnessSpring, t.fillSpring,
                        t.checkSpring, t.strikeSpring, t.dueSpring, t.restSpring])
        case .swell:
            let t = tuning.swell
            return max(t.waveDuration, end([t.checkboxSpring, t.checkSpring, t.fillSpring,
                                            t.strikeSpring, t.titleSpring, t.dueSpring,
                                            t.assigneeSpring, t.cardSpring]))
        }
    }
}
