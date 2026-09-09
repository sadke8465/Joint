import SwiftUI

struct DateRulerPicker: View {
    private enum Metrics {
        static let dayWidth: CGFloat = 52
        static let rulerHeight: CGFloat = 158
        static let selectionWidth: CGFloat = 70
        static let selectionHeight: CGFloat = 138
    }

    private enum CoordinateSpaces {
        static let ruler = "DateRulerPicker.ruler"
    }

    @Binding private var selection: Date

    private let allowedRange: ClosedRange<Date>
    private let today: Date
    private let calendar: Calendar
    private let locale: Locale
    private let timeZone: TimeZone
    private let dates: [Date]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollPosition: Date?

    init(
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        var configuredCalendar = calendar
        configuredCalendar.locale = locale
        configuredCalendar.timeZone = timeZone

        let lowerBound = configuredCalendar.startOfDay(for: range.lowerBound)
        let upperBound = configuredCalendar.startOfDay(for: range.upperBound)
        precondition(lowerBound <= upperBound, "The date ruler range must not be empty.")

        let normalizedRange = lowerBound ... upperBound

        self._selection = selection
        self.allowedRange = normalizedRange
        self.today = configuredCalendar.startOfDay(for: today)
        self.calendar = configuredCalendar
        self.locale = locale
        self.timeZone = timeZone
        self.dates = Self.makeDates(in: normalizedRange, calendar: configuredCalendar)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 28)

            ruler

            VStack(spacing: 5) {
                Text(compactDateText(for: selectedDate))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(relativeDateText(for: selectedDate))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .animation(valueAnimation, value: selectedDate)
            .padding(.top, 22)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            synchronizeFromSelection(animated: false)
        }
        .onChange(of: selection) { _, _ in
            synchronizeFromSelection(animated: true)
        }
        .onChange(of: scrollPosition) { _, newDate in
            guard let newDate else { return }
            let normalizedDate = clampedDate(newDate)
            if selection != normalizedDate {
                selection = normalizedDate
            }
        }
        .sensoryFeedback(.selection, trigger: scrollPosition) { previousDate, newDate in
            previousDate != nil && newDate != nil && previousDate != newDate
        }
    }

    private var selectedDate: Date {
        scrollPosition.map(clampedDate) ?? clampedDate(selection)
    }

    private var valueAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24)
    }

    private var header: some View {
        let monthText = monthAndYearText(for: selectedDate)

        return VStack(spacing: 10) {
            Button {
                move(to: today)
            } label: {
                Text("Today")
                    .font(.headline)
                    .padding(.horizontal, 5)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
            .disabled(!allowedRange.contains(today))
            .accessibilityHint("Moves the picker to today's date.")

            Text(monthText)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
                .contentTransition(.numericText())
                .animation(valueAnimation, value: monthText)
                .frame(height: 30)
        }
    }

    private var ruler: some View {
        GeometryReader { geometry in
            ZStack {
                selectionLens

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(dates, id: \.self) { date in
                            GeometryReader { dayGeometry in
                                let progress = selectionProgress(
                                    dayMidX: dayGeometry.frame(
                                        in: .named(CoordinateSpaces.ruler)
                                    ).midX,
                                    rulerWidth: geometry.size.width
                                )

                                DateRulerDayView(
                                    date: date,
                                    selectionProgress: progress,
                                    isToday: calendar.isDate(date, inSameDayAs: today),
                                    reduceMotion: reduceMotion,
                                    calendar: calendar
                                ) {
                                    move(to: date)
                                }
                            }
                            .frame(width: Metrics.dayWidth, height: Metrics.rulerHeight)
                            .id(date)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $scrollPosition, anchor: .center)
                .contentMargins(
                    .horizontal,
                    max(0, (geometry.size.width - Metrics.dayWidth) / 2),
                    for: .scrollContent
                )
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.12),
                            .init(color: .black, location: 0.88),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .coordinateSpace(name: CoordinateSpaces.ruler)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Date")
            .accessibilityValue(
                "\(accessibilityDateText(for: selectedDate)), \(relativeDateText(for: selectedDate))"
            )
            .accessibilityHint("Swipe up or down to change the date by one day.")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    adjustSelection(by: 1)
                case .decrement:
                    adjustSelection(by: -1)
                @unknown default:
                    break
                }
            }
        }
        .frame(height: Metrics.rulerHeight)
    }

    private func selectionProgress(dayMidX: CGFloat, rulerWidth: CGFloat) -> CGFloat {
        let distanceFromCenter = abs(dayMidX - (rulerWidth / 2))
        let linearProgress = min(max(1 - (distanceFromCenter / Metrics.dayWidth), 0), 1)

        // Smoothstep gives a soft handoff without starting an animation for every date.
        return linearProgress * linearProgress * (3 - (2 * linearProgress))
    }

    private var selectionLens: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.06))
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.09),
                radius: 14,
                y: 5
            )
            .frame(width: Metrics.selectionWidth, height: Metrics.selectionHeight)
            .allowsHitTesting(false)
    }

    private func synchronizeFromSelection(animated: Bool) {
        let target = clampedDate(selection)

        if selection != target {
            selection = target
        }

        guard scrollPosition != target else { return }

        if animated && !reduceMotion {
            withAnimation(.snappy(duration: 0.28)) {
                scrollPosition = target
            }
        } else {
            scrollPosition = target
        }
    }

    private func move(to date: Date) {
        let target = clampedDate(date)
        guard target != scrollPosition else { return }

        if reduceMotion {
            scrollPosition = target
        } else {
            withAnimation(.snappy(duration: 0.28)) {
                scrollPosition = target
            }
        }
    }

    private func adjustSelection(by dayOffset: Int) {
        guard let target = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) else {
            return
        }
        move(to: target)
    }

    private func clampedDate(_ date: Date) -> Date {
        let normalizedDate = calendar.startOfDay(for: date)
        return min(max(normalizedDate, allowedRange.lowerBound), allowedRange.upperBound)
    }

    private func monthAndYearText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter.string(from: date)
    }

    private func compactDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.dateFormat = "MM.dd.yy"
        return formatter.string(from: date)
    }

    private func accessibilityDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMdyyyy")
        return formatter.string(from: date)
    }

    private func relativeDateText(for date: Date) -> String {
        let dayDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full

        let text = formatter.localizedString(from: DateComponents(day: dayDifference))
        return String(text.prefix(1)).uppercased(with: locale) + String(text.dropFirst())
    }

    private static func makeDates(
        in range: ClosedRange<Date>,
        calendar: Calendar
    ) -> [Date] {
        var result: [Date] = []
        var date = range.lowerBound

        while date <= range.upperBound {
            result.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date),
                  nextDate > date else {
                break
            }
            date = nextDate
        }

        return result
    }
}

private struct DateRulerDayView: View {
    let date: Date
    let selectionProgress: CGFloat
    let isToday: Bool
    let reduceMotion: Bool
    let calendar: Calendar
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 7) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .opacity(isToday ? 1 : 0)

                ZStack {
                    Text(dayNumber)
                        .foregroundStyle(.secondary)
                        .opacity(1 - selectionProgress)

                    Text(dayNumber)
                        .foregroundStyle(Color.accentColor)
                        .opacity(selectionProgress)
                }
                .font(.title.weight(.semibold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .scaleEffect(
                    reduceMotion ? 1 : 0.82 + (0.18 * selectionProgress)
                )
            }
            .frame(height: 64, alignment: .bottom)

            Spacer(minLength: 13)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.secondary.opacity(0.28))
                    .frame(width: 2, height: restingTickHeight)
                    .opacity(1 - selectionProgress)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 46)
                    .scaleEffect(
                        x: 1,
                        y: 0.35 + (0.65 * selectionProgress),
                        anchor: .bottom
                    )
                    .opacity(selectionProgress)
            }
            .frame(height: 46, alignment: .bottom)

            Spacer(minLength: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var dayNumber: String {
        String(format: "%02d", calendar.component(.day, from: date))
    }

    private var restingTickHeight: CGFloat {
        if calendar.component(.day, from: date) == 1 {
            return 32
        }
        return calendar.isDateInWeekend(date) ? 24 : 18
    }
}
