import SwiftUI

// MARK: - Root

struct TaskCompletionTuning: Codable, Equatable, Sendable {
    var strike = StrikeCascadeTuning()
    var stamp = StampTuning()
    var metal = LiquidMetalTuning()
    var recede = SettleRecedeTuning()
    var swell = SwellTuning()

    init() {}

    /// Synthesized `Decodable` throws on a missing key even when the property has a default,
    /// so adding one knob would silently reset a saved preset in its entirety. Decoding each
    /// group independently bounds that to the group that actually changed.
    ///
    /// Export before asking for new parameters and nothing is ever lost.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strike = (try? container.decode(StrikeCascadeTuning.self, forKey: .strike)) ?? .init()
        stamp = (try? container.decode(StampTuning.self, forKey: .stamp)) ?? .init()
        metal = (try? container.decode(LiquidMetalTuning.self, forKey: .metal)) ?? .init()
        recede = (try? container.decode(SettleRecedeTuning.self, forKey: .recede)) ?? .init()
        swell = (try? container.decode(SwellTuning.self, forKey: .swell)) ?? .init()
    }
}

// MARK: - A. Strike Cascade

struct StrikeCascadeTuning: Codable, Equatable, Sendable {
    var pressScale = 0.88
    var checkboxSpring = SpringSpec(0.42, bounce: 0.50)
    var fillSpring = SpringSpec(0.25, bounce: 0.0)

    var checkPunch = 1.15
    var checkSpring = SpringSpec(0.30, bounce: 0.10, delay: 0.04)
    var checkWeight = 2.0

    /// Bounce is what produces the pen's follow-through past the last glyph. Deliberately
    /// not a hand-authored overshoot — a spring already does it, and does it physically.
    var strikeSpring = SpringSpec(0.45, bounce: 0.28, delay: 0.09)
    var strikeWeight = 1.5
    var strikeTrailing = 2.0

    var greyOpacity = 0.5
    var dueTravel = 7.0
    var dueOutSpring = SpringSpec(0.22, bounce: 0.0, delay: 0.22)
    var dueInSpring = SpringSpec(0.40, bounce: 0.42, delay: 0.25)

    var cardSettleScale = 0.985
    var cardSpring = SpringSpec(0.50, bounce: 0.30)
}

// MARK: - B. Stamp

struct StampTuning: Codable, Equatable, Sendable {
    var pressScale = 0.955
    var pressSpring = SpringSpec(0.14, bounce: 0.0)

    var reboundSpring = SpringSpec(0.55, bounce: 0.60, delay: 0.14)

    var fillSpring = SpringSpec(0.28, bounce: 0.0, delay: 0.15)
    var pressBrightness = -0.04
    var shadowCollapse = 0.9

    var checkPunch = 1.6
    var checkSpring = SpringSpec(0.38, bounce: 0.45, delay: 0.15)
    var checkWeight = 2.0

    /// No sweep: the line arrives at full width and expands from a hairline, the way ink
    /// spreads under pressure. A stamp hits everything at once.
    var strikeSpring = SpringSpec(0.30, bounce: 0.50, delay: 0.165)
    var strikeWeight = 1.5
    var titleSpring = SpringSpec(0.30, bounce: 0.0, delay: 0.165)
    var greyOpacity = 0.5

    var dueTravel = 12.0
    var dueSpring = SpringSpec(0.45, bounce: 0.35, delay: 0.20)

    var cardSpring = SpringSpec(0.50, bounce: 0.30)
}

// MARK: - C. Liquid Metal

struct LiquidMetalTuning: Codable, Equatable, Sendable {
    var bandSpring = SpringSpec(0.62, bounce: 0.12)
    /// The light runs on its own, slower, springier clock so the highlight lags and
    /// overshoots the band. Light with inertia is the whole illusion.
    var lightSpring = SpringSpec(0.85, bounce: 0.35)
    var lightAngleStart = 0.4
    var lightAngleEnd = 2.7

    var bandWidth = 0.30
    var bandSoftness = 1.6
    var bandTilt = 0.26
    var metalness = 0.95
    var roughness = 0.35
    var heightScale = 14.0
    var refraction = 2.6

    var fillSpring = SpringSpec(0.30, bounce: 0.0, delay: 0.10)
    var checkSpring = SpringSpec(0.34, bounce: 0.15, delay: 0.06)
    var checkWeight = 2.2
    var strikeWeight = 1.5
    var greyOpacity = 0.5

    var dueTravel = 7.0
    var dueSpring = SpringSpec(0.42, bounce: 0.38, delay: 0.28)

    var cardSpring = SpringSpec(0.50, bounce: 0.25)
    var pressScale = 0.985
}

// MARK: - D. Settle & Recede

struct SettleRecedeTuning: Codable, Equatable, Sendable {
    var tipAngle = -9.0
    var tipSpring = SpringSpec(0.30, bounce: 0.15)
    var returnSpring = SpringSpec(0.55, bounce: 0.45, delay: 0.20)
    var perspective = 0.6

    var shadowLag = 0.035
    var shadowRestRadius = 8.0
    var shadowTipRadius = 18.0
    var shadowRestY = 4.0
    var shadowTipY = 10.0

    var tipBrightness = -0.06
    var brightnessSpring = SpringSpec(0.40, bounce: 0.0, delay: 0.12)

    var fillSpring = SpringSpec(0.28, bounce: 0.0, delay: 0.19)
    var checkSpring = SpringSpec(0.26, bounce: 0.10, delay: 0.19)
    var checkWeight = 2.0
    var strikeSpring = SpringSpec(0.40, bounce: 0.20, delay: 0.21)
    var strikeWeight = 1.5
    var greyOpacity = 0.5

    var dueBlur = 3.0
    var dueSpring = SpringSpec(0.38, bounce: 0.30, delay: 0.26)

    /// The completed row ends lower in the stack. Completion expressed spatially.
    var restScale = 0.985
    var restOpacity = 0.72
    var restShadowRadius = 6.0
    var restSpring = SpringSpec(0.50, bounce: 0.20, delay: 0.38)
}

// MARK: - E. Swell

struct SwellTuning: Codable, Equatable, Sendable {
    var amplitude = 4.0
    var wavelength = 500.0
    var speed = 620.0
    var decay = 4.5
    /// Seconds the packet takes to reach full amplitude behind the front.
    var frontSoftness = 0.09
    var edgeGain = 0.45
    var crestHighlight = 0.06
    var waveDuration = 0.95
    var originNudgeX = 0.0
    var originNudgeY = 0.0

    var checkboxPulse = 1.06
    var checkboxSpring = SpringSpec(0.40, bounce: 0.45)
    var fillSpring = SpringSpec(0.26, bounce: 0.0)
    var checkSpring = SpringSpec(0.34, bounce: 0.10)
    var checkWeight = 2.0

    /// Every delay below is *derived* from distance / speed at runtime, not stored.
    /// These springs only describe how each element behaves once the front reaches it.
    var strikeSpring = SpringSpec(0.42, bounce: 0.22)
    var strikeWeight = 1.5
    var titleSpring = SpringSpec(0.34, bounce: 0.0)
    var greyOpacity = 0.5

    var dueTravel = 6.0
    var dueSpring = SpringSpec(0.38, bounce: 0.35)

    var assigneePulse = 1.08
    var assigneeSpring = SpringSpec(0.36, bounce: 0.45)

    var cardSpring = SpringSpec(0.50, bounce: 0.25)
    var pressScale = 0.99
}
