import SwiftUI

/// A — Strike Cascade.
///
/// Protagonist: the line. Metaphor: a pen crossing something off. Energy travels
/// left → right, following reading direction.
///
///  t=down  checkbox compresses, card settles                        (the impulse)
///  t=0     fill goes to ink, checkbox springs back past 1.0
///  t=40ms  checkmark draws                                          (the commit)
///  t=90ms  strike sweeps, title greys in the pen's wake             (propagation)
///  t=220ms due date swaps to "Completed"                            (the settle)
///
/// The check leads the strike by 50ms because energy has to originate at the contact
/// point and then travel. Reverse the order and it reads as two unrelated things.
struct StrikeCascadeRow: View {
    var item: TaskItemContent
    var isCompleted: Bool
    var tuning: StrikeCascadeTuning
    var context: MotionContext
    var onCommit: () -> Void

    /// Owned by the lab so Replay can simulate a real touch-down/release, which the
    /// gesture-driven styles (Stamp, Settle & Recede) depend on entirely.
    @Binding var isPressed: Bool

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
            .scaleEffect(isPressed ? tuning.pressScale : 1)
            .animation(tuning.checkboxSpring.resolved(context), value: isPressed)
        } detail: {
            // Strike and grey share one spring *and* one width, so the text greys because
            // the pen passed over it — not alongside it.
            StrikableTitle(
                text: item.title,
                strikeFraction: isCompleted ? 1 : 0,
                greyFraction: isCompleted ? 1 : 0,
                strikeWeight: tuning.strikeWeight,
                strikeTrailing: tuning.strikeTrailing,
                greyOpacity: tuning.greyOpacity,
                strikeAnimation: tuning.strikeSpring.resolved(context),
                greyAnimation: tuning.strikeSpring.resolved(context)
            )

            DueDateSwap(
                dueText: item.dueText,
                isCompleted: isCompleted,
                travel: tuning.dueTravel * context.motionScale,
                outAnimation: tuning.dueOutSpring.resolved(context),
                inAnimation: tuning.dueInSpring.resolved(context)
            )
        } assignee: {
            AssigneeCluster(name: item.assignee, indicators: item.assigneeIndicators)
        }
        .cardChrome()
        .scaleEffect(isPressed ? 1 - (1 - tuning.cardSettleScale) * context.motionScale : 1)
        .animation(tuning.cardSpring.resolved(context), value: isPressed)
        .pressable(isPressed: $isPressed, onCommit: onCommit)
    }
}
