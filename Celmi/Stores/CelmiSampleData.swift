import Foundation
import SwiftData

enum CelmiSampleData {
    @MainActor
    static func seed(into context: ModelContext, hasCompletedOnboarding: Bool) throws {
        let settings = AppSettings(hasCompletedOnboarding: hasCompletedOnboarding)
        context.insert(settings)

        let people = [
            makePerson(
                fullName: "Nicole Rivera",
                nickname: "Nicole",
                notes: "Loves handwritten cards and brunch plans.",
                dates: [
                    DateSeed(title: "Birthday", type: .birthday, month: 3, day: 11, year: 1989)
                ]
            ),
            makePerson(
                fullName: "Aiden Gomez",
                nickname: "Aiden",
                notes: "Send the dinosaur stickers.",
                dates: [
                    DateSeed(title: "Birthday", type: .birthday, month: 8, day: 22, year: 2016)
                ]
            ),
            makePerson(
                fullName: "Stefan Muller",
                nickname: "Stefan",
                notes: "Prefers a quick voice memo over a long text.",
                dates: [
                    DateSeed(title: "Birthday", type: .birthday, month: 12, day: 2, year: 1991)
                ]
            ),
            makePerson(
                fullName: "Mom and Dad",
                notes: "Book dinner early.",
                dates: [
                    DateSeed(title: "Anniversary", type: .anniversary, month: 6, day: 4, year: 1987)
                ]
            ),
            makePerson(
                fullName: "Maya Chen",
                nickname: "Maya",
                notes: "First gallery opening.",
                dates: [
                    DateSeed(title: "Gallery opening", type: .milestone, month: 10, day: 14, year: nil)
                ]
            )
        ]

        for person in people {
            context.insert(person)
            person.specialDates?.forEach { date in
                context.insert(date)
                if let preference = date.reminderPreference {
                    context.insert(preference)
                }
            }
        }

        try context.save()
    }

    private static func makePerson(
        fullName: String,
        nickname: String? = nil,
        notes: String? = nil,
        dates: [DateSeed]
    ) -> Person {
        let person = Person(fullName: fullName, nickname: nickname, notes: notes)
        let specialDates = dates.map { seed in
            SpecialDate(
                title: seed.title,
                type: seed.type,
                month: seed.month,
                day: seed.day,
                year: seed.year,
                person: person,
                reminderPreference: ReminderPreference()
            )
        }
        person.specialDates = specialDates
        return person
    }

    private struct DateSeed {
        var title: String
        var type: SpecialDateType
        var month: Int
        var day: Int
        var year: Int?
    }
}
