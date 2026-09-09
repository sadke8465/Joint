import SwiftUI

/// C — Liquid Metal.
///
/// Protagonist: the material. Metaphor: mercury flowing across the row. The energy is a
/// moving *light*, not a moving object.
///
/// Two things make this read as metal rather than as a gradient overlay:
///
/// 1. The shader treats the layer's alpha as a heightfield and lights the derived normal,
///    so the highlight curves around the letterforms and the punched-out checkmark bevels
///    itself for free.
/// 2. `progress` and `lightAngle` run on two *different* springs, so the highlight lags and
///    overshoots the band. Light with inertia is the whole illusion.
///
/// Nested `AnimatableReader`s are what make that possible: SwiftUI will not hand you the
/// intermediate value of an animating `@State`, but it will interpolate `animatableData`
/// and re-evaluate `body`. That keeps both uniforms spring-driven and interruptible, which
/// a `keyframeAnimator` could not do.
struct LiquidMetalRow: View {
    var item: TaskItemContent
    var isCompleted: Bool
    var tuning: LiquidMetalTuning
    var context: MotionContext
    var onCommit: () -> Void

    /// Owned by the lab so Replay can simulate a real touch-down/release, which the
    /// gesture-driven styles (Stamp, Settle & Recede) depend on entirely.
    @Binding var isPressed: Bool

    var body: some View {
        Group {
            if let scrub = context.scrub {
                frozen(at: scrub)
            } else {
                animated
            }
        }
        .cardChrome()
        .scaleEffect(isPressed ? 1 - (1 - tuning.pressScale) * context.motionScale : 1)
        .animation(tuning.cardSpring.resolved(context), value: isPressed)
        .pressable(isPressed: $isPressed, onCommit: onCommit)
    }

    private func frozen(at progress: Double) -> some View {
        let light = tuning.lightAngleStart + (tuning.lightAngleEnd - tuning.lightAngleStart) * progress
        return row(progress: progress)
            .modifier(LiquidMetalEffect(
                progress: progress,
                lightAngle: light,
                tuning: tuning,
                enabled: !context.reduceMotion
            ))
    }

    private var animated: some View {
        AnimatableReader(value: isCompleted ? 1 : 0) { progress in
            AnimatableReader(value: isCompleted ? tuning.lightAngleEnd : tuning.lightAngleStart) { light in
                row(progress: progress)
                    .modifier(LiquidMetalEffect(
                        progress: progress,
                        lightAngle: light,
                        tuning: tuning,
                        enabled: !context.reduceMotion
                    ))
            }
            .animation(tuning.lightSpring.resolved(context), value: isCompleted)
        }
        .animation(tuning.bandSpring.resolved(context), value: isCompleted)
    }

    private func row(progress: Double) -> some View {
        TaskRowScaffold {
            CompletionCheckbox(
                isCompleted: isCompleted,
                fillSpec: tuning.fillSpring,
                checkSpec: tuning.checkSpring,
                context: context,
                lineWidth: tuning.checkWeight,
                checkPunch: 1.0,
                // Carved out of the fill, so the shader's heightfield embosses it.
                punchedOut: !context.reduceMotion
            )
        } detail: {
            // The strike is not a separate animation: its width *is* the band's position,
            // already interpolated by the band spring one level up.
            StrikableTitle(
                text: item.title,
                strikeFraction: progress,
                greyFraction: progress,
                strikeWeight: tuning.strikeWeight,
                greyOpacity: tuning.greyOpacity,
                strikeAnimation: nil,
                greyAnimation: nil
            )

            DueDateSwap(
                dueText: item.dueText,
                isCompleted: isCompleted,
                travel: tuning.dueTravel * context.motionScale,
                outAnimation: tuning.dueSpring.resolved(context),
                inAnimation: tuning.dueSpring.resolved(context)
            )
        } assignee: {
            AssigneeCluster(name: item.assignee, indicators: item.assigneeIndicators)
        }
    }
}

private struct LiquidMetalEffect: ViewModifier {
    var progress: Double
    var lightAngle: Double
    var tuning: LiquidMetalTuning
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.visualEffect { view, proxy in
                view.layerEffect(
                    ShaderLibrary.liquidMetal(
                        .float2(proxy.size),
                        .float(Float(progress)),
                        .float(Float(tuning.bandWidth)),
                        .float(Float(tuning.bandSoftness)),
                        .float(Float(tuning.bandTilt)),
                        .float(Float(lightAngle)),
                        .float(Float(tuning.metalness)),
                        .float(Float(tuning.roughness)),
                        .float(Float(tuning.heightScale)),
                        .float(Float(tuning.refraction)),
                        .color(TaskLabPalette.pink),
                        .color(TaskLabPalette.cyan)
                    ),
                    maxSampleOffset: CGSize(width: tuning.refraction + 4, height: 4)
                )
            }
        } else {
            content
        }
    }
}
