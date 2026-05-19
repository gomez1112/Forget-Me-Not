import Foundation

struct WidgetSnapshotService: Sendable {
    private let suiteName = CelmiConstants.appGroupIdentifier
    private let storageKey = "CelmiWidgetUpcomingEvents"
    private let dateService = DateCalculationService()

    @MainActor
    func saveUpcomingEvents(for people: [Person]) {
        let events = SpecialDateEvent.events(for: people, service: dateService)
            .prefix(3)
            .map { event in
                WidgetSnapshotEvent(
                    personName: event.personName,
                    eventTitle: event.type.title,
                    eventDateText: event.monthDayText,
                    daysRemainingText: event.relativeText,
                    systemImage: event.type.systemImage
                )
            }

        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(Array(events))
        else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}

private struct WidgetSnapshotEvent: Codable {
    var personName: String
    var eventTitle: String
    var eventDateText: String
    var daysRemainingText: String
    var systemImage: String
}

