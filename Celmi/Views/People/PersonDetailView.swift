import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CelmiModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.fullName) private var people: [Person]

    @Bindable var person: Person
    @Bindable var settings: AppSettings

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var showingReminderConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                profileSummary

                if let notes = person.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .celmiCard()
                }

                if hasHelpfulDetails {
                    helpfulDetails
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
                        await model.rescheduleReminders(for: people)
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
                    let remainingPeople = people.filter { $0.id != person.id }
                    model.refreshWidgets(for: remainingPeople)
                    await model.rescheduleReminders(for: remainingPeople)
                    dismiss()
                }
            }
        }
    }

    private var hasHelpfulDetails: Bool {
        [
            person.giftIdeas,
            person.favoriteColors,
            person.clothingSizes,
            person.previousGifts,
            person.plans,
            person.importantMemories
        ].contains { value in
            value?.isEmpty == false
        }
    }

    private var profileSummary: some View {
        HStack(alignment: .top, spacing: 16) {
            PersonAvatarView(name: person.displayName, imageData: person.photoData, size: 76)

            VStack(alignment: .leading, spacing: 10) {
                if let nickname = person.nickname, !nickname.isEmpty {
                    Label(nickname, systemImage: "quote.bubble")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CelmiDesign.deepPlum)
                }

                if let context = person.relationshipContext, !context.isEmpty {
                    Label(context, systemImage: "person.text.rectangle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if person.isImportedFromContacts {
                    Label("Imported from Contacts", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.callout)
                        .foregroundStyle(CelmiDesign.sage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard()
        .accessibilityElement(children: .combine)
    }

    private var helpfulDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Helpful Details")
                .font(.headline)
                .foregroundStyle(CelmiDesign.deepPlum)

            DetailFieldRow(title: "Gift ideas", value: person.giftIdeas, systemImage: "gift")
            DetailFieldRow(title: "Favorite colors", value: person.favoriteColors, systemImage: "paintpalette")
            DetailFieldRow(title: "Clothing sizes", value: person.clothingSizes, systemImage: "tshirt")
            DetailFieldRow(title: "Previous gifts", value: person.previousGifts, systemImage: "checklist")
            DetailFieldRow(title: "Plans", value: person.plans, systemImage: "calendar")
            DetailFieldRow(title: "Important memories", value: person.importantMemories, systemImage: "sparkles")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .celmiCard()
    }
}

private struct DetailFieldRow: View {
    let title: String
    let value: String?
    let systemImage: String

    var body: some View {
        if let value, !value.isEmpty {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body)
                        .foregroundStyle(CelmiDesign.deepPlum)
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(CelmiDesign.rose)
            }
        }
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

            if let event, let count = event.displayCount {
                Text(countText(count))
                    .font(.subheadline)
                    .foregroundStyle(CelmiDesign.sage)
            }

            if let notes = specialDate.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Repeats: \(recurrenceText)")
                .font(.footnote)
                .foregroundStyle(.secondary)

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
        components.year = specialDate.year
        components.month = specialDate.month
        components.day = specialDate.day
        let date = Calendar.current.date(from: components) ?? Date()
        if specialDate.recurrence == .oneTime, specialDate.year != nil {
            return date.formatted(.dateTime.month(.wide).day().year())
        }
        return date.formatted(.dateTime.month(.wide).day())
    }

    private var recurrenceText: String {
        if specialDate.recurrence == .custom, let days = specialDate.customRecurrenceDays {
            return "Every \(days) days"
        }

        return specialDate.recurrence.title
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
            case 14: "2 weeks before"
            case 30: "1 month before"
            default: "\(offset) days before"
            }
        }
        return "Reminder: \(parts.joined(separator: ", "))"
    }

    private func countText(_ count: Int) -> String {
        switch specialDate.type {
        case .birthday:
            "Turns \(count)"
        case .anniversary, .weddingAnniversary:
            "\(count)-year anniversary"
        case .workAnniversary:
            "\(count)-year work anniversary"
        case .relationshipMilestone:
            "\(count)-year relationship milestone"
        case .graduation:
            "\(count) years since graduation"
        case .memorial:
            "\(count) years remembered"
        case .milestone, .custom:
            "\(count) years"
        }
    }
}
