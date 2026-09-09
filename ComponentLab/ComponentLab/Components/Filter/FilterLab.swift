import SwiftUI
import UIKit

@MainActor
struct FilterLab: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var items = FilterSamples.list
    @State private var pressedId: String?
    @State private var externalCommit: String?

    @State private var filter: TaskFilter = .all
    /// Applied a beat after `filter`, so the pill indicator visibly leads the list.
    @State private var appliedVisible: Set<String> = Set(FilterSamples.list.map(\.id))
    @State private var filterStyle: FilterStyle = .sift
    @State private var filterTuning = FilterTuning()
    @State private var forceEmpty = false

    @State private var completionTuning = FinalPreset.completion
    @State private var moveTuning = FinalPreset.moveDown

    @State private var speed: Double = 1
    @State private var previewReduceMotion = false
    @State private var hapticsEnabled = true
    @State private var showsSliders = false
    @State private var isFullscreen = false
    @State private var haptics = CompletionHaptics()
    @State private var leadTask: Task<Void, Never>?
    @State private var showingExport = false
    @State private var lastScore: [HapticEvent] = []

    @AppStorage("componentlab.filterTuning") private var storedTuning = ""

    /// Matches the row pitch the list uses, so derived wave timing lines up with what is drawn.
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
        .navigationTitle("Filtering")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) { FilterExportSheet(tuning: $filterTuning) }
        .task {
            loadStored()
            if LaunchOptions.opensFullscreen { isFullscreen = true }
            if let launched = LaunchOptions.filterStyle { filterStyle = launched }
            if let target = LaunchOptions.filter {
                // Deliberately after a beat, so the transition actually animates rather than
                // the list simply starting in its filtered state.
                try? await Task.sleep(for: .seconds(1.2))
                select(target)
            }
        }
        .onChange(of: filterTuning) { _, value in persist(value) }
        .onDisappear { leadTask?.cancel() }
    }

    // MARK: Stage

    private var stage: some View {
        VStack(spacing: 10) {
            // The style chips are lab furniture; the pills are the component's own control
            // surface, and a filter you cannot change shows no filtering motion at all.
            if !isFullscreen {
                styleChips
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
                        completionStyle: FinalPreset.completionStyle,
                        completionTuning: completionTuning,
                        moveStyle: FinalPreset.moveStyle,
                        moveTuning: moveTuning,
                        context: context,
                        handoff: moveTuning.handoff.stamp,
                        externalCommit: $externalCommit,
                        onCommit: { _ in
                            haptics.play(
                                FinalPreset.completionStyle.hapticScore,
                                speed: speed,
                                enabled: hapticsEnabled
                            )
                        },
                        completionOptions: FinalPreset.options,
                        moverPlaneOverride: 10,
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
            .frame(maxHeight: isFullscreen ? nil : 430)
            .scrollIndicators(.hidden)

            if !isFullscreen {
                HapticTimeline(
                    score: lastScore.isEmpty ? filterStyle.hapticScore(leavingDelays: [], tuning: filterTuning) : lastScore,
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

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "tray")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text("Nothing here")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
        .animation(filterTuning.shared.heightSpring.resolved(context), value: appliedVisible.isEmpty)
    }

    private var styleChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(FilterStyle.allCases) { candidate in
                    Button {
                        reset()
                        filterStyle = candidate
                    } label: {
                        Text(candidate.title)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        .background(
                            candidate == filterStyle ? TaskLabPalette.ink : Color(.secondarySystemBackground),
                            in: Capsule()
                        )
                        .foregroundStyle(candidate == filterStyle ? Color.white : Color.primary)
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
                    Button("Cycle") { cycle() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Button("Complete") { completeOne() }
                        .controlSize(.small)
                    Spacer()
                    Button("Reset") { reset() }
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
                Toggle("Force empty result", isOn: $forceEmpty)
                    .font(.caption)
                    .onChange(of: forceEmpty) { _, _ in select(filter) }
                Toggle("Show sliders", isOn: $showsSliders).font(.caption)

                Button("Export tuning…", systemImage: "square.and.arrow.up") { showingExport = true }
                    .controlSize(.small)

                Text("All \(counts[.all] ?? 0) · Noam \(counts[.noam] ?? 0) · Omer \(counts[.omer] ?? 0) · Joint \(counts[.joint] ?? 0). Noam and Omer both include Joint, so All↔Joint is the switch that actually separates these four.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if showsSliders {
                ForEach(FilterCatalog.shared) { group in
                    Section(group.name) {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $filterTuning.sub(param.path)
                            )
                        }
                    }
                }

                ForEach(filterStyle.groups) { group in
                    Section(group.name) {
                        ForEach(group.params) { param in
                            LabSlider(
                                name: param.name, unit: param.unit, decimals: param.decimals,
                                range: param.range, value: $filterTuning.sub(param.path)
                            )
                        }
                    }
                }

                Section("Reflow · shared with move-down") {
                    LabSlider(name: "Close · duration", unit: "s", decimals: 2, range: 0.05...2,
                              value: $moveTuning.closeRanks.displacedSpring.duration)
                    LabSlider(name: "Close · bounce", decimals: 2, range: 0...0.8,
                              value: $moveTuning.closeRanks.displacedSpring.bounce)
                    LabSlider(name: "Close · stagger", unit: "s", decimals: 3, range: 0...0.2,
                              value: $moveTuning.closeRanks.displacedStagger)
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

    private func select(_ next: TaskFilter) {
        let target = forceEmpty ? Set<String>() : next.visibleIds(in: items)

        // Haptics fire from the pill, not from the list's state change, so the feel matches
        // the press. Layered rather than replacing: a pill press during a completion is a
        // second thing the user pressed.
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

    private func completeOne() {
        guard let target = items.first(where: { appliedVisible.contains($0.id) && !$0.isCompleted }) else { return }
        Task {
            pressedId = target.id
            try? await Task.sleep(for: .seconds(0.12 / max(speed, 0.05)))
            pressedId = nil
            externalCommit = target.id
        }
    }

    private func reset() {
        leadTask?.cancel()
        forceEmpty = false
        filter = .all
        withAnimation(.spring(duration: 0.3)) {
            items = FilterSamples.list
            appliedVisible = Set(FilterSamples.list.map(\.id))
        }
    }

    // MARK: Persistence

    private func persist(_ value: FilterTuning) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storedTuning = String(decoding: data, as: UTF8.self)
    }

    private func loadStored() {
        guard !storedTuning.isEmpty,
              let decoded = try? JSONDecoder().decode(FilterTuning.self, from: Data(storedTuning.utf8))
        else { return }
        filterTuning = decoded
    }
}

private struct FilterExportSheet: View {
    @Binding var tuning: FilterTuning
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
            .navigationTitle("Filter Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
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
            tuning = try JSONDecoder().decode(FilterTuning.self, from: Data(text.utf8))
            status = "Applied."
        } catch {
            status = "Could not parse: \(error.localizedDescription)"
        }
    }
}

#Preview("Filtering") {
    NavigationStack { FilterLab() }
}
