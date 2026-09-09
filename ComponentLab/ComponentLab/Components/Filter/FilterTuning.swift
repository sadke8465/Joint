import SwiftUI

struct FilterTuning: Codable, Equatable, Sendable {
    var shared = SharedFilterTuning()
    var sift = SiftTuning()
    var deal = DealTuning()
    var focus = FocusTuning()
    var zip = ZipTuning()

    init() {}

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shared = (try? container.decode(SharedFilterTuning.self, forKey: .shared)) ?? .init()
        sift = (try? container.decode(SiftTuning.self, forKey: .sift)) ?? .init()
        deal = (try? container.decode(DealTuning.self, forKey: .deal)) ?? .init()
        focus = (try? container.decode(FocusTuning.self, forKey: .focus)) ?? .init()
        zip = (try? container.decode(ZipTuning.self, forKey: .zip)) ?? .init()
    }
}

struct SharedFilterTuning: Codable, Equatable, Sendable {
    /// The pills are the causal origin, so they move first and the list follows.
    var pillPress = 0.94
    var pillSpring = SpringSpec(0.30, bounce: 0.40)
    var indicatorSpring = SpringSpec(0.34, bounce: 0.30)
    var indicatorLead = 0.04

    /// Dropping ten rows to three shrinks the list by roughly 450pt. Without this the content
    /// below it snaps.
    var heightSpring = SpringSpec(0.50, bounce: 0.20)

    /// A row whose completion is still animating is held this long before it is allowed to
    /// leave, so a checkmark is never cut off mid-draw. 0 lets the filter win outright.
    var filterGrace = 0.18

}

// MARK: - 1. Sift (subtle)

struct SiftTuning: Codable, Equatable, Sendable {
    /// Fast exit, slow close. You barely register the leaving; what you see is the arriving.
    var exitSpring = SpringSpec(0.15, bounce: 0.0)
    var exitScale = 0.97
    var stagger = 0.02
    var enterSpring = SpringSpec(0.28, bounce: 0.20)
}

// MARK: - 2. Deal (physical)

struct DealTuning: Codable, Equatable, Sendable {
    var distance = 420.0
    var rotation = 3.0
    var exitSpring = SpringSpec(0.34, bounce: 0.0)
    var stagger = 0.05
    var enterSpring = SpringSpec(0.40, bounce: 0.35)
    /// Rows that stay get nudged as their neighbour is flicked past them.
    var wobble = 3.0
}

// MARK: - 3. Focus (depth)

struct FocusTuning: Codable, Equatable, Sendable {
    var scale = 0.88
    var blur = 2.0
    var recedeSpring = SpringSpec(0.18, bounce: 0.0)
    /// The readable intermediate frame: the whole list visible, non-matching rows ghosted
    /// behind. It is the entire reason this style cannot be misread as a deletion.
    var ghostFrame = 0.18
    var enterSpring = SpringSpec(0.34, bounce: 0.25)
}

// MARK: - 4. Zip (wavefront)

struct ZipTuning: Codable, Equatable, Sendable {
    /// Points per second. Every row's stagger is derived from its distance below the pills,
    /// so the choreography re-times itself for any list length.
    var waveSpeed = 1400.0
    var slide = 60.0
    var exitSpring = SpringSpec(0.22, bounce: 0.0)
    var enterSpring = SpringSpec(0.30, bounce: 0.30)
}
