import SwiftUI
import UIKit

@MainActor
struct TaskCompletionLab: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var style: TaskCompletionStyle = .strikeCascade
    @State private var tuning = TaskCompletionTuning()
    @State private var isCompleted = false
    @State private var isPressed = false
    @State private var speed: Double = 1
    @State private var isLooping = false
    @State private var previewReduceMotion = false
    @State private var hapticsEnabled = true
    @State private var isFullscreen = false
    @State private var haptics = CompletionHaptics()
    @State private var loopTask: Task<Void, Never>?
    @State private var showingExport = false
    @State private var didSave = false
    @State private var isScrubbing = false
    @State private var scrubPosition = 0.5

    @AppStorage("componentlab.taskCompletionTuning") private var storedTuning = ""

    init() {
        _style = State(initialValue: LaunchOptions.style ?? .strikeCascade)
        _isCompleted = State(initialValue: LaunchOptions.completed)
        _speed = State(initialValue: LaunchOptions.speed ?? 1)
        _isScrubbing = State(initialValue: LaunchOptions.scrub != nil)
        _scrubPosition = State(initialValue: LaunchOptions.scrub ?? 0.5)
    }

    private var reduceMotion: Bool { previewReduceMotion || systemReduceMotion }

    private var context: MotionContext {
        // `reversing` is read after the toggle, so completing resolves forward springs and
        // un-completing resolves the shortened, calmer undo variants. (Rule 4.)
        MotionContext(
            speed: speed,
            reversing: !isCompleted,
            reduceMotion: reduceMotion,
            scrub: isScrubbing && style.isShaderDriven ? scrubPosition : nil
        )
    }

    var body: some View {
        LabShell(isFullscreen: $isFullscreen) {
            stage
        } panel: {
            panel
        }
        .navigationTitle("Completion Motion")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) { TuningExportSheet(tuning: $tuning) }
        .task {
            loadStoredTuning()
            if LaunchOptions.opensFullscreen { isFullscreen = true }
            if LaunchOptions.autoLoop { isLooping = true }
        }
        .onChange(of: tuning) { _, newValue in persist(newValue) }
        .onChange(of: isLooping) { _, running in running ? startLoop() : stopLoop() }
        .onDisappear { stopLoop() }
    }

    // MARK: Stage

    private var stage: some View {
        VStack(spacing: 14) {
            if !isFullscreen {
                stylePicker
            }

            AnimatedTaskItemView(
                item: TaskItemSamples.figmaFrame[0],
                style: style,
                isCompleted: $isCompleted,
                isPressed: $isPressed,
                tuning: tuning,
                context: context,
                onCommit: commit
            )
            // Fresh state per style: two motion systems should never try to interpolate
            // into one another.
            .id(style)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)

            if !isFullscreen {
                HapticTimeline(
                    score: style.hapticScore,
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
                ForEach(TaskCompletionStyle.allCases) { candidate in
                    Button {
                        stopLoop()
                        isLooping = false
                        isCompleted = false
                        style = candidate
                    } label: {
                        VStack(spacing: 0) {
                            Text(candidate.title).font(.caption.weight(.medium))
                            Text(candidate.carrier).font(.caption2).opacity(0.65)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            candidate == style ? TaskLabPalette.ink : Color(.secondarySystemBackground),
                            in: Capsule()
                        )
                        .foregroundStyle(candidate == style ? Color.white : Color.primary)
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

                    Button("Reset", systemImage: "arrow.uturn.backward") {
                        tuning = TaskCompletionTuning()
                    }
                    .controlSize(.small)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Speed").font(.caption)
                        Spacer()
                        Text(speedLabel).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Slider(value: $speed, in: 0.1...1.0)
                    Text("A 50ms offset is invisible at 1×. Judge the cascade at 0.2×.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Toggle("Haptics", isOn: $hapticsEnabled)
                    .font(.caption)
                Toggle("Preview Reduce Motion", isOn: $previewReduceMotion)
                    .font(.caption)
                    .disabled(systemReduceMotion)

                Button("Export tuning…", systemImage: "square.and.arrow.up") { showingExport = true }
                    .controlSize(.small)
            }

            Section("Save") {
                // Carries all five tunings plus the style you had selected, so the move-down
                // lab can swap completion styles live and you can feel all twenty pairings.
                Button("Save preset", systemImage: "checkmark.circle.fill") {
                    CompletionPreset.save(tuning: tuning, style: style)
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { didSave = true }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if didSave || CompletionPreset.exists {
                    NavigationLink {
                        MoveDownLab()
                    } label: {
                        Label("Open Move Down Lab", systemImage: "arrow.down.to.line")
                            .font(.caption)
                    }
                }

                Text(didSave
                     ? "Saved. The move-down lab opens on \(style.title)."
                     : "Saves all five completion tunings and the selected style.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if style.isShaderDriven {
                Section("Scrub") {
                    Toggle("Freeze and scrub", isOn: $isScrubbing).font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(style == .swell ? "Wave time" : "Band position").font(.caption)
                            Spacer()
                            Text(scrubPosition.formatted(.number.precision(.fractionLength(2))))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $scrubPosition, in: 0...1)
                            .disabled(!isScrubbing)
                        Text("Hold the shader still and walk it frame by frame. Far easier than judging a 450ms sweep in flight.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            TuningPanel(tuning: $tuning, groups: style.groups)
        }
        .listStyle(.insetGrouped)
    }

    private var speedLabel: String {
        let slow = 1 / speed
        return slow < 1.05
            ? "1× real time"
            : "\(speed.formatted(.number.precision(.fractionLength(2))))×  ·  \(slow.formatted(.number.precision(.fractionLength(1))))× slow motion"
    }

    // MARK: Actions

    private func commit() {
        isCompleted.toggle()
        haptics.play(style.hapticScore, speed: speed, enabled: hapticsEnabled)
    }

    /// Replays through the same touch-down / release path a finger takes, because Stamp and
    /// Settle & Recede derive their entire first beat from the press.
    private func performPress() async {
        isPressed = true
        try? await Task.sleep(for: .seconds(0.12 / max(speed, 0.05)))
        isPressed = false
        commit()
    }

    private func replay() {
        Task { await performPress() }
    }

    private func startLoop() {
        loopTask?.cancel()
        loopTask = Task {
            while !Task.isCancelled {
                await performPress()
                try? await Task.sleep(for: .seconds(1.7 / max(speed, 0.05)))
            }
        }
    }

    private func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
        haptics.cancelPending()
    }

    // MARK: Persistence

    private func persist(_ value: TaskCompletionTuning) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storedTuning = String(decoding: data, as: UTF8.self)
    }

    private func loadStoredTuning() {
        guard !storedTuning.isEmpty,
              let decoded = try? JSONDecoder().decode(
                  TaskCompletionTuning.self,
                  from: Data(storedTuning.utf8)
              )
        else { return }
        tuning = decoded
    }
}

// MARK: - Export

/// Round-trips the whole tuning set as JSON so a chosen preset can leave the device as text
/// and be pasted straight back into the app.
private struct TuningExportSheet: View {
    @Binding var tuning: TaskCompletionTuning
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var status = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Copy this once you land on a set, or paste one in and apply.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
            .navigationTitle("Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
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
            tuning = try JSONDecoder().decode(TaskCompletionTuning.self, from: Data(text.utf8))
            status = "Applied."
        } catch {
            status = "Could not parse: \(error.localizedDescription)"
        }
    }
}

#Preview("Completion Motion Lab") {
    NavigationStack { TaskCompletionLab() }
}
