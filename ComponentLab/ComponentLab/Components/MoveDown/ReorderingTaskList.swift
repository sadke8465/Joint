import SwiftUI

// MARK: - Plan

/// Everything the list decides for one row on a given frame. The list does the arithmetic;
/// the row only applies it.
struct RowPlan: Equatable {
    var slotOffsetY: CGFloat = 0
    /// The slot this row occupies. The position animation keys on *this* rather than on
    /// `slotOffsetY`, because those two change for different reasons: the index changes when
    /// the list reorders, and the offset also changes when the measured row height arrives
    /// and the pitch is corrected. Only the first is a reorder, and only the first should
    /// animate — see `measure(_:)`.
    var slotIndex: Int = 0
    var positionAnimation: Animation?
    var role: MoveRole = .idle
    var zIndex: Double = 0
    var shoveAmount: Double = 0
    var shoveIn: Animation?
    var shoveOut: Animation?
    var presentation = FilterPresentation()
    var presentationAnimation: Animation?

    // Animations are not renderable state, so they are excluded: they only matter at the
    // moment the value they govern changes.
    static func == (lhs: RowPlan, rhs: RowPlan) -> Bool {
        lhs.slotOffsetY == rhs.slotOffsetY && lhs.slotIndex == rhs.slotIndex
            && lhs.role == rhs.role && lhs.zIndex == rhs.zIndex
            && lhs.shoveAmount == rhs.shoveAmount && lhs.presentation == rhs.presentation
    }
}

private struct MoveRecord: Equatable {
    var from: Int
    var to: Int
    var previous: [String: Int]
    /// Monotonic, so concurrent moves can be ordered without consulting a clock.
    var order: Int
}

// MARK: - List

/// Absolute positioning rather than a stack's implicit reordering, because every style needs
/// per-row control of plane, scale, shadow and blur, and because the displaced rows have to
/// react to the mover rather than all animating at once.
///
/// The central decision: **completion state and sort state are separate.** `isCompleted`
/// flips on tap and drives the checkmark; `settled` flips one handoff later and drives the
/// slot assignment. Expressing the handoff as a `.delay()` on the position animation instead
/// would mean the list is already re-sorted while the row only looks stationary — every
/// subsequent tap would then compute its roles against slots that had silently moved, and a
/// row retargeted mid-flight would inherit a fresh delay and freeze. Deferring the *state*
/// keeps every position animation delay-free, so springs retarget from live velocity.
///
/// The handoff is **one debounced window for the whole list**, not a timer per row. Every
/// commit — completing or unchecking — restarts it, and when it finally closes, every row
/// touched during it takes its new slot in a single reorder. Three properties fall out of
/// that, and all three are the point:
///
/// - *Nothing moves while you are still tapping.* Per-row timers let the first tap's reorder
///   land under the finger reaching for the third row. This cannot.
/// - *One reorder per burst.* Movers share one slot snapshot, so they read as a single
///   rearrangement rather than several racing ones.
/// - *No double reorder.* The flush reads each row's current completion state rather than one
///   captured at tap time, so a row toggled twice inside the window resolves to no movement at
///   all instead of two cancelling animations.
struct ReorderingTaskList: View {
    @Binding var items: [TaskItemContent]
    @Binding var pressedId: String?

    var completionStyle: TaskCompletionStyle
    var completionTuning: TaskCompletionTuning
    var moveStyle: MoveDownStyle
    var moveTuning: MoveDownTuning
    var context: MotionContext
    var handoff: Double
    @Binding var externalCommit: String?
    var onCommit: (String) -> Void
    /// Fires once per bulk reorder, as the batch starts travelling. A landing haptic belongs
    /// here rather than on the tap: one reorder, one landing, however many rows moved.
    var onReorder: () -> Void = {}
    var completionOptions = CompletionOptions()
    var moverPlaneOverride: Double?

    /// Ids matching the current filter. Defaults to nil, which means "no filtering" and
    /// leaves every other playground behaving exactly as before.
    var visible: Set<String>?
    var filterStyle: FilterStyle = .sift
    var filterTuning = FilterTuning()

    /// Ids whose reorder has actually been applied. Deliberately not `isCompleted`.
    @State private var settled: Set<String> = []
    /// Ids toggled since the last flush, waiting for the window to close. One set for both
    /// directions — completing and unchecking join the same batch and move together.
    @State private var pending: Set<String> = []
    /// Keyed by mover id, so every row in a batch keeps its own role.
    @State private var moves: [String: MoveRecord] = [:]
    /// Per row, so a commit only re-triggers the phase animators of rows it actually affects.
    @State private var tokens: [String: Int] = [:]
    /// One timer for the whole list rather than one per row. That is the whole tweak.
    @State private var flushTask: Task<Void, Never>?
    /// When the batch currently reflowing will be done, so the next flush can wait it out.
    @State private var reflowEnd: Date?
    @State private var clearTasks: [String: Task<Void, Never>] = [:]
    @State private var moveCounter = 0
    /// A first-frame guess only. The real height arrives from `measure(_:)` one layout pass
    /// later and is almost never this number, so the correction has to be invisible.
    @State private var rowHeight: CGFloat = 62

    /// Rows currently occupying a slot. Deferred behind `visible` on the way out, so a row
    /// never appears to squeeze shut while still on screen — that is the delete idiom, and
    /// avoiding it is what stops a filter reading as data loss.
    ///
    /// Optional on purpose: nil means "not yet diverged from the filter", so the very first
    /// render already has correct slots. Seeding it in `onAppear` instead would stack every
    /// row at slot 0 for one frame and then animate them apart on the reflow spring.
    @State private var laidOutState: Set<String>?
    /// Where a row sits once it no longer has a slot of its own.
    @State private var parked: [String: Int] = [:]
    /// Rows admitted this update: their position change is applied without animation so
    /// gaining a slot cannot produce a slide from a stale one.
    @State private var admitted: Set<String> = []
    @State private var releaseTasks: [String: Task<Void, Never>] = [:]
    @State private var enterTask: Task<Void, Never>?
    @State private var admitClearTask: Task<Void, Never>?

    private let spacing: CGFloat = 8

    private var pitch: CGFloat { rowHeight + spacing }
    private var clock: Double { max(context.speed, 0.05) }

    /// Completed items sink below the incomplete ones, each block keeping its natural order.
    ///
    /// Ordering the completed block naturally rather than by completion time is what makes
    /// the final arrangement depend *only on which items are done* — never on the order they
    /// were tapped or on how animations interleaved. Two taps in either order converge on the
    /// same list, which is the property that makes double-sorting impossible rather than
    /// merely unlikely.
    private var visibleIds: Set<String> { visible ?? Set(items.map(\.id)) }

    private var laidOut: Set<String> { laidOutState ?? visibleIds }

    private func slotMap(for settledIds: Set<String>) -> [String: Int] {
        ReorderPlanner.slots(ids: items.map(\.id), laidOut: laidOut, settled: settledIds)
    }

    /// Present for presentation purposes only once it *also* holds a slot. Leaving rows drop
    /// out immediately and start exiting; arriving rows wait for the list to open for them,
    /// so they fade in at their destination rather than at a stale position.
    private func isPresent(_ id: String) -> Bool {
        visibleIds.contains(id) && laidOut.contains(id)
    }

    private func slotOffset(for id: String) -> CGFloat {
        if let slot = slots[id] { return CGFloat(slot) * pitch }
        return CGFloat(parked[id] ?? 0) * pitch
    }

    private var slots: [String: Int] { slotMap(for: settled) }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach($items) { $item in
                MoveDownRowView(
                    item: $item,
                    pressedId: $pressedId,
                    plan: plan(for: item),
                    token: tokens[item.id] ?? 0,
                    completionStyle: completionStyle,
                    completionTuning: completionTuning,
                    moveStyle: moveStyle,
                    moveTuning: moveTuning,
                    context: context,
                    onCommit: { commit(item.id) },
                    completionOptions: completionOptions,
                    onMeasure: { measure($0) }
                )
            }
        }
        // Ten rows down to three is a ~450pt change; without this whatever sits below snaps.
        .frame(height: max(pitch * CGFloat(laidOut.count) - spacing, 0), alignment: .top)
        .animation(filterTuning.shared.heightSpring.resolved(context), value: laidOut.count)
        .onChange(of: visibleIds) { _, updated in applyFilter(to: updated) }
        .onChange(of: externalCommit) { _, requested in
            guard let requested else { return }
            commit(requested)
            externalCommit = nil
        }
        // Self-healing: anything that changes completion from outside this view — a list
        // reset, most obviously — reconciles here rather than leaving `settled` stale.
        // Rows with a scheduled sort are left alone; their own task applies the truth.
        .onChange(of: items) { _, _ in reconcile() }
        .onDisappear { cancelEverything() }
    }

    // MARK: Plans

    private func plan(for item: TaskItemContent) -> RowPlan {
        let slot = slots[item.id] ?? 0
        let role = role(for: item.id, slot: slot)
        let shove = MoveDownMotion.shove(
            style: moveStyle,
            tuning: moveTuning,
            role: role,
            context: context
        )

        let present = isPresent(item.id)
        let index = slots[item.id] ?? parked[item.id] ?? 0

        return RowPlan(
            slotOffsetY: slotOffset(for: item.id),
            slotIndex: index,
            // Admitted rows snap into their new slot; everything else springs.
            positionAnimation: admitted.contains(item.id) ? nil : MoveDownMotion.positionAnimation(
                style: moveStyle,
                tuning: moveTuning,
                role: role,
                context: context
            ),
            role: role,
            zIndex: plane(for: item.id),
            shoveAmount: shove?.amount ?? 0,
            shoveIn: shove?.animation,
            shoveOut: (moveStyle == .vault ? moveTuning.vault.duckSpring : moveTuning.drop.shoveSpring)
                .resolved(context),
            presentation: FilterMotion.presentation(
                style: filterStyle,
                tuning: filterTuning,
                isPresent: present,
                context: context
            ),
            presentationAnimation: FilterMotion.presentationAnimation(
                style: filterStyle,
                tuning: filterTuning,
                isPresent: present,
                delay: present ? 0 : FilterMotion.exitDelay(
                    style: filterStyle,
                    tuning: filterTuning,
                    index: index,
                    pitch: Double(pitch)
                ),
                context: context
            )
        )
    }

    // MARK: Measurement

    /// Rows are positioned absolutely, so the pitch has to come from a measurement — and a
    /// measurement is not a reorder. Every row reports, and they agree, so anything that
    /// matches what we already hold is dropped rather than rewritten n times per layout pass.
    ///
    /// The correction itself reaches the rows through `slotOffsetY` without touching
    /// `slotIndex`, which is what keeps it out of the position spring.
    private func measure(_ size: CGSize) {
        guard abs(size.height - rowHeight) > 0.5 else { return }
        rowHeight = size.height
    }

    // MARK: Filtering

    private func applyFilter(to updated: Set<String>) {
        for task in releaseTasks.values { task.cancel() }
        releaseTasks.removeAll()
        enterTask?.cancel()

        let leaving = laidOut.subtracting(updated)
        let entering = updated.subtracting(laidOut)
        guard !leaving.isEmpty || !entering.isEmpty else { return }

        var lastRelease = 0.0
        for id in leaving {
            var delay = FilterMotion.releaseDelay(
                style: filterStyle,
                tuning: filterTuning,
                index: slots[id] ?? 0,
                pitch: Double(pitch)
            )
            // A row whose completion is still in flight is held so its checkmark is never cut
            // off mid-draw. The filter otherwise wins outright: it is navigation.
            if pending.contains(id) { delay += filterTuning.shared.filterGrace }
            lastRelease = max(lastRelease, delay)

            releaseTasks[id] = Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay / clock))
                guard !Task.isCancelled else { return }
                parked[id] = slots[id] ?? parked[id]
                laidOutState = laidOut.subtracting([id])
                releaseTasks[id] = nil
            }
        }

        guard !entering.isEmpty else { return }
        let wait = lastRelease
        enterTask = Task { @MainActor in
            if wait > 0 { try? await Task.sleep(for: .seconds(wait / clock)) }
            guard !Task.isCancelled else { return }
            admit(entering)
        }
    }

    private func admit(_ ids: Set<String>) {
        var next = laidOut
        next.formUnion(ids)
        let projected = ReorderPlanner.slots(ids: items.map(\.id), laidOut: next, settled: settled)
        for id in ids { parked[id] = projected[id] }

        admitted = ids
        laidOutState = next
        enterTask = nil

        admitClearTask?.cancel()
        admitClearTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.05))
            guard !Task.isCancelled else { return }
            admitted = []
        }
    }

    /// Concurrent movers are stacked by recency, so the newest stays readable on top — and
    /// within one batch by origin slot, so a complete and an uncheck that cross each other in
    /// the same flush never land on the same plane and flicker.
    private func plane(for id: String) -> Double {
        guard let record = moves[id] else { return 0 }
        return (moverPlaneOverride ?? moveStyle.moverPlane)
            + Double(record.order) * 0.001
            + Double(record.from) * 0.0001
    }

    private func role(for id: String, slot: Int) -> MoveRole {
        if moves[id] != nil { return .mover }

        // A row can be displaced by more than one mover at once. Across batches the most
        // recent is the one whose crossing reads; within a batch they all share one `previous`
        // snapshot, so the topmost of them describes the whole wave and the rows below it
        // stagger from a single origin. Picking an arbitrary one instead is what would make a
        // bulk reorder read as several competing movements.
        guard let record = moves.values.max(by: {
            $0.order != $1.order ? $0.order < $1.order : $0.from > $1.from
        }) else { return .idle }

        let before = record.previous[id] ?? slot
        guard before != slot else { return .idle }

        let span = Double(record.to - record.from)
        let crossing = span == 0 ? 0 : min(1, max(0, Double(before - record.from) / span))
        return .displaced(crossing: crossing, rank: abs(before - record.from))
    }

    // MARK: Commit

    /// The tap. Completion state only — the reorder joins the batch, it is not performed.
    private func commit(_ id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        onCommit(id)
        pending.insert(id)
        scheduleFlush()
    }

    /// The window. Every commit cancels the pending flush and starts it again from zero, so a
    /// burst of taps produces exactly one reorder `handoff` seconds after the *last* of them —
    /// and until then the list is completely still under the finger.
    private func scheduleFlush() {
        flushTask?.cancel()
        flushTask = Task { @MainActor in
            let delay = handoff / clock
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }

            // One reorder at a time, as a property rather than as a consequence of tuning: the
            // preset's 1.5s window is *shorter* than Close Ranks' own reflow (1.2s displaced
            // spring plus 0.12s per step — 1.56s across four rows), so without this a second
            // batch would start into slots the first has not finished vacating.
            if let end = reflowEnd, end > .now {
                try? await Task.sleep(for: .seconds(end.timeIntervalSinceNow))
                guard !Task.isCancelled else { return }
            }
            flush()
        }
    }

    /// The bulk reorder. Reads each pending row's *current* completion state rather than one
    /// captured at tap time, so a row toggled twice inside the window resolves to no movement
    /// at all instead of two cancelling animations.
    ///
    /// Direction is not an input here: completing and unchecking are the same operation on
    /// `settled`, so a window containing both applies both in the one move.
    private func flush() {
        flushTask = nil
        let touched = pending
        pending = []
        guard !touched.isEmpty else { return }

        let before = settled
        var updated = settled
        for item in items where touched.contains(item.id) {
            if item.isCompleted {
                updated.insert(item.id)
            } else {
                updated.remove(item.id)
            }
        }
        // Rows deleted from the list while they were waiting for the window.
        updated.subtract(touched.subtracting(Set(items.map(\.id))))
        guard updated != before else { return }

        let previous = slots
        let after = slotMap(for: updated)
        settled = updated

        // Slots are a permutation, so a row whose settle state flipped without changing slot
        // never travels — the last incomplete row completing, most obviously. Recording a move
        // for it would lift a stationary row onto the mover plane.
        let movers = touched.filter {
            before.contains($0) != updated.contains($0) && previous[$0] != after[$0]
        }
        guard !movers.isEmpty else { return }

        // One order for the batch: every mover shares this snapshot, which is what lets the
        // displaced rows stagger from a single origin instead of from whichever tap was last.
        moveCounter &+= 1
        for id in movers {
            guard let from = previous[id], let to = after[id] else { continue }
            moves[id] = MoveRecord(from: from, to: to, previous: previous, order: moveCounter)
        }

        for row in items where movers.contains(row.id) || previous[row.id] != after[row.id] {
            tokens[row.id, default: 0] &+= 1
        }

        let reflow = MoveDownMotion.reflowDuration(
            style: moveStyle,
            tuning: moveTuning,
            displacedCount: ReorderPlanner.moved(from: previous, to: after).count
        )
        reflowEnd = .now.addingTimeInterval((reflow + 0.1) / clock)
        for id in movers { scheduleClear(for: id, reflow: reflow) }

        onReorder()
    }

    /// Holds the mover's plane until the whole reflow has finished, not just its own travel.
    /// With a fast mover and slow neighbours — which is exactly this preset — clearing on the
    /// mover's own duration drops it behind rows that are still moving. Every mover in a batch
    /// is passed the same reflow, so a batch lands and clears as one.
    private func scheduleClear(for id: String, reflow: Double) {
        clearTasks[id]?.cancel()
        clearTasks[id] = Task { @MainActor in
            try? await Task.sleep(for: .seconds((reflow + 0.1) / clock))
            guard !Task.isCancelled else { return }
            moves[id] = nil
            clearTasks[id] = nil
        }
    }

    // MARK: Housekeeping

    private func reconcile() {
        var updated = settled
        for item in items where !pending.contains(item.id) {
            if item.isCompleted {
                updated.insert(item.id)
            } else {
                updated.remove(item.id)
            }
        }
        guard updated != settled else { return }
        settled = updated
    }

    private func cancelEverything() {
        flushTask?.cancel()
        for task in clearTasks.values { task.cancel() }
        for task in releaseTasks.values { task.cancel() }
        enterTask?.cancel()
        admitClearTask?.cancel()
        flushTask = nil
        reflowEnd = nil
        clearTasks.removeAll()
        releaseTasks.removeAll()

        // Nothing is left half-sorted. Rows still waiting on the window take their final slots
        // outright, since there is no longer anyone on screen for the reorder to explain
        // itself to — and coming back to a list that disagrees with its own checkmarks is the
        // one failure this whole deferral scheme exists to avoid.
        pending = []
        moves = [:]
        settled = Set(items.filter(\.isCompleted).map(\.id))
    }
}

// MARK: - Row

private struct MoveDownRowView: View {
    @Binding var item: TaskItemContent
    @Binding var pressedId: String?

    var plan: RowPlan
    var token: Int
    var completionStyle: TaskCompletionStyle
    var completionTuning: TaskCompletionTuning
    var moveStyle: MoveDownStyle
    var moveTuning: MoveDownTuning
    var context: MotionContext
    var onCommit: () -> Void
    var completionOptions: CompletionOptions
    var onMeasure: (CGSize) -> Void

    private var pressed: Binding<Bool> {
        Binding(
            get: { pressedId == item.id },
            set: { pressedId = $0 ? item.id : nil }
        )
    }

    var body: some View {
        AnimatedTaskItemView(
            item: item,
            style: completionStyle,
            isCompleted: $item.isCompleted,
            isPressed: pressed,
            tuning: completionTuning,
            context: context,
            onCommit: onCommit,
            options: completionOptions
        )
        // Measured before any decoration, so an animating scale never feeds back into pitch.
        .onGeometryChange(for: CGSize.self) { $0.size } action: { onMeasure($0) }
        .id(completionStyle)
        .modifier(MoveDecorationModifier(
            plan: plan,
            token: token,
            isCompleted: item.isCompleted,
            moveStyle: moveStyle,
            moveTuning: moveTuning,
            context: context
        ))
        .scaleEffect(plan.presentation.scale)
        .rotationEffect(.degrees(plan.presentation.rotation))
        .offset(x: plan.presentation.offsetX, y: plan.presentation.offsetY)
        .opacity(plan.presentation.opacity)
        .blur(radius: plan.presentation.blur)
        .animation(plan.presentationAnimation, value: plan.presentation)
        .allowsHitTesting(plan.presentation.opacity > 0.5)
        // No delay anywhere in the position animation: the handoff already happened as a
        // state change, so this spring is free to retarget from live velocity.
        //
        // Keyed to the slot rather than to the offset. The offset also moves when the measured
        // row height replaces the initial guess, and running that through the reorder spring
        // makes every row in the list spring to a new spacing — a whole-list ring on every
        // appearance, in every style, since idle rows animate on the displaced spring.
        .offset(y: plan.slotOffsetY)
        .animation(plan.positionAnimation, value: plan.slotIndex)
        .zIndex(plan.zIndex)
    }
}

/// Two independent phase animators: the mover's decorative beats, and the crossing-keyed
/// shove on the rows it passes. Both are keyed to this row's own token, so a commit
/// elsewhere in the list leaves them alone.
private struct MoveDecorationModifier: ViewModifier {
    var plan: RowPlan
    var token: Int
    var isCompleted: Bool
    var moveStyle: MoveDownStyle
    var moveTuning: MoveDownTuning
    var context: MotionContext

    func body(content: Content) -> some View {
        content
            .phaseAnimator(MovePhase.allCases, trigger: token) { view, phase in
                let decoration = MoveDownMotion.decoration(
                    style: moveStyle,
                    tuning: moveTuning,
                    phase: plan.role.isMover ? phase : .rest,
                    isCompleted: isCompleted,
                    context: context
                )
                view
                    .scaleEffect(x: decoration.scaleX, y: decoration.scaleY)
                    .offset(x: decoration.extraOffsetX, y: decoration.extraOffsetY)
                    .opacity(decoration.opacity)
                    .blur(radius: decoration.blur)
                    .shadow(
                        color: .black.opacity(decoration.liftShadowOpacity),
                        radius: decoration.liftShadowRadius,
                        y: decoration.liftShadowRadius * 0.4
                    )
            } animation: { phase in
                MoveDownMotion.phaseAnimation(
                    style: moveStyle,
                    tuning: moveTuning,
                    phase: phase,
                    context: context
                )
            }
            .phaseAnimator([0, 1, 2], trigger: token) { view, step in
                view.offset(y: step == 1 ? plan.shoveAmount : 0)
            } animation: { step in
                step == 1 ? plan.shoveIn : plan.shoveOut
            }
    }
}
