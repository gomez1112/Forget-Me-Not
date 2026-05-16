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
    ) -> Date {
        let occurrence = nextOccurrence(month: specialDate.month, day: specialDate.day, from: date)
        let reminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: occurrence) ?? occurrence
        let components = calendar.dateComponents([.year, .month, .day], from: reminderDay)
        return calendar.date(from: DateComponents(
            calendar: calendar,
            year: components.year,
            month: components.month,
            day: components.day,
            hour: hour,
            minute: minute
        )) ?? reminderDay
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
    var nextDate: Date
    var daysRemaining: Int
    var count: Int?

    var monthDayText: String {
        nextDate.formatted(.dateTime.month(.wide).day())
    }

    var relativeText: String {
        DateCalculationService().formattedRelativeDays(daysRemaining)
    }

    static func events(
        for people: [Person],
        from date: Date = Date(),
        service: DateCalculationService = DateCalculationService()
    ) -> [SpecialDateEvent] {
        people.flatMap { person in
            (person.specialDates ?? []).map { specialDate in
                let next = service.nextOccurrence(month: specialDate.month, day: specialDate.day, from: date)
                let days = service.daysRemaining(month: specialDate.month, day: specialDate.day, from: date)
                let count: Int?
                switch specialDate.type {
                case .birthday:
                    count = service.age(on: next, birthYear: specialDate.year)
                case .anniversary, .milestone, .custom:
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
