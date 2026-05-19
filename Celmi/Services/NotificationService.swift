import Foundation
import GentleNotification
import UserNotifications

enum NotificationPermissionState: String, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var title: String {
        switch self {
        case .notDetermined: "Not Asked"
        case .denied: "Denied"
        case .authorized: "Allowed"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        }
    }
}

struct ReminderCapacity: Hashable, Sendable {
    static let systemLimit = 64

    var possibleReminderCount: Int
    var scheduledReminderLimit: Int = Self.systemLimit

    var exceedsSystemLimit: Bool {
        possibleReminderCount > scheduledReminderLimit
    }

    var scheduledReminderCount: Int {
        min(possibleReminderCount, scheduledReminderLimit)
    }

    static func current(
        for people: [Person],
        dateService: DateCalculationService = DateCalculationService()
    ) -> ReminderCapacity {
        ReminderCapacity(possibleReminderCount: reminderCandidates(for: people, dateService: dateService).count)
    }

    fileprivate static func reminderCandidates(
        for people: [Person],
        dateService: DateCalculationService = DateCalculationService(),
        now: Date = Date()
    ) -> [ReminderScheduleCandidate] {
        people.flatMap { person -> [ReminderScheduleCandidate] in
            (person.specialDates ?? []).flatMap { specialDate -> [ReminderScheduleCandidate] in
                guard let preference = specialDate.reminderPreference, preference.isEnabled else { return [] as [ReminderScheduleCandidate] }

                return preference.reminderOffsets.compactMap { offset -> ReminderScheduleCandidate? in
                    guard let notificationDate = dateService.notificationDate(
                        for: specialDate,
                        daysBefore: offset,
                        hour: preference.preferredNotificationHour,
                        minute: preference.preferredNotificationMinute,
                        from: now
                    ) else {
                        return nil
                    }

                    return ReminderScheduleCandidate(
                        person: person,
                        specialDate: specialDate,
                        daysBefore: offset,
                        notificationDate: notificationDate
                    )
                }
            }
        }
        .sorted { lhs, rhs in
            if lhs.notificationDate == rhs.notificationDate {
                return lhs.person.displayName.localizedCaseInsensitiveCompare(rhs.person.displayName) == .orderedAscending
            }

            return lhs.notificationDate < rhs.notificationDate
        }
    }
}

fileprivate struct ReminderScheduleCandidate {
    var person: Person
    var specialDate: SpecialDate
    var daysBefore: Int
    var notificationDate: Date
}

@MainActor
final class NotificationService {
    private let dateService: DateCalculationService

    init(dateService: DateCalculationService = DateCalculationService()) {
        self.dateService = dateService
    }

    func requestPermission() async -> NotificationPermissionState {
        do {
            _ = try await Notify.requestAuthorization(options: [.alert, .sound, .badge])
            return await permissionStatus()
        } catch {
            return .denied
        }
    }

    func permissionStatus() async -> NotificationPermissionState {
        switch await Notify.permissionStatus() {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .ephemeral
        }
    }

    func scheduleReminder(for person: Person, specialDate: SpecialDate, daysBefore: Int) async throws {
        guard let preference = specialDate.reminderPreference, preference.isEnabled else { return }

        let identifier = Self.identifier(
            personID: person.id,
            specialDateID: specialDate.id,
            daysBefore: daysBefore
        )
        await Notify.cancel(id: identifier)

        guard let notificationDate = dateService.notificationDate(
            for: specialDate,
            daysBefore: daysBefore,
            hour: preference.preferredNotificationHour,
            minute: preference.preferredNotificationMinute
        ) else {
            return
        }

        try await scheduleReminder(
            for: person,
            specialDate: specialDate,
            daysBefore: daysBefore,
            notificationDate: notificationDate
        )
    }

    private func scheduleReminder(
        for person: Person,
        specialDate: SpecialDate,
        daysBefore: Int,
        notificationDate: Date
    ) async throws {
        let identifier = Self.identifier(
            personID: person.id,
            specialDateID: specialDate.id,
            daysBefore: daysBefore
        )

        let content = GNNotificationContent(
            title: Self.title(personName: person.displayName, specialDate: specialDate, daysBefore: daysBefore),
            body: Self.body(for: specialDate, daysBefore: daysBefore),
            interruptionLevel: .active
        )
        .thread("celmi.relationship-reminders")
        .privacy(.genericPlaceholder("A Celmi reminder is ready."))

        let request = GNNotificationRequest(
            identifier: identifier,
            content: content,
            schedule: .exactDate(notificationDate)
        )

        try await Notify.schedule(request)
    }

    func rescheduleAllReminders(for people: [Person]) async {
        await cancelAllReminders()

        let candidates = ReminderCapacity
            .reminderCandidates(for: people, dateService: dateService)
            .prefix(ReminderCapacity.systemLimit)

        for candidate in candidates {
            try? await scheduleReminder(
                for: candidate.person,
                specialDate: candidate.specialDate,
                daysBefore: candidate.daysBefore,
                notificationDate: candidate.notificationDate
            )
        }
    }

    func cancelReminders(for person: Person) async {
        let ids = (person.specialDates ?? []).flatMap { specialDate in
            (specialDate.reminderPreference?.reminderOffsets ?? [0, 1, 7, 14, 30]).map { offset in
                Self.identifier(personID: person.id, specialDateID: specialDate.id, daysBefore: offset)
            }
        }
        await Notify.cancel(ids: ids)
    }

    func cancelAllReminders() async {
        await Notify.cancelAll()
    }

    static func identifier(personID: UUID, specialDateID: UUID, daysBefore: Int) -> String {
        "celmi.person.\(personID.uuidString).date.\(specialDateID.uuidString).offset.\(daysBefore)"
    }

    private static func title(personName: String, specialDate: SpecialDate, daysBefore: Int) -> String {
        let possessive = personName.hasSuffix("s") ? "\(personName)'" : "\(personName)'s"
        let event = specialDate.type.title.lowercased()

        switch daysBefore {
        case 0:
            return "\(possessive) \(event) is today"
        case 1:
            return "\(possessive) \(event) is tomorrow"
        case 7:
            return "\(possessive) \(event) is next week"
        default:
            return "\(possessive) \(event) is coming up"
        }
    }

    private static func body(for specialDate: SpecialDate, daysBefore: Int) -> String {
        switch specialDate.type {
        case .birthday:
            daysBefore == 0 ? "Don't forget to send a message." : "A small note now can make the day feel remembered."
        case .anniversary, .weddingAnniversary:
            "Make space to celebrate it thoughtfully."
        case .workAnniversary:
            "A quick note can make their work milestone feel seen."
        case .relationshipMilestone:
            "Make space for the memory behind this date."
        case .graduation:
            "Celebrate the work that led to this milestone."
        case .memorial:
            "Take a quiet moment to remember why this date matters."
        case .milestone, .custom:
            "You saved this because it matters."
        }
    }
}
