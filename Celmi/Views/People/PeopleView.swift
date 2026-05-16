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

    var body: some View {
        List {
            pickerSection

            if filteredPeople.isEmpty {
                CelmiEmptyStateView(
                    title: "Your inner circle is waiting.",
                    message: "Import birthdays from Contacts or add someone manually.",
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

                Button("Add Person", systemImage: "plus") {
                    if entitlementService.isPro || people.count < entitlementService.freePeopleLimit {
                        showingAddPerson = true
                    } else {
                        showingPaywall = true
                    }
                }
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
                    Text(type.title).tag(Optional(type))
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Filter people")
        }
        .listRowBackground(Color.clear)
    }
}

private struct PersonRowView: View {
    let person: Person

    private var nextEvent: SpecialDateEvent? {
        SpecialDateEvent.events(for: [person]).first
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(initials)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(CelmiDesign.rose, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundStyle(CelmiDesign.deepPlum)

                if let nextEvent {
                    Text("\(nextEvent.type.title) \(nextEvent.relativeText.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No saved milestones")
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

    private var initials: String {
        let parts = person.displayName.split(separator: " ")
        return parts.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}
