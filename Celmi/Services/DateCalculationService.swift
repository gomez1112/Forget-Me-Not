import Foundation

struct DateCalculationService: Sendable {
    enum LeapDayPolicy: Sendable {
        case useFebruary28
        case useMarch1
    }

    var calendar: Calendar
    var leapDayPolicy: LeapDayPolicy

    init(calendar: Calendar = .current, leapDayPolicy: LeapDayPolicy = .useFebruary28) {
        self.calendar = calendar
        self.leapDayPolicy = leapDayPolicy
    }

    func nextOccurrence(month: Int, day: Int, from date: Date = Date()) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: startOfDay)

        if let occurrence = occurrence(month: month, day: day, year: year),
           occurrence >= startOfDay {
            return occurrence
        }

        return occurrence(month: month, day: day, year: year + 1) ?? startOfDay
    }

    func daysRemaining(month: Int, day: Int, from date: Date = Date()) -> Int {
        let start = calendar.startOfDay(for: date)
        let next = nextOccurrence(month: month, day: day, from: start)
        return calendar.dateComponents([.day], from: start, to: next).day ?? 0
    }

    func nextOccurrence(for specialDate: SpecialDate, from date: Date = Date()) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)

        switch specialDate.recurrence {
        case .yearly:
            return nextOccurrence(month: specialDate.month, day: specialDate.day, from: startOfDay)
        case .monthly:
            return nextMonthlyOccurrence(day: specialDate.day, from: startOfDay)
        case .oneTime:
            guard let year = specialDate.year,
                  let occurrence = occurrence(month: specialDate.month, day: specialDate.day, year: year),
                  occurrence >= startOfDay
            else {
                return nil
            }
            return occurrence
        case .custom:
            guard let year = specialDate.year,
                  let interval = specialDate.customRecurrenceDays,
                  interval > 0,
                  let firstOccurrence = occurrence(month: specialDate.month, day: specialDate.day, year: year)
            else {
                return nextOccurrence(month: specialDate.month, day: specialDate.day, from: startOfDay)
            }

            if firstOccurrence >= startOfDay {
                return firstOccurrence
            }

            let elapsedDays = calendar.dateComponents([.day], from: firstOccurrence, to: startOfDay).day ?? 0
            var cycleCount = max(1, Int(ceil(Double(elapsedDays) / Double(interval))))
            var candidate = calendar.date(byAdding: .day, value: cycleCount * interval, to: firstOccurrence)

            while let candidateDate = candidate, candidateDate < startOfDay {
                cycleCount += 1
                candidate = calendar.date(byAdding: .day, value: cycleCount * interval, to: firstOccurrence)
            }

            return candidate
        }
    }

    func daysRemaining(for specialDate: SpecialDate, from date: Date = Date()) -> Int? {
        guard let next = nextOccurrence(for: specialDate, from: date) else { return nil }
        let start = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: next).day
    }

    func age(on occurrence: Date, birthYear: Int?) -> Int? {
        guard let birthYear else { return nil }
        return max(0, calendar.component(.year, from: occurrence) - birthYear)
    }

    func anniversaryCount(on occurrence: Date, startYear: Int?) -> Int? {
        age(on: occurrence, birthYear: startYear)
    }

    func formattedRelativeDays(_ days: Int) -> String {
        switch days {
        case 0:
            "Today"
        case 1:
            "Tomorrow"
        case 2..<7:
            "in \(days) days"
        case 7:
            "in 1 week"
        case 8..<31:
            "in \(days) days"
        default:
            "in \(days) days"
        }
    }

    func notificationDate(
        for specialDate: SpecialDate,
        daysBefore: Int,
        hour: Int,
        minute: Int,
        from date: Date = Date()
    ) -> Date? {
        var searchDate = date

        for _ in 0..<240 {
            guard let occurrence = nextOccurrence(for: specialDate, from: searchDate) else { return nil }
            let reminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: occurrence) ?? occurrence
            let components = calendar.dateComponents([.year, .month, .day], from: reminderDay)
            let candidate = calendar.date(from: DateComponents(
                calendar: calendar,
                year: components.year,
                month: components.month,
                day: components.day,
                hour: hour,
                minute: minute
            )) ?? reminderDay

            if candidate >= date {
                return candidate
            }

            guard specialDate.recurrence != .oneTime else {
                return nil
            }

            searchDate = calendar.date(byAdding: .day, value: 1, to: occurrence) ?? occurrence.addingTimeInterval(86_400)
        }

        return nil
    }

    private func occurrence(month: Int, day: Int, year: Int) -> Date? {
        if month == 2 && day == 29 && !calendar.isDateInLeapYear(year: year) {
            switch leapDayPolicy {
            case .useFebruary28:
                return calendar.validDate(year: year, month: 2, day: 28)
            case .useMarch1:
                return calendar.validDate(year: year, month: 3, day: 1)
            }
        }

        return calendar.validDate(year: year, month: month, day: day)
    }

    private func nextMonthlyOccurrence(day: Int, from date: Date) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)
        let startComponents = calendar.dateComponents([.year, .month], from: startOfDay)
        guard let firstOfMonth = calendar.date(from: DateComponents(
            calendar: calendar,
            year: startComponents.year,
            month: startComponents.month,
            day: 1
        )) else {
            return nil
        }

        for monthOffset in 0..<24 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: firstOfMonth) else {
                continue
            }

            let components = calendar.dateComponents([.year, .month], from: monthDate)
            guard let year = components.year,
                  let month = components.month,
                  let range = calendar.range(of: .day, in: .month, for: monthDate)
            else {
                continue
            }

            let clampedDay = min(day, range.upperBound - 1)
            guard let occurrence = calendar.validDate(year: year, month: month, day: clampedDay),
                  occurrence >= startOfDay
            else {
                continue
            }

            return occurrence
        }

        return nil
    }
}

extension Calendar {
    fileprivate func isDateInLeapYear(year: Int) -> Bool {
        guard
            let february = validDate(year: year, month: 2, day: 1),
            let days = range(of: .day, in: .month, for: february)
        else {
            return false
        }

        return days.count == 29
    }

    fileprivate func validDate(year: Int, month: Int, day: Int) -> Date? {
        let components = DateComponents(calendar: self, year: year, month: month, day: day)
        guard let date = self.date(from: components) else { return nil }

        let resolved = dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else {
            return nil
        }

        return startOfDay(for: date)
    }
}

struct SpecialDateEvent: Identifiable, Hashable, Sendable {
    var id: String
    var personID: UUID
    var specialDateID: UUID
    var personName: String
    var title: String
    var type: SpecialDateType
    var month: Int
    var day: Int
    var year: Int?
    var recurrence: SpecialDateRecurrence
    var personPhotoData: Data?
    var nextDate: Date
    var daysRemaining: Int
    var count: Int?

    var monthDayText: String {
        nextDate.formatted(.dateTime.month(.wide).day())
    }

    var relativeText: String {
        DateCalculationService().formattedRelativeDays(daysRemaining)
    }

    var displayCount: Int? {
        guard let count, count > 0 else { return nil }
        return count
    }

    static func events(
        for people: [Person],
        from date: Date = Date(),
        service: DateCalculationService = DateCalculationService()
    ) -> [SpecialDateEvent] {
        people.flatMap { person in
            (person.specialDates ?? []).compactMap { specialDate in
                guard let next = service.nextOccurrence(for: specialDate, from: date),
                      let days = service.daysRemaining(for: specialDate, from: date)
                else {
                    return nil
                }

                let count: Int?
                switch specialDate.type {
                case .birthday:
                    count = service.age(on: next, birthYear: specialDate.year)
                case .anniversary, .weddingAnniversary, .workAnniversary, .relationshipMilestone, .graduation, .memorial, .milestone, .custom:
                    count = service.anniversaryCount(on: next, startYear: specialDate.year)
                }

                return SpecialDateEvent(
                    id: "\(person.id.uuidString)-\(specialDate.id.uuidString)",
                    personID: person.id,
                    specialDateID: specialDate.id,
                    personName: person.displayName,
                    title: specialDate.title,
                    type: specialDate.type,
                    month: specialDate.month,
                    day: specialDate.day,
                    year: specialDate.year,
                    recurrence: specialDate.recurrence,
                    personPhotoData: person.photoData,
                    nextDate: next,
                    daysRemaining: days,
                    count: count
                )
            }
        }
        .sorted { lhs, rhs in
            if lhs.nextDate == rhs.nextDate {
                return lhs.personName.localizedCaseInsensitiveCompare(rhs.personName) == .orderedAscending
            }
            return lhs.nextDate < rhs.nextDate
        }
    }
}
