import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(CelmiModel.self) private var model
    @Query(sort: \Person.fullName) private var people: [Person]
    @Bindable var settings: AppSettings

    @State private var showingAddPerson = false
    @State private var showingImport = false

    private var events: [SpecialDateEvent] {
        SpecialDateEvent.events(for: people)
    }

    private var reminderCapacity: ReminderCapacity {
        ReminderCapacity.current(for: people)
    }

    private var widgetRefreshID: String {
        events.map { "\($0.id)-\($0.daysRemaining)" }.joined(separator: "|")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if reminderCapacity.exceedsSystemLimit {
                    ReminderLimitWarningView(capacity: reminderCapacity)
                        .celmiCard(cornerRadius: 18)
                }

                if let nextEvent = events.first {
                    NextCelebrationCard(event: nextEvent)
                    dashboardStats
                } else {
                    DashboardEmptyStateCard()
                    dashboardStats
                }

                if !events.prefix(5).isEmpty {
                    weekPreview
                }
            }
            .padding()
        }
        .navigationTitle("Today")
        .celmiScreenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: showImport) {
                    Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                }
                .labelStyle(.iconOnly)
                .help("Import from Contacts")
                .accessibilityLabel("Import from Contacts")
                .accessibilityIdentifier("dashboard.import")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: showAddPerson) {
                    Label("Add Person or Occasion", systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help("Add Person or Occasion")
                .accessibilityLabel("Add Person or Occasion")
                .accessibilityIdentifier("dashboard.addPerson")
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            AddEditPersonView(settings: settings)
        }
        .sheet(isPresented: $showingImport) {
            ImportContactsView(settings: settings)
        }
        .task(id: widgetRefreshID) {
            model.refreshWidgets(for: people)
        }
    }

    private func showAddPerson() {
        showingAddPerson = true
    }

    private func showImport() {
        showingImport = true
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Life gets busy.")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CelmiDesign.deepPlum)
            Text("The people you care about should never slip your mind.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var dashboardStats: some View {
        let todayCount = events.filter { $0.daysRemaining == 0 }.count
        let weekCount = events.filter { $0.daysRemaining <= 7 }.count
        let monthCount = events.filter { $0.daysRemaining <= 31 }.count

        return HStack(spacing: 12) {
            StatCard(title: "Today", value: todayCount, systemImage: "sun.max")
            StatCard(title: "This Week", value: weekCount, systemImage: "calendar")
            StatCard(title: "This Month", value: monthCount, systemImage: "sparkles")
        }
    }

    private var weekPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Up")
                .font(.headline)
                .foregroundStyle(CelmiDesign.deepPlum)

            ForEach(events.filter { $0.daysRemaining <= 7 }.prefix(4)) { event in
                UpcomingEventRow(event: event)
                    .celmiCard(cornerRadius: 22)
            }
        }
    }
}

private struct DashboardEmptyStateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("CelmiInnerCircle")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your inner circle is waiting.")
                    .font(.headline)
                    .foregroundStyle(CelmiDesign.deepPlum)
                Text("Import dates from Contacts or add a person, pet, project, or occasion manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard(cornerRadius: 24)
        .accessibilityElement(children: .combine)
    }
}

private struct NextCelebrationCard: View {
    let event: SpecialDateEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                PersonAvatarView(
                    name: event.personName,
                    imageData: event.personPhotoData,
                    size: 54,
                    systemImage: event.type.systemImage
                )
                EventTypeBadge(type: event.type)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("\(event.personName)'s \(event.type.title.lowercased()) is \(event.relativeText.lowercased())")
                    .font(.title.weight(.bold))
                    .foregroundStyle(CelmiDesign.deepPlum)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.monthDayText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CelmiDesign.deepPlum.opacity(0.72))

                Text("Send a message, plan a gift, or add a note.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(CelmiDesign.heroGradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: CelmiDesign.rose.opacity(0.18), radius: 28, y: 14)
        .accessibilityElement(children: .combine)
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(CelmiDesign.rose)
                .accessibilityHidden(true)
            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(CelmiDesign.deepPlum)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
