import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(CelmiModel.self) private var model
    @Environment(EntitlementService.self) private var entitlementService
    @Query(sort: \Person.fullName) private var people: [Person]
    @Bindable var settings: AppSettings

    @State private var showingAddPerson = false
    @State private var showingImport = false
    @State private var showingPaywall = false

    private var events: [SpecialDateEvent] {
        SpecialDateEvent.events(for: people)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let nextEvent = events.first {
                    NextCelebrationCard(event: nextEvent)
                    quickActions
                    dashboardStats
                } else {
                    quickActions
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
                Button("Add Person", systemImage: "plus") {
                    showingAddPerson = true
                }
                .accessibilityLabel("Add Person")
                .accessibilityIdentifier("dashboard.addPerson")
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            AddEditPersonView(settings: settings)
        }
        .sheet(isPresented: $showingImport) {
            ImportContactsView(settings: settings)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
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

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(CelmiDesign.deepPlum)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionCard(title: "Import from Contacts", systemImage: "person.crop.circle.badge.plus") {
                        showingImport = true
                    }
                    .frame(width: 172)

                    QuickActionCard(title: "Add Person", systemImage: "plus.circle") {
                        showingAddPerson = true
                    }
                    .frame(width: 172)

                    QuickActionCard(title: "Review Notifications", systemImage: "bell.badge") {
                        Task {
                            await model.requestNotificationPermission()
                        }
                    }
                    .frame(width: 172)

                    if !entitlementService.isPro {
                        QuickActionCard(title: "Upgrade to Pro", systemImage: "crown") {
                            showingPaywall = true
                        }
                        .frame(width: 172)
                    }
                }
                .padding(.vertical, 2)
            }
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
        HStack(spacing: 16) {
            Image(systemName: "person.2.wave.2")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CelmiDesign.rose)
                .frame(width: 48, height: 48)
                .background(CelmiDesign.rose.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your inner circle is waiting.")
                    .font(.headline)
                    .foregroundStyle(CelmiDesign.deepPlum)
                Text("Import birthdays from Contacts or add someone manually.")
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
            EventTypeBadge(type: event.type)

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

private struct QuickActionCard: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(CelmiDesign.deepPlum)
        .celmiCard(cornerRadius: 22)
        .accessibilityLabel(title)
    }
}
