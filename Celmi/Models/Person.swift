import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var fullName: String = ""
    var nickname: String?
    var contactIdentifier: String?
    var notes: String?
    var relationshipContext: String?
    var giftIdeas: String?
    var favoriteColors: String?
    var clothingSizes: String?
    var previousGifts: String?
    var plans: String?
    var importantMemories: String?
    @Attribute(.externalStorage)
    var photoData: Data?
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
        relationshipContext: String? = nil,
        giftIdeas: String? = nil,
        favoriteColors: String? = nil,
        clothingSizes: String? = nil,
        previousGifts: String? = nil,
        plans: String? = nil,
        importantMemories: String? = nil,
        photoData: Data? = nil,
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
        self.relationshipContext = relationshipContext
        self.giftIdeas = giftIdeas
        self.favoriteColors = favoriteColors
        self.clothingSizes = clothingSizes
        self.previousGifts = previousGifts
        self.plans = plans
        self.importantMemories = importantMemories
        self.photoData = photoData
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
