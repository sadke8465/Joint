import SwiftUI

enum AppTypography {
    static let hero = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let screenTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let dateHero = Font.system(.title, design: .serif, weight: .bold)
    static let sectionTitle = Font.system(.title3, design: .serif, weight: .bold)
    static let taskTitle = Font.system(.body, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default)
    static let metadata = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.footnote, design: .rounded, weight: .semibold)
    static let button = Font.system(.body, design: .rounded, weight: .bold)
}
