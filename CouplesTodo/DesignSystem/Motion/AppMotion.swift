import SwiftUI

enum AppMotion {
    static func selection(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .smooth(duration: 0.2)
    }

    static func content(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: 0.28, bounce: 0.16)
    }
}
