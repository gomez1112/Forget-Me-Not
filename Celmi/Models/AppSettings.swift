import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID = UUID()
    var defaultReminderHour: Int = 9
    var defaultReminderMinute: Int = 0
    var defaultRemindOnDay: Bool = true
    var defaultRemindOneDayBefore: Bool = true
    var defaultRemindOneWeekBefore: Bool = false
    var hasCompletedOnboarding: Bool = false
    var iCloudSyncEnabledExplanationShown: Bool = false

    init(
        id: UUID = UUID(),
        defaultReminderHour: Int = 9,
        defaultReminderMinute: Int = 0,
        defaultRemindOnDay: Bool = true,
        defaultRemindOneDayBefore: Bool = true,
        defaultRemindOneWeekBefore: Bool = false,
        hasCompletedOnboarding: Bool = false,
        iCloudSyncEnabledExplanationShown: Bool = false
    ) {
        self.id = id
        self.defaultReminderHour = defaultReminderHour
        self.defaultReminderMinute = defaultReminderMinute
        self.defaultRemindOnDay = defaultRemindOnDay
        self.defaultRemindOneDayBefore = defaultRemindOneDayBefore
        self.defaultRemindOneWeekBefore = defaultRemindOneWeekBefore
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.iCloudSyncEnabledExplanationShown = iCloudSyncEnabledExplanationShown
    }

    func makeDefaultReminderPreference() -> ReminderPreference {
        ReminderPreference(
            remindOnDay: defaultRemindOnDay,
            remindOneDayBefore: defaultRemindOneDayBefore,
            remindOneWeekBefore: defaultRemindOneWeekBefore,
            preferredNotificationHour: defaultReminderHour,
            preferredNotificationMinute: defaultReminderMinute
        )
    }

    var defaultReminderDate: Date {
        let components = DateComponents(
            calendar: Calendar.current,
            hour: defaultReminderHour,
            minute: defaultReminderMinute
        )
        return Calendar.current.date(from: components) ?? Date()
    }
}
