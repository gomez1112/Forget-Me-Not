import AppIntents
import Foundation

enum CelmiAppDestination: String, AppEnum {
    case today
    case upcoming
    case people
    case addDate
    case settings

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Celmi Destination")

    static let caseDisplayRepresentations: [CelmiAppDestination: DisplayRepresentation] = [
        .today: "Today",
        .upcoming: "Upcoming Dates",
        .people: "People",
        .addDate: "Add Important Date",
        .settings: "Settings"
    ]
}

enum CelmiAppIntentRouteStore {
    private static let pendingDestinationKey = "CelmiPendingAppDestination"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: CelmiConstants.appGroupIdentifier) ?? .standard
    }

    static func save(_ destination: CelmiAppDestination) {
        defaults.set(destination.rawValue, forKey: pendingDestinationKey)
    }

    static func consumeDestination() -> CelmiAppDestination? {
        guard let rawValue = defaults.string(forKey: pendingDestinationKey),
              let destination = CelmiAppDestination(rawValue: rawValue)
        else {
            return nil
        }

        defaults.removeObject(forKey: pendingDestinationKey)
        return destination
    }
}

struct OpenCelmiIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Celmi"
    static let description = IntentDescription("Opens Celmi to Today, Upcoming Dates, People, Settings, or the add-date flow.")
    static var supportedModes: IntentModes { .foreground(.deferred) }

    @Parameter(title: "Destination")
    var destination: CelmiAppDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$destination)")
    }

    init() {
        destination = .upcoming
    }

    init(destination: CelmiAppDestination) {
        self.destination = destination
    }

    func perform() async throws -> some IntentResult {
        await CelmiAppIntentRouteStore.save(destination)
        return .result()
    }
}

struct AddImportantDateIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Important Date"
    static let description = IntentDescription("Opens Celmi to add a birthday, anniversary, milestone, or other important date.")
    static var supportedModes: IntentModes { .foreground(.deferred) }

    init() {}

    func perform() async throws -> some IntentResult {
        await CelmiAppIntentRouteStore.save(.addDate)
        return .result()
    }
}

struct ShowNextImportantDateIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Important Date"
    static let description = IntentDescription("Shows the next birthday, anniversary, milestone, or important date saved in Celmi.")
    static var supportedModes: IntentModes { .background }

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let event = await CelmiIntentWidgetSnapshotStore.loadNextEvent() else {
            return .result(dialog: "No upcoming dates are saved in Celmi yet.")
        }

        let eventName = event.eventTitle.lowercased()
        let relativeDate = event.daysRemainingText.lowercased()
        return .result(dialog: "\(event.personName)'s \(eventName) is \(relativeDate) on \(event.eventDateText).")
    }
}

struct CelmiShortcutsProvider: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .pink

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCelmiIntent(destination: .upcoming),
            phrases: [
                "Show upcoming dates in \(.applicationName)",
                "Open up next in \(.applicationName)"
            ],
            shortTitle: "Up Next",
            systemImageName: "calendar.badge.clock"
        )

        AppShortcut(
            intent: AddImportantDateIntent(),
            phrases: [
                "Add an important date in \(.applicationName)",
                "Add a birthday in \(.applicationName)"
            ],
            shortTitle: "Add Date",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: ShowNextImportantDateIntent(),
            phrases: [
                "What is next in \(.applicationName)",
                "Show the next date in \(.applicationName)"
            ],
            shortTitle: "What Is Next",
            systemImageName: "sparkles"
        )
    }
}

private enum CelmiIntentWidgetSnapshotStore {
    private static let storageKey = "CelmiWidgetUpcomingEvents"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: CelmiConstants.appGroupIdentifier) ?? .standard
    }

    static func loadNextEvent() -> Event? {
        guard let data = defaults.data(forKey: storageKey),
              let events = try? JSONDecoder().decode([Event].self, from: data)
        else {
            return nil
        }

        return events.first
    }

    struct Event: Codable {
        var personName: String
        var eventTitle: String
        var eventDateText: String
        var daysRemainingText: String
        var systemImage: String
    }
}
