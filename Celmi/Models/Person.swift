import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var fullName: String = ""
    var nickname: String?
    var contactIdentifier: String?
    var notes: String?
    var isImportedFromContacts: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(inverse: \SpecialDate.person)
    var specialDates: [SpecialDate]?

    init(
        id: UUID = UUID(),
        fullName: String,
        nickname: String? = nil,
        contactIdentifier: String? = nil,
        notes: String? = nil,
        isImportedFromContacts: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        specialDates: [SpecialDate]? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.nickname = nickname
        self.contactIdentifier = contactIdentifier
        self.notes = notes
        self.isImportedFromContacts = isImportedFromContacts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.specialDates = specialDates
    }

    var displayName: String {
        let trimmedNickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNickname?.isEmpty == false ? trimmedNickname! : fullName
    }
}
