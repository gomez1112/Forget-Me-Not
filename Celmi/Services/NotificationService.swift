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

        let notificationDate = dateService.notificationDate(
            for: specialDate,
            daysBefore: daysBefore,
            hour: preference.preferredNotificationHour,
            minute: preference.preferredNotificationMinute
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

        for person in people {
            for specialDate in person.specialDates ?? [] {
                for offset in specialDate.reminderPreference?.reminderOffsets ?? [] {
                    try? await scheduleReminder(for: person, specialDate: specialDate, daysBefore: offset)
                }
            }
        }
    }

    func cancelReminders(for person: Person) async {
        let ids = (person.specialDates ?? []).flatMap { specialDate in
            (specialDate.reminderPreference?.reminderOffsets ?? [0, 1, 7]).map { offset in
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
        case .anniversary:
            "Make space to celebrate it thoughtfully."
        case .milestone, .custom:
            "You saved this because it matters."
        }
    }
}
