import SwiftUI

private typealias Root = MoveDownTuning

private func spring(
    _ label: String,
    _ path: WritableKeyPath<Root, SpringSpec>,
    maxDelay: Double = 0.6
) -> [MoveParam] {
    [
        MoveParam(name: "\(label) · duration", path: path.appending(path: \.duration), range: 0.05...1.2, unit: "s"),
        MoveParam(name: "\(label) · bounce", path: path.appending(path: \.bounce), range: 0...0.8)
    ]
}

private func value(
    _ label: String,
    _ path: WritableKeyPath<Root, Double>,
    _ range: ClosedRange<Double>,
    unit: String = "",
    decimals: Int = 2
) -> MoveParam {
    MoveParam(name: label, path: path, range: range, unit: unit, decimals: decimals)
}

struct MoveParam: Identifiable {
    var id: String { name }
    let name: String
    let path: WritableKeyPath<MoveDownTuning, Double>
    let range: ClosedRange<Double>
    var unit: String = ""
    var decimals: Int = 2
}

struct MoveGroup: Identifiable {
    var id: String { name }
    let name: String
    let params: [MoveParam]
}

extension MoveDownStyle {
    var groups: [MoveGroup] {
        switch self {
        case .closeRanks: MoveCatalog.closeRanks
        case .drop: MoveCatalog.drop
        case .slot: MoveCatalog.slot
        case .undertow: MoveCatalog.undertow
        case .vault: MoveCatalog.vault
        }
    }
}

enum MoveCatalog {
    /// The delay sliders are deliberately absent from the spring helper above: a move-down
    /// spring's delay is always computed from the handoff and the row's role, never stored.
    static var closeRanks: [MoveGroup] { [
        MoveGroup(name: "Mover (deliberately the slower one)", params:
            spring("Mover", \.closeRanks.moverSpring)
        ),
        MoveGroup(name: "Neighbours closing", params:
            spring("Displaced", \.closeRanks.displacedSpring)
            + [value("Stagger per row", \.closeRanks.displacedStagger, 0...0.12, unit: "s", decimals: 3)]
        )
    ] }

    static var drop: [MoveGroup] { [
        MoveGroup(name: "Unlatch", params: [
            value("Duration", \.drop.unlatch, 0...0.3, unit: "s", decimals: 3),
            value("Rise", \.drop.unlatchRise, 0...12, unit: "pt", decimals: 1),
            value("Scale", \.drop.unlatchScale, 1.0...1.1),
            value("Lift shadow radius", \.drop.liftShadowRadius, 0...30, decimals: 1),
            value("Lift shadow opacity", \.drop.liftShadowOpacity, 0...0.4)
        ]),
        MoveGroup(name: "Fall (bounce reads as spring, not gravity)", params:
            spring("Fall", \.drop.fallSpring)
        ),
        MoveGroup(name: "Impact", params:
            [
                value("Squash Y", \.drop.squashY, 0.85...1.0),
                value("Stretch X", \.drop.squashX, 1.0...1.08)
            ]
            + spring("Impact", \.drop.impactSpring)
            + spring("Settle", \.drop.settleSpring)
        ),
        MoveGroup(name: "Contact · shove on rows it passes", params:
            [value("Shove", \.drop.shove, 0...10, unit: "pt", decimals: 1)]
            + spring("Shove", \.drop.shoveSpring)
        )
    ] }

    static var slot: [MoveGroup] { [
        MoveGroup(name: "Lift out", params:
            [
                value("Scale", \.slot.liftScale, 1.0...1.12),
                value("Shadow radius", \.slot.liftShadowRadius, 0...32, decimals: 1),
                value("Shadow opacity", \.slot.liftShadowOpacity, 0...0.4)
            ]
            + spring("Lift", \.slot.liftSpring)
        ),
        MoveGroup(name: "The gap closing behind", params:
            // Without this delay the lift and the close happen together, and the row never
            // reads as a separate object riding above the list.
            [value("Gap delay", \.slot.gapDelay, 0...0.3, unit: "s", decimals: 3)]
            + spring("Gap", \.slot.gapSpring)
        ),
        MoveGroup(name: "Travel", params: spring("Travel", \.slot.travelSpring)),
        MoveGroup(name: "Seat · a detent, not a landing", params:
            spring("Seat", \.slot.seatSpring)
            + spring("Flush", \.slot.flushSpring)
        )
    ] }

    static var vault: [MoveGroup] { [
        MoveGroup(name: "Load · the crouch is the anticipation", params: [
            value("Crouch duration", \.vault.crouch, 0.02...0.3, unit: "s", decimals: 3),
            value("Crouch drop", \.vault.crouchDrop, 0...8, unit: "pt", decimals: 1),
            value("Crouch squash Y", \.vault.crouchScaleY, 0.85...1.0),
            value("Crouch stretch X", \.vault.crouchScaleX, 1.0...1.1)
        ]),
        MoveGroup(name: "Arc · keep it small to stay subtle", params:
            [
                value("Hop height", \.vault.hopHeight, 0...50, unit: "pt", decimals: 1),
                value("Lateral swing", \.vault.lateral, 0...30, unit: "pt", decimals: 1),
                value("Apex stretch Y", \.vault.apexScaleY, 1.0...1.12),
                value("Apex narrow X", \.vault.apexScaleX, 0.9...1.0),
                value("Arc shadow radius", \.vault.arcShadowRadius, 0...36, decimals: 1),
                value("Arc shadow opacity", \.vault.arcShadowOpacity, 0...0.4)
            ]
            + spring("Launch", \.vault.launchSpring)
            + spring("Travel", \.vault.travelSpring)
        ),
        MoveGroup(name: "Landing", params:
            [
                value("Land squash Y", \.vault.landSquashY, 0.85...1.0),
                value("Land stretch X", \.vault.landStretchX, 1.0...1.08)
            ]
            + spring("Land", \.vault.landSpring)
            + spring("Settle", \.vault.settleSpring)
        ),
        MoveGroup(name: "Others stagger back into place", params:
            [value("Stagger back", \.vault.staggerBack, 0...0.2, unit: "s", decimals: 3)]
            + spring("Displaced", \.vault.displacedSpring)
            + [value("Duck as it passes over", \.vault.duck, 0...8, unit: "pt", decimals: 1)]
            + spring("Duck", \.vault.duckSpring)
        )
    ] }

    static var undertow: [MoveGroup] { [
        MoveGroup(name: "Submerge", params:
            [
                value("Scale", \.undertow.submergeScale, 0.82...1.0),
                value("Opacity", \.undertow.submergeOpacity, 0.4...1.0),
                value("Blur", \.undertow.submergeBlur, 0...4, decimals: 2)
            ]
            + spring("Submerge", \.undertow.submergeSpring)
        ),
        MoveGroup(name: "Travel beneath", params: spring("Travel", \.undertow.travelSpring)),
        MoveGroup(name: "Surface", params:
            [value("Rest scale", \.undertow.restScale, 0.94...1.0)]
            + spring("Surface", \.undertow.surfaceSpring)
        ),
        MoveGroup(name: "Neighbours (plain on purpose)", params:
            spring("Displaced", \.undertow.displacedSpring)
        )
    ] }
}
