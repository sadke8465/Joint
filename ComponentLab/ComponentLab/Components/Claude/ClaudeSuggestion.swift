import Foundation

/// One opinionated stack across all three parts.
///
/// It is not a rejection of your preset — it keeps both of your structural instincts, which
/// were right, and changes the numbers that were fighting them:
///
/// 1. **Stamp with a sweeping strike.** Your two choices together are a genuine synthesis:
///    Stamp's press-and-rebound is the best tap feel here because the compression lasts
///    exactly as long as your finger, and a left-to-right line is the correct metaphor for
///    crossing something off. The only problem was that 0.11s was tuned when the line still
///    opened in Y; as a sweep it barely reads. Lengthened, and given a little bounce so the
///    pen has follow-through.
///
/// 2. **Close Ranks with your inversion kept.** Your fast-mover / slow-neighbours profile is
///    better than my original for a thirty-times-a-day action: the finished row gets out of
///    the way so your eye is not dragged along with it. But 0.13s reads as a jump cut and
///    1.2s at bounce 0.8 rings for over seven seconds. Tempered in both directions, still
///    inverted.
///
/// 3. **Focus for filtering.** Filtering is rare compared with completing, and a rare action
///    can afford to explain itself. The ghost frame makes "filtered, not deleted" unmissable
///    — which is the one misreading that actually costs you in a to-do app.
enum ClaudeSuggestion {
    static let completionStyle = TaskCompletionStyle.stamp
    static let moveStyle = MoveDownStyle.closeRanks
    static let filterStyle = FilterStyle.focus
    static let options = CompletionOptions(strikeSweepsHorizontally: true)
    static let moverPlane: Double = 10

    // MARK: Completion

    static var completion: TaskCompletionTuning {
        var tuning = TaskCompletionTuning()

        // Down fast and dead, up slow and springy. All the energy belongs to the rebound;
        // a bouncy press muddies the moment of contact.
        tuning.stamp.pressScale = 0.98
        tuning.stamp.pressSpring = SpringSpec(0.16, bounce: 0.0)
        tuning.stamp.pressBrightness = -0.03
        tuning.stamp.shadowCollapse = 0.70
        tuning.stamp.reboundSpring = SpringSpec(0.34, bounce: 0.55, delay: 0.12)

        tuning.stamp.fillSpring = SpringSpec(0.24, bounce: 0.0)
        tuning.stamp.checkSpring = SpringSpec(0.28, bounce: 0.14, delay: 0.08)
        tuning.stamp.checkPunch = 1.35
        tuning.stamp.checkWeight = 2.0

        // The change that matters. A sweep needs time to be seen crossing the title, and a
        // little bounce so it overshoots the last glyph and pulls back the way a pen does.
        // Grey runs on the identical spring so the text cannot grey ahead of or behind it.
        tuning.stamp.strikeSpring = SpringSpec(0.30, bounce: 0.22, delay: 0.16)
        tuning.stamp.titleSpring = SpringSpec(0.30, bounce: 0.22, delay: 0.16)
        tuning.stamp.strikeWeight = 1.8
        tuning.stamp.greyOpacity = 0.5

        // Lands just after the strike finishes, so the row reads as one sentence rather than
        // two things happening at once.
        tuning.stamp.dueTravel = 5.0
        tuning.stamp.dueSpring = SpringSpec(0.28, bounce: 0.30, delay: 0.26)
        tuning.stamp.cardSpring = SpringSpec(0.50, bounce: 0.30)

        return tuning
    }

    // MARK: Move down

    static var moveDown: MoveDownTuning {
        var tuning = MoveDownTuning()

        // Stamp settles at ~0.54s. This leaves roughly half a second of the row sitting
        // visibly done before it files itself — long enough to read as two separate events,
        // short enough that it never feels like lag.
        tuning.handoff.stamp = 1.15

        // Still your inversion: the mover leaves faster than the list closes. Just not a jump
        // cut, and no longer ringing long after you have moved on.
        tuning.closeRanks.moverSpring = SpringSpec(0.30, bounce: 0.18)
        tuning.closeRanks.displacedSpring = SpringSpec(0.55, bounce: 0.32)
        tuning.closeRanks.displacedStagger = 0.05

        return tuning
    }

    // MARK: Filtering

    static var filter: FilterTuning {
        var tuning = FilterTuning()

        tuning.shared.pillPress = 0.94
        tuning.shared.pillSpring = SpringSpec(0.28, bounce: 0.38)
        tuning.shared.indicatorSpring = SpringSpec(0.32, bounce: 0.28)
        tuning.shared.indicatorLead = 0.04
        tuning.shared.heightSpring = SpringSpec(0.48, bounce: 0.16)
        tuning.shared.filterGrace = 0.16

        // Shorter than my first pass: long enough to register the ghosts, short enough that
        // the list does not feel like it hesitated.
        tuning.focus.ghostFrame = 0.14
        tuning.focus.scale = 0.90
        tuning.focus.blur = 1.6
        tuning.focus.recedeSpring = SpringSpec(0.20, bounce: 0.0)
        tuning.focus.enterSpring = SpringSpec(0.34, bounce: 0.22)

        return tuning
    }

    // MARK: Rationale, for the panel

    static let notes: [(String, String)] = [
        ("Strike 0.11s → 0.30s",
         "Tuned when the line still opened in Y, where fast is right. As a left-to-right sweep it barely read. Bounce 0.22 gives the pen follow-through past the last glyph."),
        ("Press bounce 0.45 → 0",
         "Down fast and dead, up slow and springy. A bouncy press competes with the rebound for the moment of contact."),
        ("Rebound bounce 0.69 → 0.55",
         "0.69 overshoots about 4%, which starts to read as wobble rather than snap."),
        ("Reflow 1.2s / 0.8 → 0.55s / 0.32",
         "Both sliders were at maximum and the list visibly rang for over seven seconds after three quick taps. Same character, settles in under one."),
        ("Mover 0.13s → 0.30s",
         "Your inversion is right — the finished row should leave before the list reflows — but 0.13s is a jump cut rather than a move."),
        ("Handoff 1.3s → 1.15s",
         "Still a clear pause after completion, with less dead air.")
    ]
}
