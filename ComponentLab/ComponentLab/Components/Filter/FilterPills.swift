import SwiftUI

/// One indicator that travels between pills via `matchedGeometryEffect`, rather than four
/// backgrounds cross-fading. A shared element is what makes a row of pills read as a single
/// control instead of four buttons — and it gives the filter a visible causal origin, the way
/// the checkbox is the origin for a completion.
struct FilterPills: View {
    @Binding var selection: TaskFilter
    var counts: [TaskFilter: Int]
    var tuning: SharedFilterTuning
    var context: MotionContext
    var onSelect: (TaskFilter) -> Void

    @Namespace private var indicator
    @State private var pressed: TaskFilter?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TaskFilter.allCases) { filter in
                pill(filter)
            }
        }
        .animation(tuning.indicatorSpring.resolved(context), value: selection)
    }

    @ViewBuilder
    private func pill(_ filter: TaskFilter) -> some View {
        let isSelected = filter == selection

        HStack(spacing: 5) {
            Text(filter.title)
                .font(.caption.weight(.medium))
            Text("\(counts[filter] ?? 0)")
                .font(.caption2.monospacedDigit())
                .opacity(0.55)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                Capsule()
                    .fill(TaskLabPalette.ink)
                    .matchedGeometryEffect(id: "filterIndicator", in: indicator)
            } else {
                Capsule().fill(Color(.secondarySystemBackground))
            }
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .scaleEffect(pressed == filter ? tuning.pillPress : 1)
        .animation(tuning.pillSpring.resolved(context), value: pressed)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if pressed != filter { pressed = filter } }
                .onEnded { value in
                    pressed = nil
                    let travel = hypot(value.translation.width, value.translation.height)
                    if travel < 20 { onSelect(filter) }
                }
        )
    }
}
