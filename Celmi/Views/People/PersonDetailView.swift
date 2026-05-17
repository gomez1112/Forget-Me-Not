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
    @State private var showingReminderConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if showsProfileSummary {
                    profileSummary
                }

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
                        await MainActor.run {
                            showingReminderConfirmation = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Schedule reminders for \(person.displayName)")
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
                .accessibilityLabel("Edit \(person.displayName)")
                .accessibilityIdentifier("personDetail.edit")

                Button("Delete", systemImage: "trash", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .accessibilityLabel("Delete \(person.displayName)")
                .accessibilityIdentifier("personDetail.delete")
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPersonView(person: person, settings: settings)
        }
        .alert("Reminders Scheduled", isPresented: $showingReminderConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Celmi refreshed reminders for \(person.displayName).")
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

    private var showsProfileSummary: Bool {
        (person.nickname?.isEmpty == false) ||
        person.isImportedFromContacts ||
        person.contactIdentifier != nil
    }

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let nickname = person.nickname, !nickname.isEmpty {
                Label(nickname, systemImage: "quote.bubble")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CelmiDesign.deepPlum)
            }

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
