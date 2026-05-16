import Foundation
import SwiftData

@Model
final class ReminderPreference {
    var id: UUID = UUID()
    var remindOnDay: Bool = true
    var remindOneDayBefore: Bool = true
    var remindOneWeekBefore: Bool = false
    var customDaysBefore: Int?
    var preferredNotificationHour: Int = 9
    var preferredNotificationMinute: Int = 0
    var isEnabled: Bool = true

    var specialDate: SpecialDate?

    init(
        id: UUID = UUID(),
        remindOnDay: Bool = true,
        remindOneDayBefore: Bool = true,
        remindOneWeekBefore: Bool = false,
        customDaysBefore: Int? = nil,
        preferredNotificationHour: Int = 9,
        preferredNotificationMinute: Int = 0,
        isEnabled: Bool = true,
        specialDate: SpecialDate? = nil
    ) {
        self.id = id
        self.remindOnDay = remindOnDay
        self.remindOneDayBefore = remindOneDayBefore
        self.remindOneWeekBefore = remindOneWeekBefore
        self.customDaysBefore = customDaysBefore
        self.preferredNotificationHour = preferredNotificationHour
        self.preferredNotificationMinute = preferredNotificationMinute
        self.isEnabled = isEnabled
        self.specialDate = specialDate
    }

    var reminderOffsets: [Int] {
        guard isEnabled else { return [] }
        var offsets: [Int] = []
        if remindOnDay { offsets.append(0) }
        if remindOneDayBefore { offsets.append(1) }
        if remindOneWeekBefore { offsets.append(7) }
        if let customDaysBefore, customDaysBefore > 0 {
            offsets.append(customDaysBefore)
        }
        return Array(Set(offsets)).sorted()
    }
}
