import Foundation
import SwiftData

@Model
final class SpecialDate {
    var id: UUID = UUID()
    var title: String = ""
    var typeRawValue: String = SpecialDateType.birthday.rawValue
    var month: Int = 1
    var day: Int = 1
    var year: Int?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var person: Person?

    @Relationship(inverse: \ReminderPreference.specialDate)
    var reminderPreference: ReminderPreference?

    init(
        id: UUID = UUID(),
        title: String,
        type: SpecialDateType,
        month: Int,
        day: Int,
        year: Int? = nil,
        person: Person? = nil,
        reminderPreference: ReminderPreference? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.typeRawValue = type.rawValue
        self.month = month
        self.day = day
        self.year = year
        self.person = person
        self.reminderPreference = reminderPreference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: SpecialDateType {
        get { SpecialDateType(rawValue: typeRawValue) ?? .custom }
        set { typeRawValue = newValue.rawValue }
    }
}
