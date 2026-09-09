import SwiftUI

// MARK: - Root

struct MoveDownTuning: Codable, Equatable, Sendable {
    var handoff = HandoffTuning()
    var closeRanks = CloseRanksTuning()
    var drop = DropTuning()
    var slot = SlotTuning()
    var undertow = UndertowTuning()
    var vault = VaultTuning()

    init() {}

    /// Same lenient decoding as the completion tuning: adding one knob should cost one
    /// group, not the whole saved preset.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        handoff = (try? container.decode(HandoffTuning.self, forKey: .handoff)) ?? .init()
        closeRanks = (try? container.decode(CloseRanksTuning.self, forKey: .closeRanks)) ?? .init()
        drop = (try? container.decode(DropTuning.self, forKey: .drop)) ?? .init()
        slot = (try? container.decode(SlotTuning.self, forKey: .slot)) ?? .init()
        undertow = (try? container.decode(UndertowTuning.self, forKey: .undertow)) ?? .init()
        vault = (try? container.decode(VaultTuning.self, forKey: .vault)) ?? .init()
    }
}

// MARK: - Handoff

/// When the reorder starts, per completion style. Starting at t=0 makes the strike
/// unreadable; waiting for the full settle costs 1.1s of dead air. The right moment is the
/// end of the completion's propagation beat — the settle then happens during travel.
struct HandoffTuning: Codable, Equatable, Sendable {
    var strikeCascade = 0.28
    var stamp = 0.20
    var liquidMetal = 0.46
    var settleRecede = 0.30
    /// Swell's is nominal only — it is normally derived from the wavefront reaching the
    /// card's trailing edge, which is the whole point of that style.
    var swell = 0.53
    var swellIsDerived = true

    func delay(for style: TaskCompletionStyle) -> Double {
        switch style {
        case .strikeCascade: strikeCascade
        case .stamp: stamp
        case .liquidMetal: liquidMetal
        case .settleRecede: settleRecede
        case .swell: swell
        }
    }
}

// MARK: - 1. Close Ranks (subtle)

struct CloseRanksTuning: Codable, Equatable, Sendable {
    /// The mover is deliberately slower than the rows closing above it. That single speed
    /// differential is the entire effect: the list flows around a row that is settling,
    /// rather than a row shoving through a list.
    var moverSpring = SpringSpec(0.52, bounce: 0.08)
    var displacedSpring = SpringSpec(0.38, bounce: 0.14)
    var displacedStagger = 0.025
}

// MARK: - 2. Drop (physical)

struct DropTuning: Codable, Equatable, Sendable {
    var unlatch = 0.08
    var unlatchRise = 3.0
    var unlatchScale = 1.02
    var liftShadowRadius = 12.0
    var liftShadowOpacity = 0.14

    /// Zero bounce reads as weight. A bouncy fall reads as a spring, not as gravity.
    var fallSpring = SpringSpec(0.34, bounce: 0.0)

    /// Impact: overshoot comes from the settle spring's bounce, the squash is explicit.
    var squashY = 0.96
    var squashX = 1.012
    var impactSpring = SpringSpec(0.09, bounce: 0.0)
    var settleSpring = SpringSpec(0.30, bounce: 0.50)

    /// Displaced rows are shoved *as the mover crosses them*, not on a fixed stagger.
    /// Fixed stagger reads as choreography; crossing-keyed reads as contact.
    var shove = 2.5
    var shoveSpring = SpringSpec(0.30, bounce: 0.25)
}

// MARK: - 3. Slot (mechanical)

struct SlotTuning: Codable, Equatable, Sendable {
    var liftScale = 1.03
    var liftSpring = SpringSpec(0.12, bounce: 0.0)
    var liftShadowRadius = 14.0
    var liftShadowOpacity = 0.16

    var travelSpring = SpringSpec(0.30, bounce: 0.10)

    /// The list closes *after* the row has visibly left it. Without this delay the lift and
    /// the close happen together and the row never reads as a separate object.
    var gapDelay = 0.06
    var gapSpring = SpringSpec(0.30, bounce: 0.10)

    /// Short and bouncy: a detent, not a landing.
    var seatSpring = SpringSpec(0.26, bounce: 0.45)
    var flushSpring = SpringSpec(0.22, bounce: 0.20)
}

// MARK: - 4. Undertow (depth)

struct UndertowTuning: Codable, Equatable, Sendable {
    var submergeScale = 0.94
    var submergeOpacity = 0.85
    var submergeBlur = 0.5
    var submergeSpring = SpringSpec(0.14, bounce: 0.0)

    var travelSpring = SpringSpec(0.40, bounce: 0.12)

    var surfaceSpring = SpringSpec(0.30, bounce: 0.28)
    /// It surfaces to a *lower* elevation than the incomplete rows. Completion expressed
    /// spatially, the same idea Settle & Recede ends on — which is why they pair.
    var restScale = 0.99

    /// The depth change already explains the reorder, so the neighbours can stay plain.
    /// This is the one style where "the displaced rows do nothing special" is correct.
    var displacedSpring = SpringSpec(0.36, bounce: 0.15)
}

// MARK: - 5. Vault (springs up and over)

struct VaultTuning: Codable, Equatable, Sendable {
    /// How far the move starts *before* the completion has finished settling. 0 is strictly
    /// sequential — completion ends, then it jumps. Positive values pull it earlier.
    var overlap = 0.0

    // Load. A crouch is anticipation, and anticipation is what makes a jump read as a jump
    // rather than as a translation.
    var crouch = 0.09
    var crouchDrop = 2.0
    var crouchScaleY = 0.94
    var crouchScaleX = 1.03

    // The arc. Deliberately small — this is meant to be subtle, and a tall hop in a 60pt row
    // reads as a glitch rather than as play.
    var hopHeight = 14.0
    var lateral = 7.0
    var apexScaleY = 1.03
    var apexScaleX = 0.985
    var arcShadowRadius = 16.0
    var arcShadowOpacity = 0.16
    var launchSpring = SpringSpec(0.28, bounce: 0.18)
    var travelSpring = SpringSpec(0.40, bounce: 0.14)

    // Landing.
    var landSquashY = 0.95
    var landStretchX = 1.015
    var landSpring = SpringSpec(0.11, bounce: 0.0)
    var settleSpring = SpringSpec(0.32, bounce: 0.55)

    // The other rows.
    var staggerBack = 0.045
    var displacedSpring = SpringSpec(0.34, bounce: 0.30)
    /// Each row it passes over ducks very slightly, keyed to the crossing.
    var duck = 1.5
    var duckSpring = SpringSpec(0.26, bounce: 0.30)
}
