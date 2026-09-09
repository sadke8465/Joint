import SwiftUI

/// D — Settle & Recede.
///
/// Protagonist: depth and shadow. Metaphor: the card tipping back and being filed away.
/// Colour barely does any work — the item greys because it moved away from the light.
///
/// The tip is bound to touch-down and the return to release, so "tip, latch, return" is a
/// real gesture rather than a scripted three-beat. That keeps it interruptible, and the
/// small overshoot on the way back is the return spring's bounce rather than a keyframe.
///
/// The row comes to rest at a *lower elevation* than its neighbours: completion expressed
/// spatially. In a list this chains straight into a reorder.
struct SettleRecedeRow: View {
    var item: TaskItemContent
    var isCompleted: Bool
    var tuning: SettleRecedeTuning
    var context: MotionContext
    var onCommit: () -> Void

    /// Owned by the lab so Replay can simulate a real touch-down/release, which the
    /// gesture-driven styles (Stamp, Settle & Recede) depend on entirely.
    @Binding var isPressed: Bool

    /// Rule 3: light has to trail geometry, or the card looks weightless.
    private var shadowSpec: SpringSpec {
        let base = isPressed ? tuning.tipSpring : tuning.returnSpring
        return SpringSpec(base.duration, bounce: base.bounce, delay: base.delay + tuning.shadowLag)
    }

    private var shadowRadius: Double {
        if isPressed { return tuning.shadowTipRadius }
        return isCompleted ? tuning.restShadowRadius : tuning.shadowRestRadius
    }

    private var shadowY: Double {
        isPressed ? tuning.shadowTipY : tuning.shadowRestY
    }

    var body: some View {
        TaskRowScaffold {
            CompletionCheckbox(
                isCompleted: isCompleted,
                fillSpec: tuning.fillSpring,
                checkSpec: tuning.checkSpring,
                context: context,
                lineWidth: tuning.checkWeight
            )
        } detail: {
            StrikableTitle(
                text: item.title,
                strikeFraction: isCompleted ? 1 : 0,
                greyFraction: isCompleted ? 1 : 0,
                strikeWeight: tuning.strikeWeight,
                greyOpacity: tuning.greyOpacity,
                strikeAnimation: tuning.strikeSpring.resolved(context),
                greyAnimation: tuning.strikeSpring.resolved(context)
            )

            DueDateSwap(
                dueText: item.dueText,
                isCompleted: isCompleted,
                travel: 0,
                blur: tuning.dueBlur * context.motionScale,
                outAnimation: tuning.dueSpring.resolved(context),
                inAnimation: tuning.dueSpring.resolved(context)
            )
        } assignee: {
            AssigneeCluster(name: item.assignee, indicators: item.assigneeIndicators)
        }
        .cardChrome(shadowRadius: shadowRadius, shadowY: shadowY)
        .animation(shadowSpec.resolved(context), value: isPressed)
        .animation(shadowSpec.resolved(context), value: isCompleted)
        .brightness(isPressed ? tuning.tipBrightness * context.motionScale : 0)
        .animation(tuning.brightnessSpring.resolved(context), value: isPressed)
        .rotation3DEffect(
            .degrees(isPressed ? tuning.tipAngle * context.motionScale : 0),
            axis: (x: 1, y: 0, z: 0),
            anchor: .bottom,
            perspective: tuning.perspective
        )
        .animation(
            isPressed ? tuning.tipSpring.resolved(context) : tuning.returnSpring.resolved(context),
            value: isPressed
        )
        .scaleEffect(isCompleted ? 1 - (1 - tuning.restScale) * context.motionScale : 1)
        .opacity(isCompleted ? tuning.restOpacity : 1)
        .animation(tuning.restSpring.resolved(context), value: isCompleted)
        .pressable(isPressed: $isPressed, onCommit: onCommit)
    }
}
