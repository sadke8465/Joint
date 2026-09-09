import SwiftUI

/// Resolves a filter style into the presentation each row wears, and into when the list is
/// allowed to reclaim that row's slot.
enum FilterMotion {

    /// What an absent row looks like. Present rows are always the identity.
    static func presentation(
        style: FilterStyle,
        tuning: FilterTuning,
        isPresent: Bool,
        context: MotionContext
    ) -> FilterPresentation {
        guard !isPresent else { return FilterPresentation() }
        guard !context.reduceMotion else { return FilterPresentation(opacity: 0) }

        switch style {
        case .sift:
            return FilterPresentation(opacity: 0, scale: tuning.sift.exitScale)

        case .deal:
            return FilterPresentation(
                opacity: 0.35,
                offsetX: tuning.deal.distance,
                rotation: tuning.deal.rotation
            )

        case .focus:
            return FilterPresentation(
                opacity: 0,
                scale: tuning.focus.scale,
                blur: tuning.focus.blur
            )

        case .zip:
            return FilterPresentation(opacity: 0, offsetX: tuning.zip.slide)
        }
    }

    /// The spring a row uses to reach that presentation, including its own stagger.
    static func presentationAnimation(
        style: FilterStyle,
        tuning: FilterTuning,
        isPresent: Bool,
        delay: Double,
        context: MotionContext
    ) -> Animation? {
        let spec: SpringSpec
        switch style {
        case .sift: spec = isPresent ? tuning.sift.enterSpring : tuning.sift.exitSpring
        case .deal: spec = isPresent ? tuning.deal.enterSpring : tuning.deal.exitSpring
        case .focus: spec = isPresent ? tuning.focus.enterSpring : tuning.focus.recedeSpring
        case .zip: spec = isPresent ? tuning.zip.enterSpring : tuning.zip.exitSpring
        }

        var adjusted = spec
        adjusted.delay = delay
        return adjusted.resolved(context)
    }

    /// When a leaving row begins its exit, measured from the pill tap.
    static func exitDelay(
        style: FilterStyle,
        tuning: FilterTuning,
        index: Int,
        pitch: Double
    ) -> Double {
        switch style {
        case .sift:
            return tuning.sift.stagger * Double(index)
        case .deal:
            return tuning.deal.stagger * Double(index)
        case .focus:
            // No stagger: this is one plane moving back, not a sequence of rows.
            return 0
        case .zip:
            // Derived from how far the row sits below the pills, so adding rows needs no
            // retuning and the front keeps a constant speed.
            return (Double(index + 1) * pitch) / max(tuning.zip.waveSpeed, 1)
        }
    }

    /// When the list may reclaim the row's slot — always after the exit has done its work, so
    /// a row never appears to squeeze shut while still visible. That is the delete idiom, and
    /// avoiding it is what keeps a filter from reading as data loss.
    static func releaseDelay(
        style: FilterStyle,
        tuning: FilterTuning,
        index: Int,
        pitch: Double
    ) -> Double {
        let exit = exitDelay(style: style, tuning: tuning, index: index, pitch: pitch)
        switch style {
        case .sift:
            return exit + tuning.sift.exitSpring.duration
        case .deal:
            return exit + tuning.deal.exitSpring.duration * 0.55
        case .focus:
            return tuning.focus.ghostFrame
        case .zip:
            return exit + tuning.zip.exitSpring.duration * 0.5
        }
    }
}
