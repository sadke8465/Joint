import SwiftUI

// MARK: - Descriptors

struct TuningParam: Identifiable {
    var id: String { name }
    let name: String
    let path: WritableKeyPath<TaskCompletionTuning, Double>
    let range: ClosedRange<Double>
    var unit: String = ""
    var decimals: Int = 2
}

struct TuningGroup: Identifiable {
    var id: String { name }
    let name: String
    let params: [TuningParam]
}

private typealias Root = TaskCompletionTuning

/// Every spring is three knobs. Expanding them from one key path keeps the ranges
/// consistent and means adding a spring to a style is a one-line change here.
private func spring(
    _ label: String,
    _ path: WritableKeyPath<Root, SpringSpec>,
    maxDelay: Double = 0.6
) -> [TuningParam] {
    [
        TuningParam(name: "\(label) · duration", path: path.appending(path: \.duration), range: 0.05...1.2, unit: "s"),
        TuningParam(name: "\(label) · bounce", path: path.appending(path: \.bounce), range: 0...0.8),
        TuningParam(name: "\(label) · delay", path: path.appending(path: \.delay), range: 0...maxDelay, unit: "s")
    ]
}

private func value(
    _ label: String,
    _ path: WritableKeyPath<Root, Double>,
    _ range: ClosedRange<Double>,
    unit: String = "",
    decimals: Int = 2
) -> TuningParam {
    TuningParam(name: label, path: path, range: range, unit: unit, decimals: decimals)
}

// MARK: - Per style

extension TaskCompletionStyle {
    var groups: [TuningGroup] {
        switch self {
        case .strikeCascade: TuningCatalog.strikeCascade
        case .stamp: TuningCatalog.stamp
        case .liquidMetal: TuningCatalog.liquidMetal
        case .settleRecede: TuningCatalog.settleRecede
        case .swell: TuningCatalog.swell
        }
    }
}

enum TuningCatalog {
    static var strikeCascade: [TuningGroup] { [
        TuningGroup(name: "Impulse", params:
            [value("Press scale", \.strike.pressScale, 0.75...1.0)]
            + spring("Checkbox", \.strike.checkboxSpring)
            + spring("Fill", \.strike.fillSpring)
        ),
        TuningGroup(name: "Commit · checkmark", params:
            [
                value("Punch from", \.strike.checkPunch, 1.0...2.0),
                value("Stroke weight", \.strike.checkWeight, 0.5...4.0, unit: "pt")
            ]
            + spring("Draw", \.strike.checkSpring)
        ),
        TuningGroup(name: "Propagation · strike + grey", params:
            spring("Strike", \.strike.strikeSpring)
            + [
                value("Line weight", \.strike.strikeWeight, 0.5...4.0, unit: "pt"),
                value("Trailing overhang", \.strike.strikeTrailing, 0...12, unit: "pt", decimals: 1),
                value("Grey opacity", \.strike.greyOpacity, 0.2...1.0)
            ]
        ),
        TuningGroup(name: "Settle · due date", params:
            [value("Travel", \.strike.dueTravel, 0...20, unit: "pt", decimals: 1)]
            + spring("Out", \.strike.dueOutSpring)
            + spring("In", \.strike.dueInSpring)
        ),
        TuningGroup(name: "Card", params:
            [value("Settle scale", \.strike.cardSettleScale, 0.94...1.0)]
            + spring("Card", \.strike.cardSpring)
        )
    ] }

    static var stamp: [TuningGroup] { [
        TuningGroup(name: "Press", params:
            [
                value("Press scale", \.stamp.pressScale, 0.88...1.0),
                value("Brightness", \.stamp.pressBrightness, -0.2...0.0),
                value("Shadow collapse", \.stamp.shadowCollapse, 0...1)
            ]
            + spring("Press", \.stamp.pressSpring)
        ),
        TuningGroup(name: "Rebound", params:
            // The 1.025 overshoot is the bounce, not a target. Raise bounce, not a scale.
            spring("Rebound", \.stamp.reboundSpring)
        ),
        TuningGroup(name: "Commit · checkmark", params:
            [
                value("Punch from", \.stamp.checkPunch, 1.0...2.5),
                value("Stroke weight", \.stamp.checkWeight, 0.5...4.0, unit: "pt")
            ]
            + spring("Draw", \.stamp.checkSpring)
            + spring("Fill", \.stamp.fillSpring)
        ),
        TuningGroup(name: "Strike + title", params:
            spring("Strike (scale Y)", \.stamp.strikeSpring)
            + [value("Line weight", \.stamp.strikeWeight, 0.5...4.0, unit: "pt")]
            + spring("Title grey", \.stamp.titleSpring)
            + [value("Grey opacity", \.stamp.greyOpacity, 0.2...1.0)]
        ),
        TuningGroup(name: "Due date", params:
            [value("Travel", \.stamp.dueTravel, 0...24, unit: "pt", decimals: 1)]
            + spring("Swap", \.stamp.dueSpring)
        )
    ] }

    static var liquidMetal: [TuningGroup] { [
        TuningGroup(name: "Band", params:
            spring("Band", \.metal.bandSpring)
            + [
                value("Width", \.metal.bandWidth, 0.05...1.0),
                value("Softness", \.metal.bandSoftness, 0.1...6.0),
                value("Tilt", \.metal.bandTilt, -0.8...0.8, unit: "rad")
            ]
        ),
        TuningGroup(name: "Light (its own, slower clock)", params:
            spring("Light", \.metal.lightSpring)
            + [
                value("Angle start", \.metal.lightAngleStart, 0...6.28, unit: "rad"),
                value("Angle end", \.metal.lightAngleEnd, 0...6.28, unit: "rad")
            ]
        ),
        TuningGroup(name: "Material", params: [
            value("Metalness", \.metal.metalness, 0...1),
            value("Roughness", \.metal.roughness, 0...1),
            value("Height scale", \.metal.heightScale, 0...40, decimals: 1),
            value("Refraction", \.metal.refraction, 0...10, decimals: 1)
        ]),
        TuningGroup(name: "Row", params:
            spring("Checkmark", \.metal.checkSpring)
            + spring("Fill", \.metal.fillSpring)
            + [
                value("Check weight", \.metal.checkWeight, 0.5...4.0, unit: "pt"),
                value("Line weight", \.metal.strikeWeight, 0.5...4.0, unit: "pt"),
                value("Grey opacity", \.metal.greyOpacity, 0.2...1.0),
                value("Due travel", \.metal.dueTravel, 0...20, unit: "pt", decimals: 1)
            ]
            + spring("Due", \.metal.dueSpring)
        )
    ] }

    static var settleRecede: [TuningGroup] { [
        TuningGroup(name: "Tip", params:
            [
                value("Tip angle", \.recede.tipAngle, -25...0, unit: "°", decimals: 1),
                value("Perspective", \.recede.perspective, 0.1...1.5),
                value("Brightness", \.recede.tipBrightness, -0.25...0)
            ]
            + spring("Tip", \.recede.tipSpring)
            + spring("Return", \.recede.returnSpring)
        ),
        TuningGroup(name: "Light (rule 3: shadow trails geometry)", params: [
            value("Shadow lag", \.recede.shadowLag, 0...0.15, unit: "s", decimals: 3),
            value("Rest radius", \.recede.shadowRestRadius, 0...30, decimals: 1),
            value("Tip radius", \.recede.shadowTipRadius, 0...40, decimals: 1),
            value("Rest Y", \.recede.shadowRestY, 0...20, decimals: 1),
            value("Tip Y", \.recede.shadowTipY, 0...30, decimals: 1)
        ]),
        TuningGroup(name: "Commit", params:
            spring("Checkmark", \.recede.checkSpring)
            + spring("Fill", \.recede.fillSpring)
            + spring("Strike", \.recede.strikeSpring)
            + [
                value("Check weight", \.recede.checkWeight, 0.5...4.0, unit: "pt"),
                value("Line weight", \.recede.strikeWeight, 0.5...4.0, unit: "pt"),
                value("Grey opacity", \.recede.greyOpacity, 0.2...1.0),
                value("Due blur", \.recede.dueBlur, 0...12, decimals: 1)
            ]
            + spring("Due", \.recede.dueSpring)
        ),
        TuningGroup(name: "Rest · lower in the stack", params:
            [
                value("Rest scale", \.recede.restScale, 0.9...1.0),
                value("Rest opacity", \.recede.restOpacity, 0.3...1.0),
                value("Rest shadow", \.recede.restShadowRadius, 0...20, decimals: 1)
            ]
            + spring("Rest", \.recede.restSpring, maxDelay: 1.0)
        )
    ] }

    static var swell: [TuningGroup] { [
        TuningGroup(name: "Wave · subtle and large", params: [
            value("Amplitude", \.swell.amplitude, 0...12, unit: "pt", decimals: 1),
            value("Wavelength", \.swell.wavelength, 120...1400, unit: "pt", decimals: 0),
            value("Speed", \.swell.speed, 200...1600, unit: "pt/s", decimals: 0),
            value("Decay", \.swell.decay, 1...12, decimals: 1),
            value("Front softness", \.swell.frontSoftness, 0.005...0.4, unit: "s", decimals: 3),
            value("Edge gain", \.swell.edgeGain, 0...2),
            value("Crest highlight", \.swell.crestHighlight, 0...0.25),
            value("Wave duration", \.swell.waveDuration, 0.3...2.0, unit: "s")
        ]),
        TuningGroup(name: "Origin", params: [
            value("Nudge X", \.swell.originNudgeX, -80...80, unit: "pt", decimals: 0),
            value("Nudge Y", \.swell.originNudgeY, -60...60, unit: "pt", decimals: 0)
        ]),
        TuningGroup(name: "Pebble", params:
            [
                value("Checkbox pulse", \.swell.checkboxPulse, 1.0...1.25),
                value("Check weight", \.swell.checkWeight, 0.5...4.0, unit: "pt")
            ]
            + spring("Checkbox", \.swell.checkboxSpring)
            + spring("Checkmark", \.swell.checkSpring)
            + spring("Fill", \.swell.fillSpring)
        ),
        // No delay sliders here on purpose: every stagger below is derived at runtime from
        // distance / speed. Change "Speed" above and the whole choreography re-times itself.
        TuningGroup(name: "Wake (stagger is derived, not stored)", params:
            spring("Strike", \.swell.strikeSpring, maxDelay: 0.01)
            + [
                value("Line weight", \.swell.strikeWeight, 0.5...4.0, unit: "pt"),
                value("Grey opacity", \.swell.greyOpacity, 0.2...1.0)
            ]
            + spring("Title grey", \.swell.titleSpring, maxDelay: 0.01)
            + [value("Due travel", \.swell.dueTravel, 0...20, unit: "pt", decimals: 1)]
            + spring("Due", \.swell.dueSpring, maxDelay: 0.01)
            + [value("Assignee pulse", \.swell.assigneePulse, 1.0...1.3)]
            + spring("Assignee", \.swell.assigneeSpring, maxDelay: 0.01)
        ),
        TuningGroup(name: "Card", params:
            [value("Press scale", \.swell.pressScale, 0.94...1.0)]
            + spring("Card", \.swell.cardSpring)
        )
    ] }
}
