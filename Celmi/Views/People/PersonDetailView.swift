import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CelmiModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @Bindable var person: Person
    @Bindable var settings: AppSettings

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let notes = person.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .celmiCard()
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Special Dates")
                        .font(.headline)
                        .foregroundStyle(CelmiDesign.deepPlum)

                    ForEach(person.specialDates ?? []) { specialDate in
                        SpecialDateCard(specialDate: specialDate)
                    }
                }

                Button("Schedule Reminders", systemImage: "bell.badge") {
                    Task {
                        await model.scheduleReminders(for: person)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(person.displayName)
        .celmiScreenBackground()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit", systemImage: "pencil") {
                    showingEdit = true
                }

                Button("Delete", systemImage: "trash", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPersonView(person: person, settings: settings)
        }
        .confirmationDialog("Delete \(person.displayName)?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await model.cancelReminders(for: person)
                    modelContext.delete(person)
                    try? modelContext.save()
                    model.refreshWidgets()
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(person.displayName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CelmiDesign.deepPlum)

            if person.isImportedFromContacts {
                Label("Imported from Contacts", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.callout)
                    .foregroundStyle(CelmiDesign.sage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard()
        .accessibilityElement(children: .combine)
    }
}

private struct SpecialDateCard: View {
    let specialDate: SpecialDate

    private var event: SpecialDateEvent? {
        guard let person = specialDate.person else { return nil }
        return SpecialDateEvent.events(for: [person]).first { $0.specialDateID == specialDate.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                EventTypeBadge(type: specialDate.type)
                Spacer()
                if let event {
                    Text(event.relativeText)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(CelmiDesign.deepPlum)
                }
            }

            Text(specialDate.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CelmiDesign.deepPlum)

            Text(monthDayText)
                .font(.body)
                .foregroundStyle(.secondary)

            if let event, let count = event.count {
                Text(countText(count))
                    .font(.subheadline)
                    .foregroundStyle(CelmiDesign.sage)
            }

            Text(reminderText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard()
        .accessibilityElement(children: .combine)
    }

    private var monthDayText: String {
        var components = DateComponents()
        components.month = specialDate.month
        components.day = specialDate.day
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.wide).day())
    }

    private var reminderText: String {
        guard let preference = specialDate.reminderPreference, preference.isEnabled else {
            return "Reminder: Off"
        }

        let parts = preference.reminderOffsets.map { offset in
            switch offset {
            case 0: "day of"
            case 1: "1 day before"
            case 7: "1 week before"
            default: "\(offset) days before"
            }
        }
        return "Reminder: \(parts.joined(separator: ", "))"
    }

    private func countText(_ count: Int) -> String {
        switch specialDate.type {
        case .birthday:
            "Turns \(count)"
        case .anniversary:
            "\(count)-year anniversary"
        case .milestone, .custom:
            "\(count) years"
        }
    }
}
