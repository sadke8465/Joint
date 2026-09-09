import Foundation

enum PreviewFixtures {
    static let englishLocale = Locale(identifier: "en_US")
    static let hebrewLocale = Locale(identifier: "he_IL")
    static let timeZone = TimeZone(identifier: "Asia/Jerusalem") ?? .gmt

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = englishLocale
        calendar.timeZone = timeZone
        return calendar
    }

    static let today: Date = {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = 2026
        components.month = 9
        components.day = 7

        guard let date = components.date else {
            preconditionFailure("Unable to create the fixed preview date.")
        }
        return calendar.startOfDay(for: date)
    }()

    static func date(dayOffset: Int) -> Date {
        calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
    }
}
