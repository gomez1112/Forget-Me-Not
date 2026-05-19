import Testing
import Foundation
@testable import Celmi

@MainActor
struct CelmiTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func daysRemainingTreatsTodayAsZero() {
        let service = DateCalculationService(calendar: calendar)
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11))!

        #expect(service.daysRemaining(month: 3, day: 11, from: today) == 0)
    }

    @Test func nextOccurrenceMovesPastDatesToNextYear() {
        let service = DateCalculationService(calendar: calendar)
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 12))!
        let next = service.nextOccurrence(month: 3, day: 11, from: date)

        #expect(calendar.component(.year, from: next) == 2027)
        #expect(calendar.component(.month, from: next) == 3)
        #expect(calendar.component(.day, from: next) == 11)
    }

    @Test func leapDayUsesFebruary28InNonLeapYears() {
        let service = DateCalculationService(calendar: calendar)
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let next = service.nextOccurrence(month: 2, day: 29, from: date)

        #expect(calendar.component(.year, from: next) == 2026)
        #expect(calendar.component(.month, from: next) == 2)
        #expect(calendar.component(.day, from: next) == 28)
    }

    @Test func ageCalculationUsesOccurrenceYear() {
        let service = DateCalculationService(calendar: calendar)
        let occurrence = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11))!

        #expect(service.age(on: occurrence, birthYear: 1989) == 37)
    }

    @Test func anniversaryCountMatchesElapsedYears() {
        let service = DateCalculationService(calendar: calendar)
        let occurrence = calendar.date(from: DateComponents(year: 2026, month: 6, day: 4))!

        #expect(service.anniversaryCount(on: occurrence, startYear: 1987) == 39)
    }

    @Test func displayCountHidesZeroYearEvents() {
        let event = SpecialDateEvent(
            id: "event-1",
            personID: UUID(),
            specialDateID: UUID(),
            personName: "QA Test Person",
            title: "Work Anniversary",
            type: .workAnniversary,
            month: 5,
            day: 18,
            year: 2026,
            recurrence: .yearly,
            personPhotoData: nil,
            nextDate: calendar.date(from: DateComponents(year: 2026, month: 5, day: 18))!,
            daysRemaining: 0,
            count: 0
        )

        #expect(event.displayCount == nil)
    }

    @Test func notificationIdentifierIsStable() {
        let personID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let dateID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!

        #expect(NotificationService.identifier(personID: personID, specialDateID: dateID, daysBefore: 7) == "celmi.person.AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA.date.BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB.offset.7")
    }

    @Test func contactImportFiltersDuplicateIdentifiers() {
        let existing = Person(fullName: "Nicole Rivera", contactIdentifier: "contact-1")
        let candidates = [
            ImportedPersonCandidate(
                contactIdentifier: "contact-1",
                fullName: "Nicole Rivera",
                dates: []
            ),
            ImportedPersonCandidate(
                contactIdentifier: "contact-2",
                fullName: "Aiden Gomez",
                dates: []
            )
        ]

        let filtered = ContactsService.duplicateFreeCandidates(candidates, existingPeople: [existing])

        #expect(filtered.map { $0.contactIdentifier } == ["contact-2"])
    }
}
