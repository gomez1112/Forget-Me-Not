import SwiftData
import SwiftUI

struct PeopleView: View {
    @Environment(EntitlementService.self) private var entitlementService
    @Query(sort: \Person.fullName) private var people: [Person]
    @Bindable var settings: AppSettings

    @State private var searchText = ""
    @State private var selectedFilter: SpecialDateType?
    @State private var showingAddPerson = false
    @State private var showingImport = false
    @State private var showingPaywall = false

    private var filteredPeople: [Person] {
        people.filter { person in
            let matchesSearch = searchText.isEmpty || person.fullName.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == nil || (person.specialDates ?? []).contains { $0.type == selectedFilter }
            return matchesSearch && matchesFilter
        }
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No matching people."
        }

        if let selectedFilter {
            return "No \(selectedFilter.emptyStatePluralTitle) yet."
        }

        return "Your important dates are waiting."
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try another name or clear the search."
        }

        if let selectedFilter {
            return "Add a \(selectedFilter.emptyStateSingularTitle) for someone or switch filters."
        }

        return "Import dates from Contacts or add a person, pet, project, or occasion manually."
    }

    var body: some View {
        List {
            pickerSection

            if filteredPeople.isEmpty {
                CelmiEmptyStateView(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    systemImage: "person.2"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredPeople) { person in
                    NavigationLink {
                        PersonDetailView(person: person, settings: settings)
                    } label: {
                        PersonRowView(person: person)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("People")
        .searchable(text: $searchText, prompt: "Search people")
        .celmiScreenBackground()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Import", systemImage: "person.crop.circle.badge.plus") {
                    showingImport = true
                }
                .accessibilityLabel("Import from Contacts")
                .accessibilityIdentifier("people.import")

                Button("Add Person or Occasion", systemImage: "plus") {
                    if entitlementService.isPro || people.count < entitlementService.freePeopleLimit {
                        showingAddPerson = true
                    } else {
                        showingPaywall = true
                    }
                }
                .accessibilityLabel("Add Person or Occasion")
                .accessibilityIdentifier("people.addPerson")
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

    private var pickerSection: some View {
        Section {
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(Optional<SpecialDateType>.none)
                ForEach(SpecialDateType.allCases) { type in
                    Label(type.title, systemImage: type.systemImage).tag(Optional(type))
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Filter people")
        }
        .listRowBackground(Color.clear)
    }
}

private extension SpecialDateType {
    var filterTitle: String {
        switch self {
        case .birthday:
            "Birthday"
        case .anniversary:
            "Anniversary"
        case .weddingAnniversary:
            "Wedding anniversary"
        case .workAnniversary:
            "Work anniversary"
        case .relationshipMilestone:
            "relationship milestone"
        case .graduation:
            "graduation"
        case .memorial:
            "memorial"
        case .milestone:
            "Milestone"
        case .custom:
            "Custom"
        }
    }

    var emptyStateSingularTitle: String {
        switch self {
        case .birthday:
            "birthday"
        case .anniversary:
            "anniversary"
        case .weddingAnniversary:
            "wedding anniversary"
        case .workAnniversary:
            "work anniversary"
        case .relationshipMilestone:
            "relationship milestone"
        case .graduation:
            "graduation"
        case .memorial:
            "memorial"
        case .milestone:
            "milestone"
        case .custom:
            "custom date"
        }
    }

    var emptyStatePluralTitle: String {
        switch self {
        case .birthday:
            "birthdays"
        case .anniversary:
            "anniversaries"
        case .weddingAnniversary:
            "wedding anniversaries"
        case .workAnniversary:
            "work anniversaries"
        case .relationshipMilestone:
            "relationship milestones"
        case .graduation:
            "graduations"
        case .memorial:
            "memorials"
        case .milestone:
            "milestones"
        case .custom:
            "custom dates"
        }
    }
}

private struct PersonRowView: View {
    let person: Person

    private var nextEvent: SpecialDateEvent? {
        SpecialDateEvent.events(for: [person]).first
    }

    var body: some View {
        HStack(spacing: 14) {
            PersonAvatarView(name: person.displayName, imageData: person.photoData, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundStyle(CelmiDesign.deepPlum)

                if let nextEvent {
                    Text("\(nextEvent.type.title) \(nextEvent.relativeText.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No saved dates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\((person.specialDates ?? []).count)")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel("\((person.specialDates ?? []).count) saved dates")
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
