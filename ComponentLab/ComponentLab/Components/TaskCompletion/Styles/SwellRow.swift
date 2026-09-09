import SwiftUI

/// E — Swell.
///
/// Protagonist: the card as a membrane. Metaphor: a pebble dropped in water — the checkbox
/// *is* the pebble. Energy is radial from the contact point.
///
/// The distinguishing property: **the timeline is emergent, not authored.** Every element
/// below reads its stagger from `arrival(at:)` — its own distance to the origin divided by
/// wave speed. Tune one number, `speed`, and the whole choreography falls out of the layout.
/// Change the card width, move the checkbox, translate the title into German, and the
/// timing re-derives itself correctly. None of the other four survive that without retuning.
///
/// The wave's own clock is linear on purpose: a travelling wave propagates linearly in time
/// and the *decay* is the exponential, which lives in the shader. Spring-driving the
/// wavefront would be physically wrong. Everything the wave triggers is spring-driven.
struct SwellRow: View {
    var item: TaskItemContent
    var isCompleted: Bool
    var tuning: SwellTuning
    var context: MotionContext
    var onCommit: () -> Void

    /// Owned by the lab so Replay can simulate a real touch-down/release, which the
    /// gesture-driven styles (Stamp, Settle & Recede) depend on entirely.
    @Binding var isPressed: Bool
    @State private var waveTrigger = 0
    @State private var origin: CGPoint = .zero
    @State private var titleAnchor: CGPoint = .zero
    @State private var dueAnchor: CGPoint = .zero
    @State private var assigneeAnchor: CGPoint = .zero

    private static let space = "swell.card"

    /// Room for the border to bow outward without being clipped by the layer's bounds.
    private var bowRoom: Double {
        guard !context.reduceMotion else { return 0 }
        return tuning.amplitude * (1 + tuning.edgeGain) + 4
    }

    private var waveDuration: Double { tuning.waveDuration / max(context.speed, 0.05) }

    /// Seconds for the wavefront to reach a point. This is the entire scheduling system.
    private func arrival(at point: CGPoint) -> Double {
        guard tuning.speed > 0 else { return 0 }
        return Double(hypot(point.x - origin.x, point.y - origin.y)) / tuning.speed
    }

    private func staggered(_ base: SpringSpec, at point: CGPoint) -> SpringSpec {
        SpringSpec(base.duration, bounce: base.bounce, delay: arrival(at: point))
    }

    var body: some View {
        card
            .padding(bowRoom)
            .coordinateSpace(.named(Self.space))
            .modifier(SwellEffect(
                trigger: waveTrigger,
                duration: waveDuration,
                scrubbedTime: context.scrub.map { $0 * tuning.waveDuration },
                origin: CGPoint(x: origin.x + tuning.originNudgeX, y: origin.y + tuning.originNudgeY),
                tuning: tuning,
                enabled: !context.reduceMotion
            ))
            .padding(-bowRoom)
            .scaleEffect(isPressed ? 1 - (1 - tuning.pressScale) * context.motionScale : 1)
            .animation(tuning.cardSpring.resolved(context), value: isPressed)
            .pressable(isPressed: $isPressed) {
                waveTrigger &+= 1
                onCommit()
            }
    }

    private var card: some View {
        TaskRowScaffold {
            // The pebble. At radius zero it has no displacement, so it draws cleanly while
            // everything around it moves.
            CompletionCheckbox(
                isCompleted: isCompleted,
                fillSpec: tuning.fillSpring,
                checkSpec: tuning.checkSpring,
                context: context,
                lineWidth: tuning.checkWeight
            )
            .scaleEffect(isPressed ? tuning.checkboxPulse : 1)
            .animation(tuning.checkboxSpring.resolved(context), value: isPressed)
            .anchorReporter(in: Self.space) { origin = $0 }
        } detail: {
            StrikableTitle(
                text: item.title,
                strikeFraction: isCompleted ? 1 : 0,
                greyFraction: isCompleted ? 1 : 0,
                strikeWeight: tuning.strikeWeight,
                greyOpacity: tuning.greyOpacity,
                strikeAnimation: staggered(tuning.strikeSpring, at: titleAnchor).resolved(context),
                greyAnimation: staggered(tuning.titleSpring, at: titleAnchor).resolved(context)
            )
            .anchorReporter(in: Self.space) { titleAnchor = $0 }

            DueDateSwap(
                dueText: item.dueText,
                isCompleted: isCompleted,
                travel: tuning.dueTravel * context.motionScale,
                outAnimation: staggered(tuning.dueSpring, at: dueAnchor).resolved(context),
                inAnimation: staggered(tuning.dueSpring, at: dueAnchor).resolved(context)
            )
            .anchorReporter(in: Self.space) { dueAnchor = $0 }
        } assignee: {
            assigneeCluster
        }
        .cardChrome()
    }

    @ViewBuilder
    private var assigneeCluster: some View {
        let pulseIn = staggered(tuning.assigneeSpring, at: assigneeAnchor).resolved(context)
        let pulseOut = tuning.assigneeSpring.resolved(context)

        AssigneeCluster(name: item.assignee, indicators: item.assigneeIndicators)
            .anchorReporter(in: Self.space) { assigneeAnchor = $0 }
            .phaseAnimator([0, 1, 2], trigger: waveTrigger) { view, phase in
                view.scaleEffect(
                    phase == 1 && !context.reduceMotion ? tuning.assigneePulse : 1
                )
            } animation: { phase in
                phase == 1 ? pulseIn : pulseOut
            }
    }
}

// MARK: - Effect

private struct SwellEffect: ViewModifier {
    var trigger: Int
    var duration: Double
    var scrubbedTime: Double?
    var origin: CGPoint
    var tuning: SwellTuning
    var enabled: Bool

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else if let scrubbedTime {
            wave(content, at: scrubbedTime)
        } else {
            content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, time in
                wave(view, at: time)
            } keyframes: { _ in
                MoveKeyframe(0)
                LinearKeyframe(duration, duration: duration)
            }
        }
    }

    // keyframeAnimator's content builder runs nonisolated, so the helper it calls must be
    // nonisolated too.
    nonisolated private func wave(_ view: some View, at time: Double) -> some View {
        view.visualEffect { effectView, proxy in
                    effectView.layerEffect(
                        ShaderLibrary.swell(
                            .float2(proxy.size),
                            .float2(origin),
                            .float(Float(time)),
                            .float(Float(tuning.amplitude)),
                            .float(Float(tuning.wavelength)),
                            .float(Float(tuning.speed)),
                            .float(Float(tuning.decay)),
                            .float(Float(tuning.frontSoftness)),
                            .float(Float(tuning.edgeGain)),
                            .float(Float(tuning.crestHighlight))
                        ),
                        maxSampleOffset: CGSize(
                            width: tuning.amplitude * (1 + tuning.edgeGain) + 2,
                            height: tuning.amplitude * (1 + tuning.edgeGain) + 2
                        )
                    )
        }
    }
}

// MARK: - Geometry

extension View {
    /// Reports this view's centre in a named space. Swell needs real positions because its
    /// stagger is computed from distance rather than stored as a delay.
    func anchorReporter(in space: String, action: @escaping (CGPoint) -> Void) -> some View {
        onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .named(space))
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { action($0) }
    }
}
