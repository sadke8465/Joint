import SwiftUI

/// Resolves a style + tuning into the concrete springs and decorations a row applies.
/// Kept separate from the views so all four styles can be read side by side.
enum MoveDownMotion {

    // MARK: Position
    //
    // Position is always a plain `.animation(spring, value: slot)`. SwiftUI springs retarget
    // from current velocity, so completing item 2 while item 4 is still travelling retargets
    // both instead of queueing. Nothing here is phased, on purpose.

    static func positionAnimation(
        style: MoveDownStyle,
        tuning: MoveDownTuning,
        role: MoveRole,
        context: MotionContext
    ) -> Animation? {
        guard !context.reduceMotion else {
            return .easeOut(duration: 0.24 / max(context.speed, 0.05))
        }

        switch style {
        case .closeRanks:
            let spec = tuning.closeRanks
            switch role {
            case .mover:
                return spec.moverSpring.resolved(context)
            case let .displaced(_, rank):
                return delayed(
                    spec.displacedSpring,
                    by: spec.displacedStagger * Double(rank),
                    context
                )
            case .idle:
                return spec.displacedSpring.resolved(context)
            }

        case .drop:
            let spec = tuning.drop
            switch role {
            case .mover:
                return delayed(spec.fallSpring, by: spec.unlatch, context)
            case let .displaced(crossing, _):
                // Keyed to when the falling row actually crosses it.
                return delayed(
                    spec.shoveSpring,
                    by: spec.unlatch + crossing * spec.fallSpring.duration,
                    context
                )
            case .idle:
                return spec.shoveSpring.resolved(context)
            }

        case .slot:
            let spec = tuning.slot
            switch role {
            case .mover:
                return delayed(spec.travelSpring, by: spec.liftSpring.duration, context)
            default:
                return delayed(spec.gapSpring, by: spec.gapDelay, context)
            }

        case .undertow:
            let spec = tuning.undertow
            switch role {
            case .mover:
                return delayed(spec.travelSpring, by: spec.submergeSpring.duration, context)
            default:
                return spec.displacedSpring.resolved(context)
            }

        case .vault:
            let spec = tuning.vault
            switch role {
            case .mover:
                return delayed(spec.travelSpring, by: spec.crouch, context)
            case let .displaced(_, rank):
                // They close up only once it has left the ground, one after another.
                return delayed(
                    spec.displacedSpring,
                    by: spec.crouch + spec.staggerBack * Double(rank),
                    context
                )
            case .idle:
                return delayed(spec.displacedSpring, by: spec.crouch, context)
            }
        }
    }

    /// Seconds from the handoff until the mover reaches its slot. Drives the landing haptic
    /// and how long the row keeps its raised (or sunken) plane.
    static func travelDuration(style: MoveDownStyle, tuning: MoveDownTuning) -> Double {
        switch style {
        case .closeRanks: tuning.closeRanks.moverSpring.duration
        case .drop: tuning.drop.unlatch + tuning.drop.fallSpring.duration
        case .slot: tuning.slot.liftSpring.duration + tuning.slot.travelSpring.duration
        case .undertow: tuning.undertow.submergeSpring.duration + tuning.undertow.travelSpring.duration
        case .vault: tuning.vault.crouch + tuning.vault.launchSpring.duration
        }
    }

    /// How long the entire reflow takes — the slower of the mover and the neighbours,
    /// including their stagger. Close Ranks in particular is tuned with a fast mover and slow
    /// neighbours, so using the mover's own travel here would drop it out of its plane while
    /// rows are still sliding underneath it.
    static func reflowDuration(
        style: MoveDownStyle,
        tuning: MoveDownTuning,
        displacedCount: Int
    ) -> Double {
        let steps = Double(max(displacedCount - 1, 0))
        let displaced: Double

        switch style {
        case .closeRanks:
            displaced = tuning.closeRanks.displacedSpring.duration
                + tuning.closeRanks.displacedStagger * steps
        case .drop:
            displaced = tuning.drop.unlatch + tuning.drop.fallSpring.duration
                + tuning.drop.shoveSpring.duration
        case .slot:
            displaced = tuning.slot.gapDelay + tuning.slot.gapSpring.duration
        case .undertow:
            displaced = tuning.undertow.displacedSpring.duration
        case .vault:
            displaced = tuning.vault.crouch + tuning.vault.staggerBack * steps
                + tuning.vault.displacedSpring.duration
        }

        return max(travelDuration(style: style, tuning: tuning), displaced)
    }

    // MARK: Decoration
    //
    // Only the mover decorates. Phases are a one-shot flourish, so restarting on retrigger
    // is the correct behaviour — unlike position, which must retarget.

    static func decoration(
        style: MoveDownStyle,
        tuning: MoveDownTuning,
        phase: MovePhase,
        isCompleted: Bool,
        context: MotionContext
    ) -> RowDecoration {
        guard !context.reduceMotion else { return RowDecoration() }

        switch style {
        case .closeRanks:
            // Nothing. The speed differential between mover and neighbours is the effect.
            return RowDecoration()

        case .drop:
            let spec = tuning.drop
            switch phase {
            case .rest, .settle:
                return RowDecoration()
            case .lift:
                return RowDecoration(
                    scaleX: spec.unlatchScale,
                    scaleY: spec.unlatchScale,
                    extraOffsetY: -spec.unlatchRise,
                    liftShadowRadius: spec.liftShadowRadius,
                    liftShadowOpacity: spec.liftShadowOpacity
                )
            case .travel:
                return RowDecoration(
                    liftShadowRadius: spec.liftShadowRadius * 0.6,
                    liftShadowOpacity: spec.liftShadowOpacity * 0.6
                )
            case .impact:
                return RowDecoration(scaleX: spec.squashX, scaleY: spec.squashY)
            }

        case .slot:
            let spec = tuning.slot
            switch phase {
            case .rest, .settle:
                return RowDecoration()
            case .lift, .travel:
                return RowDecoration(
                    scaleX: spec.liftScale,
                    scaleY: spec.liftScale,
                    liftShadowRadius: spec.liftShadowRadius,
                    liftShadowOpacity: spec.liftShadowOpacity
                )
            case .impact:
                return RowDecoration()
            }

        case .undertow:
            let spec = tuning.undertow
            switch phase {
            case .rest:
                return RowDecoration()
            case .lift, .travel:
                return RowDecoration(
                    scaleX: spec.submergeScale,
                    scaleY: spec.submergeScale,
                    opacity: spec.submergeOpacity,
                    blur: spec.submergeBlur
                )
            case .impact, .settle:
                // Surfaces to a slightly lower elevation than the incomplete rows — but only
                // if it is actually completed, so an un-completed row returns to full size.
                let scale = isCompleted ? spec.restScale : 1
                return RowDecoration(scaleX: scale, scaleY: scale)
            }

        case .vault:
            let spec = tuning.vault
            switch phase {
            case .rest, .settle:
                return RowDecoration()
            case .lift:
                // Crouch. Anticipation is what makes a jump read as a jump.
                return RowDecoration(
                    scaleX: spec.crouchScaleX,
                    scaleY: spec.crouchScaleY,
                    extraOffsetY: spec.crouchDrop
                )
            case .travel:
                // Apex: up, out, and stretched along the direction of travel.
                return RowDecoration(
                    scaleX: spec.apexScaleX,
                    scaleY: spec.apexScaleY,
                    extraOffsetX: spec.lateral,
                    extraOffsetY: -spec.hopHeight,
                    liftShadowRadius: spec.arcShadowRadius,
                    liftShadowOpacity: spec.arcShadowOpacity
                )
            case .impact:
                return RowDecoration(scaleX: spec.landStretchX, scaleY: spec.landSquashY)
            }
        }
    }

    static func phaseAnimation(
        style: MoveDownStyle,
        tuning: MoveDownTuning,
        phase: MovePhase,
        context: MotionContext
    ) -> Animation? {
        guard !context.reduceMotion else { return nil }

        switch style {
        case .closeRanks:
            return SpringSpec(0.2).resolved(context)

        case .drop:
            let spec = tuning.drop
            switch phase {
            case .rest: return nil
            case .lift: return SpringSpec(spec.unlatch).resolved(context)
            case .travel: return spec.fallSpring.resolved(context)
            case .impact: return spec.impactSpring.resolved(context)
            case .settle: return spec.settleSpring.resolved(context)
            }

        case .slot:
            let spec = tuning.slot
            switch phase {
            case .rest: return nil
            case .lift: return spec.liftSpring.resolved(context)
            case .travel: return spec.travelSpring.resolved(context)
            case .impact: return spec.seatSpring.resolved(context)
            case .settle: return spec.flushSpring.resolved(context)
            }

        case .undertow:
            let spec = tuning.undertow
            switch phase {
            case .rest: return nil
            case .lift: return spec.submergeSpring.resolved(context)
            case .travel: return spec.travelSpring.resolved(context)
            case .impact, .settle: return spec.surfaceSpring.resolved(context)
            }

        case .vault:
            let spec = tuning.vault
            switch phase {
            case .rest: return nil
            case .lift: return SpringSpec(spec.crouch).resolved(context)
            case .travel: return spec.launchSpring.resolved(context)
            case .impact: return spec.landSpring.resolved(context)
            case .settle: return spec.settleSpring.resolved(context)
            }
        }
    }

    // MARK: Shove
    //
    // Drop is the only style where the displaced rows are disturbed by contact rather than
    // by schedule. Returns the amount and when it lands.

    static func shove(
        style: MoveDownStyle,
        tuning: MoveDownTuning,
        role: MoveRole,
        context: MotionContext
    ) -> (amount: Double, animation: Animation?)? {
        guard !context.reduceMotion else { return nil }
        guard case let .displaced(crossing, _) = role else { return nil }

        switch style {
        case .drop:
            let spec = tuning.drop
            let delay = spec.unlatch + crossing * spec.fallSpring.duration
            return (spec.shove, delayed(spec.shoveSpring, by: delay, context))
        case .vault:
            // Each row ducks very slightly as it is jumped over.
            let spec = tuning.vault
            let delay = spec.crouch + crossing * spec.launchSpring.duration
            return (spec.duck, delayed(spec.duckSpring, by: delay, context))
        default:
            return nil
        }
    }

    // MARK: Helpers

    private static func delayed(_ spec: SpringSpec, by delay: Double, _ context: MotionContext) -> Animation {
        var adjusted = spec
        adjusted.delay = delay
        return adjusted.resolved(context)
    }
}
