import SwiftUI

/// Dispatches to a style. Give this an `.id(style)` at the call site so switching styles
/// tears down the previous one's state instead of trying to interpolate between two
/// completely different motion systems.
struct AnimatedTaskItemView: View {
    var item: TaskItemContent
    var style: TaskCompletionStyle
    @Binding var isCompleted: Bool
    @Binding var isPressed: Bool
    var tuning: TaskCompletionTuning
    var context: MotionContext
    var onCommit: () -> Void
    var options = CompletionOptions()

    var body: some View {
        switch style {
        case .strikeCascade:
            StrikeCascadeRow(
                item: item, isCompleted: isCompleted, tuning: tuning.strike,
                context: context, onCommit: onCommit, isPressed: $isPressed
            )
        case .stamp:
            StampRow(
                item: item, isCompleted: isCompleted, tuning: tuning.stamp,
                context: context, onCommit: onCommit,
                strikeSweeps: options.strikeSweepsHorizontally, isPressed: $isPressed
            )
        case .liquidMetal:
            LiquidMetalRow(
                item: item, isCompleted: isCompleted, tuning: tuning.metal,
                context: context, onCommit: onCommit, isPressed: $isPressed
            )
        case .settleRecede:
            SettleRecedeRow(
                item: item, isCompleted: isCompleted, tuning: tuning.recede,
                context: context, onCommit: onCommit, isPressed: $isPressed
            )
        case .swell:
            SwellRow(
                item: item, isCompleted: isCompleted, tuning: tuning.swell,
                context: context, onCommit: onCommit, isPressed: $isPressed
            )
        }
    }
}
