import SwiftUI

#Preview("Interactive · Future") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            initialSelection: PreviewFixtures.date(dayOffset: 12),
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.englishLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
}

#Preview("Today") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.englishLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
}

#Preview("Month Boundary") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            initialSelection: PreviewFixtures.date(dayOffset: 24),
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.englishLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
}

#Preview("Dark") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            initialSelection: PreviewFixtures.date(dayOffset: -8),
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.englishLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Large Type") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            initialSelection: PreviewFixtures.date(dayOffset: 3),
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.englishLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Hebrew · RTL") {
    NavigationStack {
        DateRulerPickerDemo(
            today: PreviewFixtures.today,
            initialSelection: PreviewFixtures.date(dayOffset: 7),
            calendar: PreviewFixtures.calendar,
            locale: PreviewFixtures.hebrewLocale,
            timeZone: PreviewFixtures.timeZone
        )
    }
    .environment(\.locale, PreviewFixtures.hebrewLocale)
    .environment(\.layoutDirection, .rightToLeft)
}
