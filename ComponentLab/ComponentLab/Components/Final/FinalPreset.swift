import Foundation

/// The settled pairing: Stamp completion, Close Ranks move-down.
///
/// Values are your exported tuning, rounded to numbers worth reading. Two of them are worth
/// knowing about:
///
/// - `moverSpring` is *faster* than `displacedSpring` here (0.13s against 1.2s), inverting
///   the default where the mover trailed its neighbours. The completed row is pulled away
///   and the list reflows slowly behind it — which is exactly why the mover needs to sit
///   above the others.
/// - The handoff is 1.5s, and it is a *debounced window for the whole list* rather than a
///   per-row delay: the reorder waits well past Stamp finishing, so completing and filing read
///   as two separate events rather than one long one — and a burst of taps files in one move
///   once the tapping stops.
enum FinalPreset {
    static let completionStyle = TaskCompletionStyle.stamp
    static let moveStyle = MoveDownStyle.closeRanks

    static let options = CompletionOptions(strikeSweepsHorizontally: true)

    static var completion: TaskCompletionTuning {
        var tuning = TaskCompletionTuning()

        tuning.stamp.pressScale = 0.98
        tuning.stamp.pressSpring = SpringSpec(0.24, bounce: 0.45)
        tuning.stamp.pressBrightness = -0.03
        tuning.stamp.shadowCollapse = 0.70

        tuning.stamp.reboundSpring = SpringSpec(0.31, bounce: 0.69, delay: 0.12)

        tuning.stamp.fillSpring = SpringSpec(0.24, bounce: 0)
        tuning.stamp.checkSpring = SpringSpec(0.27, bounce: 0.16, delay: 0.10)
        tuning.stamp.checkPunch = 1.40
        tuning.stamp.checkWeight = 2.0

        // Tuned while the line still opened in Y. As a left-to-right sweep 0.11s is very
        // quick — near enough to appearing outright — so this is the first knob to reach for.
        tuning.stamp.strikeSpring = SpringSpec(0.11, bounce: 0, delay: 0.23)
        tuning.stamp.strikeWeight = 2.0
        tuning.stamp.titleSpring = SpringSpec(0.30, bounce: 0, delay: 0.17)
        tuning.stamp.greyOpacity = 0.5

        tuning.stamp.dueTravel = 5.0
        tuning.stamp.dueSpring = SpringSpec(0.20, bounce: 0.35, delay: 0.20)
        tuning.stamp.cardSpring = SpringSpec(0.50, bounce: 0.30)

        return tuning
    }

    static var moveDown: MoveDownTuning {
        var tuning = MoveDownTuning()
        // Stamp settles at ~0.65s, so this leaves the completed row visibly done and sitting
        // still for most of a second before it sinks. Measured from the last commit, not the
        // first: tap three rows and all three sink 1.5s after the third.
        tuning.handoff.stamp = 1.50
        tuning.closeRanks.moverSpring = SpringSpec(0.13, bounce: 0.80)
        tuning.closeRanks.displacedSpring = SpringSpec(1.20, bounce: 0.80)
        tuning.closeRanks.displacedStagger = 0.12
        return tuning
    }
}
