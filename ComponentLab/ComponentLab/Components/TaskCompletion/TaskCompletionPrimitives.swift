import SwiftUI

// MARK: - Checkmark

/// Hand-rolled so the draw-on is a real, tunable animation.
///
/// `.symbolEffect(.drawOn)` is SF Symbols 7 / iOS 26 only and exposes essentially no
/// parameters; `trim(from:to:)` on a Shape gives stroke weight, cap style, draw curve and
/// spring overshoot as first-class knobs, and works at the app's iOS 18 target.
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Proportions matched to SF Symbols' `checkmark` so the static frame is identical.
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.53))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.39, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.24))
        return path
    }
}

/// A checkmark that draws itself on. `progress` is the trim end, so it is animatable by any
/// spring — but keep bounce low here: overshoot on a *path trim* reads as a rendering bug,
/// while overshoot on scale reads as mass. (Rule 2.)
struct DrawnCheckmark: View {
    var progress: Double
    var lineWidth: Double
    var color: Color = .white

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: max(0, min(1, progress)))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Animatable readers
//
// SwiftUI cannot hand you the intermediate value of an animating `@State`. Conforming a
// view to `Animatable` can: SwiftUI interpolates `animatableData` and re-evaluates `body`
// every frame, which is the only way to drive a Metal uniform from a real spring (rather
// than from a linear keyframe) and keep it interruptible.

struct AnimatableReader<Content: View>: View, Animatable {
    var value: Double
    @ViewBuilder var content: (Double) -> Content

    // `Animatable` is a nonisolated protocol while `View` is main-actor isolated under
    // Swift 6, so the requirement has to be spelled nonisolated explicitly.
    nonisolated var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View { content(value) }
}

// MARK: - Shared row pieces

enum TaskLabMetrics {
    static let cardPadding: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12
    static let outerSpacing: CGFloat = 12
    static let contentSpacing: CGFloat = 8
    static let detailSpacing: CGFloat = 2
    static let completionSize: CGFloat = 32
    static let indicatorLabelSpacing: CGFloat = 4
    static let indicatorSize: CGFloat = 8
    static let indicatorOverlap: CGFloat = 4
}

enum TaskLabPalette {
    static let surface = Color.white
    static let border = Color(red: 234 / 255, green: 234 / 255, blue: 234 / 255)
    static let incompleteBackground = Color(red: 246 / 255, green: 246 / 255, blue: 246 / 255)
    static let ink = Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)
    static let secondaryText = ink.opacity(0.5)
    static let cyan = Color(red: 0 / 255, green: 201 / 255, blue: 249 / 255)
    static let pink = Color(red: 255 / 255, green: 0 / 255, blue: 48 / 255)
}

/// The title, its strikethrough, and the grey-out — deliberately one component.
///
/// The grey copy is revealed by a leading-anchored mask whose width *is* the strike line's
/// width. One variable drives both, so the text cannot grey ahead of or behind the pen.
/// Sub-glyph precision, and impossible to desync.
struct StrikableTitle: View {
    var text: String
    /// 0...1 of the measured text width.
    var strikeFraction: Double
    /// Separate from `strikeFraction` so Stamp can grey uniformly while its line grows in Y.
    var greyFraction: Double
    var strikeScaleY: Double = 1
    var strikeWeight: Double
    var strikeTrailing: Double = 0
    /// The completed title lands on exactly the due-date colour: ink at this opacity.
    var greyOpacity: Double
    /// Supplied per layer so Stamp can grey uniformly while its line springs open in Y.
    var strikeAnimation: Animation?
    var greyAnimation: Animation?
    var font: Font = .caption

    @State private var textWidth: CGFloat = 0

    private var strikeWidth: CGFloat {
        max(0, (textWidth + strikeTrailing) * strikeFraction)
    }

    var body: some View {
        // The measured width must come from the text alone. Putting the strike line inside
        // the measured container makes the line's width feed back into the measurement that
        // produces it, and the row grows without bound the moment a strike is drawn — so the
        // line lives in an overlay, which is sized by its parent and cannot affect layout.
        ZStack(alignment: .leading) {
            Text(text)
                .foregroundStyle(TaskLabPalette.ink)

            Text(text)
                .foregroundStyle(TaskLabPalette.ink.opacity(greyOpacity))
                .mask(alignment: .leading) {
                    Rectangle().frame(width: max(0, textWidth * greyFraction))
                }
                .animation(greyAnimation, value: greyFraction)
        }
        .font(font)
        .fixedSize(horizontal: true, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(TaskLabPalette.ink.opacity(greyOpacity))
                .frame(width: strikeWidth, height: strikeWeight)
                .scaleEffect(y: strikeScaleY, anchor: .center)
                .animation(strikeAnimation, value: strikeFraction)
                .animation(strikeAnimation, value: strikeScaleY)
        }
    }
}

/// The due date swapping to "Completed".
///
/// The width change is the single most common place these animations break. A ZStack sizes
/// to its widest child, so the container is stable at max(due, "Completed") and simply
/// cannot pop — the extra width sits against a Spacer and is invisible.
///
/// In and out get separate animations because the old value should leave briskly and the
/// new one should arrive with bounce. One shared spring makes the swap feel like a crossfade.
struct DueDateSwap: View {
    var dueText: String
    var isCompleted: Bool
    var travel: Double
    var blur: Double = 0
    var outAnimation: Animation?
    var inAnimation: Animation?
    var font: Font = .caption

    var body: some View {
        ZStack(alignment: .leading) {
            label(dueText)
                .opacity(isCompleted ? 0 : 1)
                .offset(y: isCompleted ? -travel : 0)
                .blur(radius: isCompleted ? blur : 0)
                .animation(outAnimation, value: isCompleted)

            label("Completed")
                .opacity(isCompleted ? 1 : 0)
                .offset(y: isCompleted ? 0 : travel)
                .blur(radius: isCompleted ? 0 : blur)
                .animation(inAnimation, value: isCompleted)
        }
        .font(font)
        .foregroundStyle(TaskLabPalette.secondaryText)
    }

    private func label(_ value: String) -> some View {
        Text(value).fixedSize(horizontal: true, vertical: false)
    }
}

struct AssigneeCluster: View {
    var name: String
    var indicators: [TaskAssigneeIndicator]
    var pulse: Double = 1

    var body: some View {
        HStack(spacing: TaskLabMetrics.indicatorLabelSpacing) {
            Text(name)
                .font(.caption)
                .foregroundStyle(TaskLabPalette.secondaryText)
                .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: -TaskLabMetrics.indicatorOverlap) {
                ForEach(Array(indicators.enumerated()), id: \.offset) { _, indicator in
                    Circle()
                        .fill(indicator.labColor)
                        .frame(width: TaskLabMetrics.indicatorSize, height: TaskLabMetrics.indicatorSize)
                }
            }
            .scaleEffect(pulse)
            .accessibilityHidden(true)
        }
    }
}

extension TaskAssigneeIndicator {
    var labColor: Color {
        switch self {
        case .cyan: TaskLabPalette.cyan
        case .pink: TaskLabPalette.pink
        }
    }
}
