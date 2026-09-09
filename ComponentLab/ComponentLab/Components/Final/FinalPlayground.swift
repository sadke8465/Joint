import SwiftUI
import UIKit

/// One pairing, no pickers. The two labs stay exactly as they were; this is where the chosen
/// combination lives, with the sliders tucked away rather than removed.
@MainActor
struct FinalPlayground: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var items = MoveDownSamples.list
    @State private var pressedId: String?
    @State private var externalCommit: String?

    @State private var completionTuning = FinalPreset.completion
    @State private var moveTuning = FinalPreset.moveDown

    @State private var speed: Double = 1
    @State private var isLooping = false
    @State private var previewReduceMotion = false
    @State private var hapticsEnabled = true
    @State private var showsSliders = false
    @State private var isFullscreen = false
    @State private var haptics = CompletionHaptics()
    @State private var loopTask: Task<Void, Never>?
    @State private var showingExport = false

    @AppStorage("componentlab.finalCompletionTuning") private var storedCompletion = ""
    @AppStorage("componentlab.finalMoveTuning") private var storedMove = ""

    init() {
        _speed = State(initialValue: LaunchOptions.speed ?? 1)
    }

    private var reduceMotion: Bool { previewReduceMotion || systemReduceMotion }

    private var context: MotionContext {
        MotionContext(speed: speed, reversing: false, reduceMotion: reduceMotion)
    }

    private var handoff: Double { moveTuning.handoff.stamp }

    private var travel: Double {
        MoveDownMotion.travelDuration(style: FinalPreset.moveStyle, tuning: moveTuning)
    }

    /// The move-down score in its own time base — offsets run from the reorder, not from the
    /// tap, because the reorder no longer happens a fixed distance after any one tap.
    private var moveScore: [HapticEvent] {
        FinalPreset.moveStyle.hapticScore(travel: travel)
    }

    /// Completion score, then the move score shifted to the handoff. One timeline, showing the
    /// lone-tap case — which is the only case where the two have a fixed relationship.
    private var combinedScore: [HapticEvent] {
        FinalPreset.completionStyle.hapticScore + moveScore.map { event -> HapticEvent in
            var shifted = event
            shifted.offset += handoff
            return shifted
        }
    }

    var body: some View {
        LabShell(isFullscreen: $isFullscreen) {
            stage
        } panel: {
            panel
        }
        .navigationTitle("Final-ish")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) {
            FinalExportSheet(completion: $completionTuning, move: $moveTuning)
        }
        .task {
            loadStored()
            if LaunchOptions.opensFullscreen { isFullscreen = true }
            if LaunchOptions.autoLoop { isLooping = true }
            if LaunchOptions.stress { stress() }
        }
        .onChange(of: completionTuning) { _, value in persistCompletion(value) }
        .onChange(of: moveTuning) { _, value in persistMove(value) }
        .onChange(of: isLooping) { _, running in running ? startLoop() : stopLoop() }
        .onDisappear { stopLoop() }
    }

    private var stage: some View {
        VStack(spacing: 12) {
            if !isFullscreen {
                Text("Stamp  ·  Close Ranks")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ReorderingTaskList(
                items: $items,
                pressedId: $pressedId,
                completionStyle: FinalPreset.completionStyle,
                completionTuning: completionTuning,
                moveStyle: FinalPreset.moveStyle,
                moveTuning: moveTuning,
                context: context,
                handoff: handoff,
                externalCommit: $externalCommit,
                // Split deliberately: the completion belongs to the tap, the landing belongs
                // to the reorder. Playing the combined score per tap would fire three landings
                // for a burst that produces one bulk move.
                onCommit: { _ in
                    haptics.play(
                        FinalPreset.completionStyle.hapticScore,
                        speed: speed,
                        enabled: hapticsEnabled
                    )
                },
                onReorder: {
                    haptics.playAdditional(moveScore, speed: speed, enabled: hapticsEnabled)
                },
                completionOptions: FinalPreset.options,
                // Mover rides above: it clears its slot in 0.13s while the neighbours take
                // 1.2s, so it necessarily overlaps rows that have not reflowed yet.
                moverPlaneOverride: 10
            )
            .padding(.horizontal, 16)

            if !isFullscreen {
                HapticTimeline(
                    score: combinedScore,
                    pulses: haptics.pulses,
                    supportsHaptics: haptics.supportsHaptics
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var panel: some View {
        List {
            Section("Transport") {
                HStack(spacing: 12) {
                    Button("Replay", systemImage: "arrow.clockwise") { replay() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Toggle("Loop", isOn: $isLooping)
                        .toggleStyle(.button)
                        .controlSize(.small)
                    Button("Stress", systemImage: "bolt.fill") { stress() }
                        .controlSize(.small)
                    Spacer()
                    Button("Reset list", systemImage: "arrow.uturn.backward") { resetList() }
                        .controlSize(.small)
                }

                Text("Stress taps three rows 130ms apart — well inside the window — so all three restart the timer and file together in one reorder, 1.5s after the last tap.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Speed").font(.caption)
                        Spacer()
                        Text(speedLabel).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Slider(value: $speed, in: 0.1...1.0)
                }

                Toggle("Haptics", isOn: $hapticsEnabled).font(.caption)
                Toggle("Preview Reduce Motion", isOn: $previewReduceMotion)
                    .font(.caption)
                    .disabled(systemReduceMotion)
                Toggle("Show sliders", isOn: $showsSliders).font(.caption)

                HStack {
                    Button("Export", systemImage: "square.and.arrow.up") { showingExport = true }
                        .controlSize(.small)
                    Spacer()
                    Button("Back to preset", systemImage: "arrow.counterclockwise") {
                        completionTuning = FinalPreset.completion
                        moveTuning = FinalPreset.moveDown
                    }
                    .controlSize(.small)
                }
            }

            if showsSliders {
                Section("Handoff") {
                    LabSlider(
                        name: "Quiet window before reorder",
                        unit: "s",
                        decimals: 3,
                        range: 0...3,
                        value: $moveTuning.handoff.stamp
                    )
                }

                ForEach(TaskCompletionStyle.stamp.groups) { group in
                    Section("Completion · \(group.name)") {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $completionTuning.sub(param.path)
                            )
                        }
                    }
                }

                ForEach(MoveDownStyle.closeRanks.groups) { group in
                    Section("Move · \(group.name)") {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $moveTuning.sub(param.path)
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var speedLabel: String {
        let slow = 1 / speed
        return slow < 1.05
            ? "1× real time"
            : "\(speed.formatted(.number.precision(.fractionLength(2))))×  ·  \(slow.formatted(.number.precision(.fractionLength(1))))× slow"
    }

    // MARK: Actions

    private func resetList() {
        stopLoop()
        withAnimation(.spring(duration: 0.3)) { items = MoveDownSamples.list }
    }

    private func nextTarget() -> String? { items.first(where: { !$0.isCompleted })?.id }

    private func performPress(on id: String) async {
        pressedId = id
        try? await Task.sleep(for: .seconds(0.12 / max(speed, 0.05)))
        pressedId = nil
        externalCommit = id
    }

    /// Fires three commits inside the window, each restarting it, so all three collapse into a
    /// single bulk reorder. The final arrangement is a pure function of which rows are settled,
    /// so it must be the same every time regardless of how the taps fell.
    private func stress() {
        stopLoop()
        Task {
            items = MoveDownSamples.list
            try? await Task.sleep(for: .seconds(0.35))
            for id in ["dishes", "vet", "groceries"] {
                externalCommit = id
                try? await Task.sleep(for: .seconds(0.13))
            }
        }
    }

    private func replay() {
        Task {
            if nextTarget() == nil { resetList() }
            guard let target = nextTarget() else { return }
            await performPress(on: target)
        }
    }

    private func startLoop() {
        loopTask?.cancel()
        loopTask = Task {
            while !Task.isCancelled {
                if nextTarget() == nil {
                    try? await Task.sleep(for: .seconds(0.9 / max(speed, 0.05)))
                    guard !Task.isCancelled else { return }
                    items = MoveDownSamples.list
                    try? await Task.sleep(for: .seconds(0.5 / max(speed, 0.05)))
                }
                guard !Task.isCancelled, let target = nextTarget() else { continue }
                await performPress(on: target)
                try? await Task.sleep(for: .seconds((handoff + travel + 0.5) / max(speed, 0.05)))
            }
        }
    }

    private func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
        haptics.cancelPending()
    }

    // MARK: Persistence

    private func persistCompletion(_ value: TaskCompletionTuning) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storedCompletion = String(decoding: data, as: UTF8.self)
    }

    private func persistMove(_ value: MoveDownTuning) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storedMove = String(decoding: data, as: UTF8.self)
    }

    private func loadStored() {
        if !storedCompletion.isEmpty,
           let decoded = try? JSONDecoder().decode(TaskCompletionTuning.self, from: Data(storedCompletion.utf8)) {
            completionTuning = decoded
        }
        if !storedMove.isEmpty,
           let decoded = try? JSONDecoder().decode(MoveDownTuning.self, from: Data(storedMove.utf8)) {
            moveTuning = decoded
        }
    }
}

private struct FinalExportSheet: View {
    @Binding var completion: TaskCompletionTuning
    @Binding var move: MoveDownTuning
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var status = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $text)
                    .font(.system(.caption, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                if !status.isEmpty {
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = text
                        status = "Copied."
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Final Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { text = encoded }
        }
    }

    private var encoded: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let completionText = (try? encoder.encode(completion)).map { String(decoding: $0, as: UTF8.self) } ?? "{}"
        let moveText = (try? encoder.encode(move)).map { String(decoding: $0, as: UTF8.self) } ?? "{}"
        return "// completion\n\(completionText)\n\n// move down\n\(moveText)"
    }
}

#Preview("Final-ish") {
    NavigationStack { FinalPlayground() }
}
