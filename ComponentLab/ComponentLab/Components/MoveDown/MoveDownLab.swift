import SwiftUI
import UIKit

/// Distinct titles on purpose. Five rows all reading "Do the dishes" makes a reorder
/// impossible to follow, which is the one thing this lab exists to show.
enum MoveDownSamples {
    static let list: [TaskItemContent] = [
        TaskItemContent(id: "dishes", title: "Do the dishes", dueText: "Today",
                        assignee: "Joint", assigneeIndicators: [.pink, .cyan], isCompleted: false),
        TaskItemContent(id: "groceries", title: "Order groceries", dueText: "Today",
                        assignee: "Noam", assigneeIndicators: [.cyan], isCompleted: false),
        TaskItemContent(id: "vet", title: "Book the vet", dueText: "Tomorrow",
                        assignee: "Omer", assigneeIndicators: [.pink], isCompleted: false),
        TaskItemContent(id: "rent", title: "Pay the rent", dueText: "In 3 Days",
                        assignee: "Joint", assigneeIndicators: [.pink, .cyan], isCompleted: false),
        TaskItemContent(id: "flights", title: "Book flights home", dueText: "12.03.2026",
                        assignee: "Noam", assigneeIndicators: [.cyan], isCompleted: false)
    ]
}

@MainActor
struct MoveDownLab: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var items = MoveDownSamples.list
    @State private var pressedId: String?
    @State private var externalCommit: String?

    @State private var moveStyle: MoveDownStyle = .closeRanks
    @State private var completionStyle: TaskCompletionStyle
    @State private var completionTuning: TaskCompletionTuning
    @State private var moveTuning = MoveDownTuning()

    @State private var speed: Double = 1
    @State private var isLooping = false
    @State private var previewReduceMotion = false
    @State private var hapticsEnabled = true
    @State private var isFullscreen = false
    @State private var haptics = CompletionHaptics()
    @State private var loopTask: Task<Void, Never>?
    @State private var showingExport = false
    @State private var listWidth: CGFloat = 340

    @AppStorage("componentlab.moveDownTuning") private var storedTuning = ""

    init() {
        let preset = CompletionPreset.load()
        _completionStyle = State(initialValue: LaunchOptions.style ?? preset?.style ?? .strikeCascade)
        _completionTuning = State(initialValue: preset?.tuning ?? TaskCompletionTuning())
        _moveStyle = State(initialValue: LaunchOptions.moveStyle ?? .closeRanks)
        _speed = State(initialValue: LaunchOptions.speed ?? 1)
    }

    private var reduceMotion: Bool { previewReduceMotion || systemReduceMotion }

    private var context: MotionContext {
        MotionContext(speed: speed, reversing: false, reduceMotion: reduceMotion)
    }

    /// Swell's handoff is derived from the wavefront reaching the card's trailing edge rather
    /// than stored — the same principle that makes that completion style re-time itself when
    /// the layout changes.
    private var completionLength: Double {
        completionStyle.nominalDuration(completionTuning)
    }

    private var handoff: Double {
        // Vault waits for the completion to finish, then jumps. Overlap pulls it earlier;
        // 0 is strictly sequential.
        if moveStyle.startsAfterCompletion {
            return max(0, completionLength - moveTuning.vault.overlap)
        }
        if completionStyle == .swell, moveTuning.handoff.swellIsDerived {
            return Double(listWidth) / max(completionTuning.swell.speed, 1)
        }
        return moveTuning.handoff.delay(for: completionStyle)
    }

    private var travel: Double {
        MoveDownMotion.travelDuration(style: moveStyle, tuning: moveTuning)
    }

    /// The move-down score in its own time base — offsets run from the reorder, not from the
    /// tap, because the reorder no longer happens a fixed distance after any one tap.
    private var moveScore: [HapticEvent] {
        moveStyle.hapticScore(
            travel: travel,
            crouch: moveTuning.vault.crouch,
            stagger: moveTuning.vault.staggerBack
        )
    }

    /// Completion score, then the move-down score shifted to the handoff. One timeline, showing
    /// the lone-tap case — the only one where the two have a fixed relationship.
    private var combinedScore: [HapticEvent] {
        completionStyle.hapticScore + moveScore.map { event -> HapticEvent in
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
        .navigationTitle("Move Down")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) { MoveTuningExportSheet(tuning: $moveTuning) }
        .task {
            loadStoredTuning()
            if LaunchOptions.opensFullscreen { isFullscreen = true }
            if LaunchOptions.autoLoop { isLooping = true }
        }
        .onChange(of: moveTuning) { _, value in persist(value) }
        .onChange(of: isLooping) { _, running in running ? startLoop() : stopLoop() }
        .onDisappear { stopLoop() }
    }

    // MARK: Stage

    private var stage: some View {
        VStack(spacing: 12) {
            if !isFullscreen {
                stylePicker
            }

            ReorderingTaskList(
                items: $items,
                pressedId: $pressedId,
                completionStyle: completionStyle,
                completionTuning: completionTuning,
                moveStyle: moveStyle,
                moveTuning: moveTuning,
                context: context,
                handoff: handoff,
                externalCommit: $externalCommit,
                // The completion belongs to the tap, the landing to the reorder — a burst
                // batches into one move and must feel like one.
                onCommit: { _ in
                    haptics.play(completionStyle.hapticScore, speed: speed, enabled: hapticsEnabled)
                },
                onReorder: {
                    haptics.playAdditional(moveScore, speed: speed, enabled: hapticsEnabled)
                }
            )
            .padding(.horizontal, 16)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { listWidth = $0 - 32 }

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

    private var stylePicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MoveDownStyle.allCases) { candidate in
                    Button {
                        stopLoop()
                        isLooping = false
                        resetList()
                        moveStyle = candidate
                    } label: {
                        VStack(spacing: 0) {
                            Text(candidate.title).font(.caption.weight(.medium))
                            Text(candidate.carrier).font(.caption2).opacity(0.65)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            candidate == moveStyle ? TaskLabPalette.ink : Color(.secondarySystemBackground),
                            in: Capsule()
                        )
                        .foregroundStyle(candidate == moveStyle ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Panel

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
                    Spacer()
                    Button("Reset list", systemImage: "arrow.uturn.backward") { resetList() }
                        .controlSize(.small)
                }

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
                Button("Export tuning…", systemImage: "square.and.arrow.up") { showingExport = true }
                    .controlSize(.small)
            }

            Section("Pairing") {
                Picker("Completion", selection: $completionStyle) {
                    ForEach(TaskCompletionStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .font(.caption)
                .onChange(of: completionStyle) { _, _ in resetList() }

                if completionStyle == .swell {
                    Toggle("Derive handoff from the wavefront", isOn: $moveTuning.handoff.swellIsDerived)
                        .font(.caption)
                }

                if moveStyle.startsAfterCompletion {
                    LabSlider(
                        name: "Timing overlap",
                        unit: "s",
                        decimals: 3,
                        range: -0.2...0.8,
                        value: $moveTuning.vault.overlap
                    )
                } else {
                    LabSlider(
                        name: "Handoff · \(completionStyle.title)",
                        unit: "s",
                        decimals: 3,
                        range: 0...2.5,
                        value: $moveTuning.sub(handoffPath)
                    )
                    .disabled(completionStyle == .swell && moveTuning.handoff.swellIsDerived)
                }

                Text(handoffHint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            ForEach(moveStyle.groups) { group in
                Section(group.name) {
                    ForEach(group.params) { param in
                        LabSlider(
                            name: param.name,
                            unit: param.unit,
                            decimals: param.decimals,
                            range: param.range,
                            value: $moveTuning.sub(param.path)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var handoffPath: WritableKeyPath<MoveDownTuning, Double> {
        switch completionStyle {
        case .strikeCascade: \.handoff.strikeCascade
        case .stamp: \.handoff.stamp
        case .liquidMetal: \.handoff.liquidMetal
        case .settleRecede: \.handoff.settleRecede
        case .swell: \.handoff.swell
        }
    }

    private var handoffHint: String {
        if moveStyle.startsAfterCompletion {
            let length = completionLength.formatted(.number.precision(.fractionLength(2)))
            let start = handoff.formatted(.number.precision(.fractionLength(2)))
            return "\(completionStyle.title) settles at \(length)s; the vault starts at \(start)s. 0 overlap is strictly sequential — negative leaves a gap."
        }
        if completionStyle == .swell, moveTuning.handoff.swellIsDerived {
            return "Derived: \(handoff.formatted(.number.precision(.fractionLength(3))))s — card width ÷ wave speed."
        }
        return "A quiet window, not a per-row delay: each tap restarts it, and everything touched files together when it closes. Too early and the strike is unreadable; too late and there is dead air."
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
        withAnimation(.spring(duration: 0.3)) {
            items = MoveDownSamples.list
        }
    }

    private func nextTarget() -> String? {
        items.first(where: { !$0.isCompleted })?.id
    }

    private func performPress(on id: String) async {
        pressedId = id
        try? await Task.sleep(for: .seconds(0.12 / max(speed, 0.05)))
        pressedId = nil
        externalCommit = id
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

    private func persist(_ value: MoveDownTuning) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storedTuning = String(decoding: data, as: UTF8.self)
    }

    private func loadStoredTuning() {
        guard !storedTuning.isEmpty,
              let decoded = try? JSONDecoder().decode(MoveDownTuning.self, from: Data(storedTuning.utf8))
        else { return }
        moveTuning = decoded
    }
}

private struct MoveTuningExportSheet: View {
    @Binding var tuning: MoveDownTuning
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
                    Button("Apply", systemImage: "checkmark") { apply() }
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Move Down Tuning")
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
        guard let data = try? encoder.encode(tuning) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private func apply() {
        do {
            tuning = try JSONDecoder().decode(MoveDownTuning.self, from: Data(text.utf8))
            status = "Applied."
        } catch {
            status = "Could not parse: \(error.localizedDescription)"
        }
    }
}

#Preview("Move Down Lab") {
    NavigationStack { MoveDownLab() }
}
