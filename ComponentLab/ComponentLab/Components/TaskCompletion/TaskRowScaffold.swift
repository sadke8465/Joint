import SwiftUI

// MARK: - Layout scaffold

/// The layout every style shares, so the styles themselves only ever express motion.
struct TaskRowScaffold<Checkbox: View, Detail: View, Assignee: View>: View {
    @ViewBuilder var checkbox: Checkbox
    @ViewBuilder var detail: Detail
    @ViewBuilder var assignee: Assignee

    var body: some View {
        HStack(alignment: .top, spacing: TaskLabMetrics.outerSpacing) {
            HStack(alignment: .top, spacing: TaskLabMetrics.contentSpacing) {
                checkbox

                VStack(alignment: .leading, spacing: TaskLabMetrics.detailSpacing) {
                    detail
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 0)

            assignee
        }
        .padding(TaskLabMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Card background, border and shadow. Split out because Settle & Recede animates the
/// shadow independently of everything else — light is that style's whole storyteller.
struct CardChrome: ViewModifier {
    var shadowRadius: Double = 4
    var shadowY: Double = 2
    var shadowOpacity: Double = 0.05

    func body(content: Content) -> some View {
        content
            .background(
                TaskLabPalette.surface,
                in: RoundedRectangle(cornerRadius: TaskLabMetrics.cardCornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TaskLabMetrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(TaskLabPalette.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
    }
}

// MARK: - Checkbox

struct CompletionCheckbox: View {
    var isCompleted: Bool
    var fillSpec: SpringSpec
    var checkSpec: SpringSpec
    var context: MotionContext
    var lineWidth: Double
    var checkPunch: Double = 1.15
    /// Liquid Metal carves the checkmark out of the fill so the shader's alpha-heightfield
    /// bevels it. The emboss then comes free from the lighting rather than being painted.
    var punchedOut: Bool = false

    /// Rule 2: bounce belongs on the transform, never on the path trim. The scale spring is
    /// derived from the trim spring so one slider drives both without breaking the rule.
    private var scaleSpec: SpringSpec {
        SpringSpec(checkSpec.duration, bounce: min(0.7, checkSpec.bounce + 0.3), delay: checkSpec.delay)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? TaskLabPalette.ink : TaskLabPalette.incompleteBackground)
                .overlay {
                    Circle()
                        .strokeBorder(TaskLabPalette.border, lineWidth: 1)
                        .opacity(isCompleted ? 0 : 1)
                }
                .animation(fillSpec.resolved(context), value: isCompleted)

            checkmark
        }
        .frame(width: TaskLabMetrics.completionSize, height: TaskLabMetrics.completionSize)
        .compositingGroup()
    }

    @ViewBuilder
    private var checkmark: some View {
        let mark = DrawnCheckmark(
            progress: isCompleted ? 1 : 0,
            lineWidth: lineWidth,
            color: .white
        )
        .frame(width: 15, height: 15)
        .animation(checkSpec.resolved(context), value: isCompleted)
        .scaleEffect(isCompleted ? 1 : checkPunch)
        .animation(scaleSpec.resolved(context), value: isCompleted)

        if punchedOut {
            mark.blendMode(.destinationOut)
        } else {
            mark
        }
    }
}

// MARK: - Press

/// Touch-down is where the impulse actually starts, so it gets its own state rather than
/// being folded into the completion toggle. Commit fires on release.
struct PressableRow: ViewModifier {
    @Binding var isPressed: Bool
    var onCommit: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { value in
                        isPressed = false
                        let travel = hypot(value.translation.width, value.translation.height)
                        if travel < 20 { onCommit() }
                    }
            )
    }
}

extension View {
    func pressable(isPressed: Binding<Bool>, onCommit: @escaping () -> Void) -> some View {
        modifier(PressableRow(isPressed: isPressed, onCommit: onCommit))
    }

    func cardChrome(shadowRadius: Double = 4, shadowY: Double = 2, shadowOpacity: Double = 0.05) -> some View {
        modifier(CardChrome(shadowRadius: shadowRadius, shadowY: shadowY, shadowOpacity: shadowOpacity))
    }
}
