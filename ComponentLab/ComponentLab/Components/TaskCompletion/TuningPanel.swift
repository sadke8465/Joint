import SwiftUI

extension Binding {
    /// Bind through a stored key path. `$tuning.strike.duration` only works for key paths
    /// written inline; the catalog stores them, so it needs this.
    func sub<T>(_ keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        Binding<T>(
            get: { wrappedValue[keyPath: keyPath] },
            set: { wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

struct TuningPanel: View {
    @Binding var tuning: TaskCompletionTuning
    var groups: [TuningGroup]

    var body: some View {
        ForEach(groups) { group in
            Section(group.name) {
                ForEach(group.params) { param in
                    ParamSlider(value: $tuning.sub(param.path), param: param)
                }
            }
        }
    }
}

struct ParamSlider: View {
    @Binding var value: Double
    let param: TuningParam

    var body: some View {
        LabSlider(
            name: param.name,
            unit: param.unit,
            decimals: param.decimals,
            range: param.range,
            value: $value
        )
    }
}

/// Shared by both labs.
struct LabSlider: View {
    let name: String
    var unit: String = ""
    var decimals: Int = 2
    let range: ClosedRange<Double>
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name).font(.caption)
                Spacer()
                Text(formatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
        .padding(.vertical, 2)
    }

    private var formatted: String {
        let number = value.formatted(.number.precision(.fractionLength(decimals)))
        return unit.isEmpty ? number : "\(number) \(unit)"
    }
}

// MARK: - Haptic timeline

/// Haptics do not play on a simulator, so the score is drawn instead. Ticks flash as their
/// events fire, which makes the timing inspectable without a device.
struct HapticTimeline: View {
    var score: [HapticEvent]
    var pulses: [CompletionHaptics.Pulse]
    var supportsHaptics: Bool

    private var span: Double {
        max(score.map(\.offset).max() ?? 0.5, 0.3) + 0.15
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: supportsHaptics ? "iphone.gen3.radiowaves.left.and.right" : "iphone.gen3.slash")
                        .font(.caption2)
                    Text(supportsHaptics ? "Haptic score" : "Haptic score · simulator, not played")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 3)

                        ForEach(score) { event in
                            let fired = isLit(event, now: timeline.date)
                            Circle()
                                .fill(fired ? TaskLabPalette.cyan : Color.secondary.opacity(0.45))
                                .frame(width: fired ? 11 : 7, height: fired ? 11 : 7)
                                .offset(x: proxy.size.width * (event.offset / span))
                                .animation(.spring(duration: 0.25, bounce: 0.4), value: fired)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 14)

                Text(score.map(\.label).joined(separator: "   ·   "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func isLit(_ event: HapticEvent, now: Date) -> Bool {
        pulses.contains { $0.label == event.label && now.timeIntervalSince($0.firedAt) < 0.45 }
    }
}
