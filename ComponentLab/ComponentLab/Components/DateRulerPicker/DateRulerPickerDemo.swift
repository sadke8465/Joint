import SwiftUI

struct DateRulerPickerDemo: View {
    private let today: Date
    private let calendar: Calendar
    private let locale: Locale
    private let timeZone: TimeZone
    private let allowedRange: ClosedRange<Date>

    @State private var selection: Date

    init(
        today: Date = .now,
        initialSelection: Date? = nil,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        var configuredCalendar = calendar
        configuredCalendar.locale = locale
        configuredCalendar.timeZone = timeZone

        let normalizedToday = configuredCalendar.startOfDay(for: today)
        let startingDate = configuredCalendar.startOfDay(for: initialSelection ?? normalizedToday)
        let lowerBound = configuredCalendar.date(
            byAdding: .month,
            value: -18,
            to: normalizedToday
        ) ?? normalizedToday
        let upperBound = configuredCalendar.date(
            byAdding: .month,
            value: 18,
            to: normalizedToday
        ) ?? normalizedToday

        self.today = normalizedToday
        self.calendar = configuredCalendar
        self.locale = locale
        self.timeZone = timeZone
        self.allowedRange = lowerBound ... upperBound
        self._selection = State(initialValue: startingDate)
    }

    var body: some View {
        VStack {
            Spacer(minLength: 40)

            DateRulerPicker(
                selection: $selection,
                in: allowedRange,
                today: today,
                calendar: calendar,
                locale: locale,
                timeZone: timeZone
            )

            Spacer(minLength: 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Date Ruler")
        .navigationBarTitleDisplayMode(.inline)
    }
}
