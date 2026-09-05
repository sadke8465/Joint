import SwiftUI

enum AppMotion {
    static func selection(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .smooth(duration: 0.18)
    }

    static func content(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: 0.25)
    }
}
