import SwiftUI

private typealias Root = FilterTuning

private func spring(_ label: String, _ path: WritableKeyPath<Root, SpringSpec>) -> [FilterParam] {
    [
        FilterParam(name: "\(label) · duration", path: path.appending(path: \.duration), range: 0.05...1.2, unit: "s"),
        FilterParam(name: "\(label) · bounce", path: path.appending(path: \.bounce), range: 0...0.8)
    ]
}

private func value(
    _ label: String,
    _ path: WritableKeyPath<Root, Double>,
    _ range: ClosedRange<Double>,
    unit: String = "",
    decimals: Int = 2
) -> FilterParam {
    FilterParam(name: label, path: path, range: range, unit: unit, decimals: decimals)
}

struct FilterParam: Identifiable {
    var id: String { name }
    let name: String
    let path: WritableKeyPath<FilterTuning, Double>
    let range: ClosedRange<Double>
    var unit: String = ""
    var decimals: Int = 2
}

struct FilterGroup: Identifiable {
    var id: String { name }
    let name: String
    let params: [FilterParam]
}

extension FilterStyle {
    var groups: [FilterGroup] {
        switch self {
        case .sift: FilterCatalog.sift
        case .deal: FilterCatalog.deal
        case .focus: FilterCatalog.focus
        case .zip: FilterCatalog.zip
        }
    }
}

enum FilterCatalog {
    static var shared: [FilterGroup] { [
        FilterGroup(name: "Pills · the causal origin", params:
            [value("Press scale", \.shared.pillPress, 0.85...1.0)]
            + spring("Pill", \.shared.pillSpring)
            + spring("Indicator", \.shared.indicatorSpring)
            + [value("Indicator leads list by", \.shared.indicatorLead, 0...0.2, unit: "s", decimals: 3)]
        ),
        FilterGroup(name: "Container", params:
            spring("Height", \.shared.heightSpring)
            + [value("Grace for in-flight completion", \.shared.filterGrace, 0...0.6, unit: "s", decimals: 3)]
        )
    ] }

    static var sift: [FilterGroup] { [
        FilterGroup(name: "Exit · fast, so you barely register it", params:
            spring("Exit", \.sift.exitSpring)
            + [
                value("Exit scale", \.sift.exitScale, 0.85...1.0),
                value("Stagger", \.sift.stagger, 0...0.1, unit: "s", decimals: 3)
            ]
        ),
        FilterGroup(name: "Enter", params: spring("Enter", \.sift.enterSpring))
    ] }

    static var deal: [FilterGroup] { [
        FilterGroup(name: "Flick out", params:
            [
                value("Distance", \.deal.distance, 100...700, unit: "pt", decimals: 0),
                value("Rotation", \.deal.rotation, 0...15, unit: "°", decimals: 1),
                value("Stagger", \.deal.stagger, 0...0.2, unit: "s", decimals: 3)
            ]
            + spring("Exit", \.deal.exitSpring)
        ),
        FilterGroup(name: "Deal back in", params: spring("Enter", \.deal.enterSpring)),
        FilterGroup(name: "Contact", params: [
            value("Wobble on rows it passes", \.deal.wobble, 0...12, unit: "pt", decimals: 1)
        ])
    ] }

    static var focus: [FilterGroup] { [
        FilterGroup(name: "Recede", params:
            [
                value("Scale", \.focus.scale, 0.6...1.0),
                value("Blur", \.focus.blur, 0...8, decimals: 2)
            ]
            + spring("Recede", \.focus.recedeSpring)
        ),
        FilterGroup(name: "Ghost frame · why it can't read as deletion", params: [
            value("Hold before closing", \.focus.ghostFrame, 0...0.8, unit: "s", decimals: 3)
        ]),
        FilterGroup(name: "Come forward", params: spring("Enter", \.focus.enterSpring))
    ] }

    static var zip: [FilterGroup] { [
        FilterGroup(name: "Wavefront · stagger is derived, not stored", params: [
            value("Wave speed", \.zip.waveSpeed, 200...4000, unit: "pt/s", decimals: 0),
            value("Slide", \.zip.slide, 0...200, unit: "pt", decimals: 0)
        ]),
        FilterGroup(name: "Exit", params: spring("Exit", \.zip.exitSpring)),
        FilterGroup(name: "Enter", params: spring("Enter", \.zip.enterSpring))
    ] }
}
