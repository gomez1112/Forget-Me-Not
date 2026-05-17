import SwiftData
import SwiftUI

struct UpcomingEventsView: View {
    @Query(sort: \Person.fullName) private var people: [Person]
    @Bindable var settings: AppSettings

    private var groupedEvents: [(String, [SpecialDateEvent])] {
        let events = SpecialDateEvent.events(for: people)
        return [
            ("Today", events.filter { $0.daysRemaining == 0 }),
            ("This Week", events.filter { (1...7).contains($0.daysRemaining) }),
            ("This Month", events.filter { (8...31).contains($0.daysRemaining) }),
            ("Later", events.filter { $0.daysRemaining > 31 })
        ].filter { !$0.1.isEmpty }
    }

    var body: some View {
        List {
            if groupedEvents.isEmpty {
                CelmiEmptyStateView(
                    title: "No dates yet.",
                    message: "Add someone you care about to start seeing celebrations here.",
                    systemImage: "calendar.badge.plus"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(groupedEvents, id: \.0) { section, events in
                    Section(section) {
                        ForEach(events) { event in
                            if let person = people.first(where: { $0.id == event.personID }) {
                                NavigationLink {
                                    PersonDetailView(person: person, settings: settings)
                                } label: {
                                    UpcomingEventRow(event: event)
                                }
                                .listRowBackground(Color.clear)
                            } else {
                                UpcomingEventRow(event: event)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Upcoming")
        .celmiTabContentClearance()
        .celmiScreenBackground()
    }
}

struct UpcomingEventRow: View {
    let event: SpecialDateEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.type.systemImage)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(CelmiDesign.rose.opacity(0.14), in: Circle())
                .foregroundStyle(CelmiDesign.rose)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.personName)
                    .font(.headline)
                    .foregroundStyle(CelmiDesign.deepPlum)

                HStack(spacing: 6) {
                    Text(event.type.title)
                    Text(event.monthDayText)
                    if let count = event.count {
                        Text("- \(count)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(event.relativeText)
                .font(.callout.weight(.semibold))
                .foregroundStyle(CelmiDesign.deepPlum)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.personName), \(event.type.title), \(event.monthDayText), \(event.relativeText)")
    }
}
