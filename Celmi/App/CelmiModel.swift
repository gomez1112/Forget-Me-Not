import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class CelmiModel {
    private let contactsService: ContactsService
    private let notificationService: NotificationService
    private let widgetRefreshService: WidgetRefreshService

    var contactsPermissionState: ContactsPermissionState = .notDetermined
    var notificationPermissionState: NotificationPermissionState = .notDetermined
    var importCandidates: [ImportedPersonCandidate] = []
    var lastErrorMessage: String?

    init(
        contactsService: ContactsService = ContactsService(),
        notificationService: NotificationService = NotificationService(),
        widgetRefreshService: WidgetRefreshService = WidgetRefreshService()
    ) {
        self.contactsService = contactsService
        self.notificationService = notificationService
        self.widgetRefreshService = widgetRefreshService
    }

    static var preview: CelmiModel {
        CelmiModel()
    }

    func refreshPermissionStates() async {
        contactsPermissionState = contactsService.permissionState()
        notificationPermissionState = await notificationService.permissionStatus()
    }

    @discardableResult
    func requestContactsPermission() async -> ContactsPermissionState {
        let state = await contactsService.requestPermission()
        contactsPermissionState = state
        return state
    }

    @discardableResult
    func requestNotificationPermission() async -> NotificationPermissionState {
        let state = await notificationService.requestPermission()
        notificationPermissionState = state
        return state
    }

    func loadContactCandidates(existingPeople: [Person]) async {
        do {
            importCandidates = try await contactsService.fetchImportCandidates(existingPeople: existingPeople)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func saveSelectedImportCandidates(
        into context: ModelContext,
        settings: AppSettings,
        existingPeople: [Person]
    ) {
        let candidates = ContactsService.duplicateFreeCandidates(
            importCandidates.filter(\.isSelected),
            existingPeople: existingPeople
        )

        for candidate in candidates {
            let person = candidate.makePerson(settings: settings)
            context.insert(person)
            person.specialDates?.forEach { date in
                context.insert(date)
                if let preference = date.reminderPreference {
                    context.insert(preference)
                }
            }
        }

        try? context.save()
        importCandidates = []
        widgetRefreshService.refreshAllTimelines()
    }

    func rescheduleReminders(for people: [Person]) async {
        await notificationService.rescheduleAllReminders(for: people)
    }

    func scheduleReminders(for person: Person) async {
        for date in person.specialDates ?? [] {
            for offset in date.reminderPreference?.reminderOffsets ?? [] {
                try? await notificationService.scheduleReminder(for: person, specialDate: date, daysBefore: offset)
            }
        }
    }

    func cancelReminders(for person: Person) async {
        await notificationService.cancelReminders(for: person)
    }

    func cancelAllReminders() async {
        await notificationService.cancelAllReminders()
    }

    func refreshWidgets() {
        widgetRefreshService.refreshAllTimelines()
    }
}
