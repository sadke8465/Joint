import SwiftUI
import UIKit

private enum PresetChoice: String, CaseIterable, Identifiable {
    case claude
    case yours

    var id: String { rawValue }
    var title: String { self == .claude ? "Claude's" : "Yours" }
}

@MainActor
struct ClaudeSuggestionLab: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var items = FilterSamples.list
    @State private var pressedId: String?
    @State private var externalCommit: String?

    @State private var preset: PresetChoice = .claude
    @State private var filter: TaskFilter = .all
    @State private var appliedVisible: Set<String> = Set(FilterSamples.list.map(\.id))
    @State private var filterStyle: FilterStyle = ClaudeSuggestion.filterStyle

    @State private var completionTuning = ClaudeSuggestion.completion
    @State private var moveTuning = ClaudeSuggestion.moveDown
    @State private var filterTuning = ClaudeSuggestion.filter

    @State private var speed: Double = 1
    @State private var previewReduceMotion = false
    @State private var hapticsEnabled = true
    @State private var showsSliders = false
    @State private var showsNotes = true
    @State private var isFullscreen = false
    @State private var haptics = CompletionHaptics()
    @State private var leadTask: Task<Void, Never>?
    @State private var scriptTask: Task<Void, Never>?
    @State private var showingExport = false
    @State private var lastScore: [HapticEvent] = []

    private let pitch: Double = 70

    private var reduceMotion: Bool { previewReduceMotion || systemReduceMotion }

    private var context: MotionContext {
        MotionContext(speed: speed, reversing: false, reduceMotion: reduceMotion)
    }

    private var counts: [TaskFilter: Int] {
        Dictionary(uniqueKeysWithValues: TaskFilter.allCases.map { ($0, $0.visibleIds(in: items).count) })
    }

    var body: some View {
        LabShell(isFullscreen: $isFullscreen) {
            stage
        } panel: {
            panel
        }
        .navigationTitle("Claude's Suggestion")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) {
            SuggestionExportSheet(
                completion: completionTuning,
                move: moveTuning,
                filter: filterTuning
            )
        }
        .task {
            if LaunchOptions.opensFullscreen { isFullscreen = true }
            if let launched = LaunchOptions.filterStyle { filterStyle = launched }
            if LaunchOptions.stress { stress() }
            if let target = LaunchOptions.filter {
                try? await Task.sleep(for: .seconds(1.2))
                select(target)
            }
        }
        .onDisappear {
            leadTask?.cancel()
            scriptTask?.cancel()
        }
    }

    // MARK: Stage

    private var stage: some View {
        VStack(spacing: 10) {
            // The preset switch is lab furniture; the pills are the component's own control
            // surface, and a filter you cannot change shows no filtering motion at all.
            if !isFullscreen {
                presetSwitch
            }

            FilterPills(
                selection: $filter,
                counts: counts,
                tuning: filterTuning.shared,
                context: context,
                onSelect: select
            )

            ScrollView {
                ZStack(alignment: .top) {
                    ReorderingTaskList(
                        items: $items,
                        pressedId: $pressedId,
                        completionStyle: ClaudeSuggestion.completionStyle,
                        completionTuning: completionTuning,
                        moveStyle: ClaudeSuggestion.moveStyle,
                        moveTuning: moveTuning,
                        context: context,
                        handoff: moveTuning.handoff.stamp,
                        externalCommit: $externalCommit,
                        onCommit: { _ in
                            haptics.play(
                                ClaudeSuggestion.completionStyle.hapticScore,
                                speed: speed,
                                enabled: hapticsEnabled
                            )
                        },
                        completionOptions: ClaudeSuggestion.options,
                        moverPlaneOverride: ClaudeSuggestion.moverPlane,
                        visible: appliedVisible,
                        filterStyle: filterStyle,
                        filterTuning: filterTuning
                    )

                    if appliedVisible.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: isFullscreen ? nil : 400)
            .scrollIndicators(.hidden)

            if !isFullscreen {
                HapticTimeline(
                    score: lastScore.isEmpty ? ClaudeSuggestion.completionStyle.hapticScore : lastScore,
                    pulses: haptics.pulses,
                    supportsHaptics: haptics.supportsHaptics
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var presetSwitch: some View {
        HStack(spacing: 8) {
            ForEach(PresetChoice.allCases) { candidate in
                Button {
                    apply(candidate)
                } label: {
                    Text(candidate.title)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            candidate == preset ? TaskLabPalette.ink : Color(.secondarySystemBackground),
                            in: Capsule()
                        )
                        .foregroundStyle(candidate == preset ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }

            Text("Stamp · Close Ranks · \(filterStyle.title)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "tray").font(.title3).foregroundStyle(.tertiary)
            Text("Nothing here").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
        .animation(filterTuning.shared.heightSpring.resolved(context), value: appliedVisible.isEmpty)
    }

    // MARK: Panel

    private var panel: some View {
        List {
            Section("Try it") {
                HStack(spacing: 10) {
                    Button("Complete") { completeOne() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Button("Cycle filter") { cycle() }
                        .controlSize(.small)
                    Spacer()
                    Button("Reset") { reset() }
                        .controlSize(.small)
                }

                HStack(spacing: 10) {
                    Button("Interleave") { interleave() }
                        .controlSize(.small)
                    Button("Stress") { stress() }
                        .controlSize(.small)
                    Spacer()
                }

                Text("Interleave completes a row and switches filter 400ms later, while the completion is still animating and its reorder is still pending — the case where all three parts overlap.")
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

                Picker("Filter style", selection: $filterStyle) {
                    ForEach(FilterStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .font(.caption)

                Toggle("Show sliders", isOn: $showsSliders).font(.caption)
                Toggle("Show reasoning", isOn: $showsNotes).font(.caption)

                Button("Export", systemImage: "square.and.arrow.up") { showingExport = true }
                    .controlSize(.small)
            }

            if showsNotes {
                Section("What I changed, and why") {
                    ForEach(ClaudeSuggestion.notes, id: \.0) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.0).font(.caption.weight(.medium))
                            Text(note.1).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if showsSliders {
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

                Section("Move down") {
                    LabSlider(name: "Handoff", unit: "s", decimals: 3, range: 0...3,
                              value: $moveTuning.handoff.stamp)
                    LabSlider(name: "Mover · duration", unit: "s", decimals: 2, range: 0.05...1.2,
                              value: $moveTuning.closeRanks.moverSpring.duration)
                    LabSlider(name: "Mover · bounce", decimals: 2, range: 0...0.8,
                              value: $moveTuning.closeRanks.moverSpring.bounce)
                    LabSlider(name: "Close · duration", unit: "s", decimals: 2, range: 0.05...2,
                              value: $moveTuning.closeRanks.displacedSpring.duration)
                    LabSlider(name: "Close · bounce", decimals: 2, range: 0...0.8,
                              value: $moveTuning.closeRanks.displacedSpring.bounce)
                    LabSlider(name: "Close · stagger", unit: "s", decimals: 3, range: 0...0.2,
                              value: $moveTuning.closeRanks.displacedStagger)
                }

                ForEach(FilterCatalog.shared) { group in
                    Section("Filter · \(group.name)") {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $filterTuning.sub(param.path)
                            )
                        }
                    }
                }

                ForEach(filterStyle.groups) { group in
                    Section("Filter · \(group.name)") {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $filterTuning.sub(param.path)
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

    // MARK: Presets

    private func apply(_ choice: PresetChoice) {
        preset = choice
        switch choice {
        case .claude:
            completionTuning = ClaudeSuggestion.completion
            moveTuning = ClaudeSuggestion.moveDown
            filterTuning = ClaudeSuggestion.filter
            filterStyle = ClaudeSuggestion.filterStyle
        case .yours:
            completionTuning = stored(TaskCompletionTuning.self, "componentlab.finalCompletionTuning")
                ?? CompletionPreset.load()?.tuning ?? FinalPreset.completion
            moveTuning = stored(MoveDownTuning.self, "componentlab.finalMoveTuning") ?? FinalPreset.moveDown
            filterTuning = stored(FilterTuning.self, "componentlab.filterTuning") ?? FilterTuning()
            // You have not settled on a filter style yet, so this is the one that matches
            // Close Ranks' restraint.
            filterStyle = .sift
        }
        reset()
    }

    private func stored<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let text = UserDefaults.standard.string(forKey: key), !text.isEmpty else { return nil }
        return try? JSONDecoder().decode(T.self, from: Data(text.utf8))
    }

    // MARK: Actions

    private func select(_ next: TaskFilter) {
        let target = next.visibleIds(in: items)

        let ordered = items.filter { appliedVisible.contains($0.id) }.map(\.id)
        let leavingDelays = ordered.enumerated()
            .filter { !target.contains($0.element) }
            .map { index, _ in
                FilterMotion.exitDelay(style: filterStyle, tuning: filterTuning, index: index, pitch: pitch)
            }
            .sorted()

        let score = filterStyle.hapticScore(leavingDelays: leavingDelays, tuning: filterTuning)
        lastScore = score
        haptics.playAdditional(score, speed: speed, enabled: hapticsEnabled)

        filter = next
        leadTask?.cancel()
        leadTask = Task { @MainActor in
            let lead = filterTuning.shared.indicatorLead / max(speed, 0.05)
            if lead > 0 { try? await Task.sleep(for: .seconds(lead)) }
            guard !Task.isCancelled else { return }
            appliedVisible = target
        }
    }

    private func cycle() {
        let all = TaskFilter.allCases
        let next = all[(all.firstIndex(of: filter).map { $0 + 1 } ?? 0) % all.count]
        select(next)
    }

    private func tap(_ id: String) async {
        pressedId = id
        try? await Task.sleep(for: .seconds(0.12 / max(speed, 0.05)))
        pressedId = nil
        externalCommit = id
    }

    private func completeOne() {
        guard let target = items.first(where: { appliedVisible.contains($0.id) && !$0.isCompleted }) else { return }
        scriptTask?.cancel()
        scriptTask = Task { await tap(target.id) }
    }

    /// All three parts overlapping: the row is still drawing its checkmark and its reorder is
    /// still pending when the filter changes underneath it.
    private func interleave() {
        scriptTask?.cancel()
        scriptTask = Task { @MainActor in
            guard let target = items.first(where: { appliedVisible.contains($0.id) && !$0.isCompleted }) else { return }
            await tap(target.id)
            try? await Task.sleep(for: .seconds(0.4 / max(speed, 0.05)))
            guard !Task.isCancelled else { return }
            cycle()
        }
    }

    private func stress() {
        scriptTask?.cancel()
        scriptTask = Task { @MainActor in
            items = FilterSamples.list
            appliedVisible = filter.visibleIds(in: items)
            try? await Task.sleep(for: .seconds(0.35))
            for id in ["dishes", "vet", "groceries"] where appliedVisible.contains(id) {
                externalCommit = id
                try? await Task.sleep(for: .seconds(0.13))
            }
        }
    }

    private func reset() {
        leadTask?.cancel()
        scriptTask?.cancel()
        filter = .all
        withAnimation(.spring(duration: 0.3)) {
            items = FilterSamples.list
            appliedVisible = Set(FilterSamples.list.map(\.id))
        }
    }
}

private struct SuggestionExportSheet: View {
    let completion: TaskCompletionTuning
    let move: MoveDownTuning
    let filter: FilterTuning
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
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = text
                    status = "Copied."
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Suggested Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { text = encoded }
        }
    }

    private var encoded: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        func dump<T: Encodable>(_ value: T) -> String {
            (try? encoder.encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "{}"
        }
        return """
        // completion — Stamp, sweeping strike
        \(dump(completion))

        // move down — Close Ranks, mover above
        \(dump(move))

        // filtering — Focus
        \(dump(filter))
        """
    }
}

#Preview("Claude's Suggestion") {
    NavigationStack { ClaudeSuggestionLab() }
}
