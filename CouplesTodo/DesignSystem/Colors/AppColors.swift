import SwiftUI

enum AppColors {
    static let canvas = Color(red: 0.976, green: 0.965, blue: 0.941)
    static let groupedBackground = Color(red: 0.941, green: 0.925, blue: 0.894)
    static let surface = Color(red: 1.000, green: 0.995, blue: 0.980)
    static let elevatedSurface = Color.white
    static let heroSurface = Color(red: 0.925, green: 0.910, blue: 0.965)

    static let primaryText = Color(red: 0.118, green: 0.106, blue: 0.086)
    static let secondaryText = Color(red: 0.360, green: 0.337, blue: 0.298)
    static let tertiaryText = Color(red: 0.420, green: 0.396, blue: 0.353)
    static let separator = Color(red: 0.855, green: 0.824, blue: 0.761)
    static let border = separator

    static let accent = Color(red: 0.157, green: 0.298, blue: 0.620)
    static let playBlue = Color(red: 0.298, green: 0.518, blue: 0.749)
    static let success = Color(red: 0.176, green: 0.467, blue: 0.345)
    static let turquoise = Color(red: 0.208, green: 0.557, blue: 0.490)
    static let violet = Color(red: 0.427, green: 0.337, blue: 0.682)
    static let coral = Color(red: 0.839, green: 0.388, blue: 0.298)
    static let amber = Color(red: 0.878, green: 0.627, blue: 0.188)
    static let pink = Color(red: 0.718, green: 0.278, blue: 0.447)
    static let danger = Color(red: 0.698, green: 0.157, blue: 0.212)

    static let background = canvas
    static let accentSoft = accent.opacity(0.10)
    static let controlBackground = groupedBackground
    static let divider = separator
    static let destructive = danger
}
