import SwiftUI
import WidgetKit

struct CelmiWidgetEntry: TimelineEntry {
    let date: Date
    let personName: String
    let eventTitle: String
    let eventDateText: String
    let daysRemainingText: String
}

struct CelmiWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CelmiWidgetEntry {
        CelmiWidgetEntry(
            date: Date(),
            personName: "Nicole",
            eventTitle: "Birthday",
            eventDateText: "March 11",
            daysRemainingText: "in 12 days"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CelmiWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CelmiWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct CelmiWidgetEntryView: View {
    let entry: CelmiWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(entry.eventTitle, systemImage: "gift")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.personName)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.16))
                .lineLimit(1)

            Text(entry.eventDateText)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(entry.daysRemainingText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(red: 0.82, green: 0.38, blue: 0.48))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        .accessibilityElement(children: .combine)
    }
}

struct CelmiWidget: Widget {
    let kind = "CelmiNextCelebrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CelmiWidgetProvider()) { entry in
            CelmiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Celebration")
        .description("See the next birthday, anniversary, or milestone from your inner circle.")
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
