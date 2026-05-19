import SwiftUI
import WidgetKit

struct CelmiWidgetEvent: Codable, Hashable {
    var personName: String
    var eventTitle: String
    var eventDateText: String
    var daysRemainingText: String
    var systemImage: String
}

struct CelmiWidgetEntry: TimelineEntry {
    let date: Date
    let events: [CelmiWidgetEvent]

    var primaryEvent: CelmiWidgetEvent {
        events.first ?? Self.placeholderEvents[0]
    }

    static let placeholderEvents = [
        CelmiWidgetEvent(
            personName: "Nicole",
            eventTitle: "Birthday",
            eventDateText: "March 11",
            daysRemainingText: "in 12 days",
            systemImage: "gift"
        ),
        CelmiWidgetEvent(
            personName: "Mom and Dad",
            eventTitle: "Anniversary",
            eventDateText: "June 4",
            daysRemainingText: "in 2 weeks",
            systemImage: "heart"
        ),
        CelmiWidgetEvent(
            personName: "Maya",
            eventTitle: "Milestone",
            eventDateText: "October 14",
            daysRemainingText: "in 4 months",
            systemImage: "sparkles"
        )
    ]
}

struct CelmiWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CelmiWidgetEntry {
        CelmiWidgetEntry(date: Date(), events: CelmiWidgetEntry.placeholderEvents)
    }

    func getSnapshot(in context: Context, completion: @escaping (CelmiWidgetEntry) -> Void) {
        completion(CelmiWidgetEntry(date: Date(), events: WidgetSnapshotStore.loadEvents()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CelmiWidgetEntry>) -> Void) {
        let entry = CelmiWidgetEntry(date: Date(), events: WidgetSnapshotStore.loadEvents())
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private enum WidgetSnapshotStore {
    static let suiteName = "group.com.transfinite.Celmi"
    static let storageKey = "CelmiWidgetUpcomingEvents"

    static func loadEvents() -> [CelmiWidgetEvent] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: storageKey),
              let events = try? JSONDecoder().decode([CelmiWidgetEvent].self, from: data)
        else {
            return CelmiWidgetEntry.placeholderEvents
        }

        return Array(events.prefix(3))
    }
}

struct CelmiWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CelmiWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        case .accessoryRectangular:
            accessoryRectangularLayout
        case .accessoryInline:
            if entry.events.isEmpty {
                Text("Celmi: No dates yet")
            } else {
                Text("\(entry.primaryEvent.personName): \(entry.primaryEvent.daysRemainingText)")
            }
        default:
            smallLayout
        }
    }

    @ViewBuilder
    private var smallLayout: some View {
        if entry.events.isEmpty {
            emptyLayout
        } else {
            let event = entry.primaryEvent

            VStack(alignment: .leading, spacing: 8) {
                Label(event.eventTitle, systemImage: event.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(event.personName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.16))
                    .lineLimit(2)

                Text(event.eventDateText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text(event.daysRemainingText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.82, green: 0.38, blue: 0.48))
            }
            .widgetBackground()
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var mediumLayout: some View {
        if entry.events.isEmpty {
            emptyLayout
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Up Next")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.16))

                ForEach(entry.events.prefix(3), id: \.self) { event in
                    HStack(spacing: 8) {
                        Image(systemName: event.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.82, green: 0.38, blue: 0.48))
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.personName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(event.eventTitle) - \(event.eventDateText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 6)

                        Text(event.daysRemainingText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.82, green: 0.38, blue: 0.48))
                            .lineLimit(1)
                    }
                }
            }
            .widgetBackground()
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var accessoryRectangularLayout: some View {
        if entry.events.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("No dates yet")
                    .font(.headline)
                Text("Add someone in Celmi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            let event = entry.primaryEvent

            VStack(alignment: .leading, spacing: 2) {
                Text(event.personName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(event.eventTitle) \(event.daysRemainingText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Up Next", systemImage: "calendar.badge.plus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No dates yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.16))

            Text("Add someone in Celmi")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .widgetBackground()
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func widgetBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.95, blue: 0.91),
                        Color(red: 0.98, green: 0.84, blue: 0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

struct CelmiWidget: Widget {
    let kind = "CelmiNextCelebrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CelmiWidgetProvider()) { entry in
            CelmiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next")
        .description("See the next birthday, anniversary, milestone, or important date.")
        .supportedFamilies(Self.supportedFamilies)
    }

    private static var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}

@main
struct CelmiWidgetBundle: WidgetBundle {
    var body: some Widget {
        CelmiWidget()
    }
}
