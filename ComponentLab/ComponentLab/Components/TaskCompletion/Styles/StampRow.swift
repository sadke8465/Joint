import SwiftUI

/// B — Stamp.
///
/// Protagonist: the whole card. Metaphor: a rubber stamp. Energy is on Z, not X — the
/// deliberate opposite of Strike Cascade, with zero horizontal sweep.
///
/// Everything happens on the *rebound*: the release of stored energy, not the press.
/// The press is driven by touch-down and the rebound by release, so the compression is
/// literally as long as the finger is down. Both the 0.955 dip and the 1.025 overshoot
/// are emergent — the press spring has no bounce, the rebound spring has a lot.
struct StampRow: View {
    var item: TaskItemContent
    var isCompleted: Bool
    var tuning: StampTuning
    var context: MotionContext
    var onCommit: () -> Void
    var strikeSweeps = false

    /// Owned by the lab so Replay can simulate a real touch-down/release, which the
    /// gesture-driven styles (Stamp, Settle & Recede) depend on entirely.
    @Binding var isPressed: Bool

    private var pressed: Double { isPressed ? context.motionScale : 0 }

    var body: some View {
        TaskRowScaffold {
            CompletionCheckbox(
                isCompleted: isCompleted,
                fillSpec: tuning.fillSpring,
                checkSpec: tuning.checkSpring,
                context: context,
                lineWidth: tuning.checkWeight,
                checkPunch: tuning.checkPunch
            )
        } detail: {
            // Stamp's own line opens from a hairline in Y — a stamp hits everything at once.
            // Sweeping instead makes the line read as a pen crossing the title, which is why
            // the grey stays uniform either way: only the line's mechanic changes.
            StrikableTitle(
                text: item.title,
                strikeFraction: strikeSweeps ? (isCompleted ? 1 : 0) : 1,
                greyFraction: isCompleted ? 1 : 0,
                strikeScaleY: strikeSweeps ? 1 : (isCompleted ? 1 : 0),
                strikeWeight: tuning.strikeWeight,
                greyOpacity: tuning.greyOpacity,
                strikeAnimation: tuning.strikeSpring.resolved(context),
                greyAnimation: tuning.titleSpring.resolved(context)
            )

            DueDateSwap(
                dueText: item.dueText,
                isCompleted: isCompleted,
                travel: tuning.dueTravel * context.motionScale,
                outAnimation: tuning.dueSpring.resolved(context),
                inAnimation: tuning.dueSpring.resolved(context)
            )
        } assignee: {
            AssigneeCluster(name: item.assignee, indicators: item.assigneeIndicators)
        }
        // Shadow collapses toward the surface as the card is pushed into it.
        .cardChrome(
            shadowRadius: 4 - 4 * tuning.shadowCollapse * pressed,
            shadowY: 2 - 2 * tuning.shadowCollapse * pressed
        )
        .brightness(tuning.pressBrightness * pressed)
        .scaleEffect(isPressed ? 1 - (1 - tuning.pressScale) * context.motionScale : 1)
        // Down is fast and dead; up is slow and springy. One property, two characters.
        .animation(
            isPressed
                ? tuning.pressSpring.resolved(context)
                : tuning.reboundSpring.resolved(context),
            value: isPressed
        )
        .pressable(isPressed: $isPressed, onCommit: onCommit)
    }
}
