import SwiftData
import SwiftUI

struct AddEditPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CelmiModel.self) private var model

    private let person: Person?
    @Bindable private var settings: AppSettings

    @State private var fullName: String
    @State private var nickname: String
    @State private var notes: String
    @State private var dateDrafts: [SpecialDateDraft]

    init(person: Person? = nil, settings: AppSettings) {
        self.person = person
        self._settings = Bindable(settings)
        self._fullName = State(initialValue: person?.fullName ?? "")
        self._nickname = State(initialValue: person?.nickname ?? "")
        self._notes = State(initialValue: person?.notes ?? "")
        self._dateDrafts = State(initialValue: person?.specialDates?.map(SpecialDateDraft.init) ?? [.birthday])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)
                    TextField("Nickname", text: $nickname)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Special Dates") {
                    ForEach($dateDrafts) { $draft in
                        SpecialDateDraftEditor(draft: $draft)
                    }
                    .onDelete { offsets in
                        dateDrafts.remove(atOffsets: offsets)
                    }

                    Button("Add Date", systemImage: "plus.circle") {
                        dateDrafts.append(.custom)
                    }
                }

                Section("Default Reminders") {
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: { settings.defaultReminderDate },
                            set: { newDate in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                settings.defaultReminderHour = components.hour ?? 9
                                settings.defaultReminderMinute = components.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    Toggle("Day of", isOn: $settings.defaultRemindOnDay)
                    Toggle("One day before", isOn: $settings.defaultRemindOneDayBefore)
                    Toggle("One week before", isOn: $settings.defaultRemindOneWeekBefore)
                }
            }
            .navigationTitle(person == nil ? "Add Person" : "Edit Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        dateDrafts.contains(where: \.isValid)
    }

    private func save() {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let targetPerson = person ?? Person(fullName: cleanName)
        targetPerson.fullName = cleanName
        targetPerson.nickname = cleanNickname.isEmpty ? nil : cleanNickname
        targetPerson.notes = cleanNotes.isEmpty ? nil : cleanNotes
        targetPerson.updatedAt = Date()

        if person == nil {
            modelContext.insert(targetPerson)
        }

        let oldDates = targetPerson.specialDates ?? []
        oldDates.forEach { modelContext.delete($0) }

        let newDates = dateDrafts.filter(\.isValid).map { draft in
            SpecialDate(
                title: draft.title,
                type: draft.type,
                month: draft.month,
                day: draft.day,
                year: draft.yearKnown ? draft.year : nil,
                person: targetPerson,
                reminderPreference: settings.makeDefaultReminderPreference()
            )
        }

        targetPerson.specialDates = newDates
        newDates.forEach { date in
            modelContext.insert(date)
            if let preference = date.reminderPreference {
                modelContext.insert(preference)
            }
        }

        try? modelContext.save()
        model.refreshWidgets()
        Task {
            await model.scheduleReminders(for: targetPerson)
        }
        dismiss()
    }
}

private struct SpecialDateDraftEditor: View {
    @Binding var draft: SpecialDateDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Type", selection: $draft.type) {
                ForEach(SpecialDateType.allCases) { type in
                    Label(type.title, systemImage: type.systemImage)
                        .tag(type)
                }
            }

            TextField("Title", text: $draft.title)

            DatePicker("Date", selection: $draft.date, displayedComponents: .date)

            Toggle("Year known", isOn: $draft.yearKnown)
        }
        .onChange(of: draft.type) { _, newType in
            if draft.title.isEmpty || SpecialDateType.allCases.map(\.title).contains(draft.title) {
                draft.title = newType.title
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SpecialDateDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var type: SpecialDateType
    var date: Date
    var yearKnown: Bool

    static var birthday: SpecialDateDraft {
        SpecialDateDraft(title: "Birthday", type: .birthday, date: Date(), yearKnown: false)
    }

    static var custom: SpecialDateDraft {
        SpecialDateDraft(title: "Milestone", type: .milestone, date: Date(), yearKnown: false)
    }

    init(title: String, type: SpecialDateType, date: Date, yearKnown: Bool) {
        self.title = title
        self.type = type
        self.date = date
        self.yearKnown = yearKnown
    }

    init(specialDate: SpecialDate) {
        var components = DateComponents()
        components.year = specialDate.year ?? Calendar.current.component(.year, from: Date())
        components.month = specialDate.month
        components.day = specialDate.day
        self.title = specialDate.title
        self.type = specialDate.type
        self.date = Calendar.current.date(from: components) ?? Date()
        self.yearKnown = specialDate.year != nil
    }

    var month: Int {
        Calendar.current.component(.month, from: date)
    }

    var day: Int {
        Calendar.current.component(.day, from: date)
    }

    var year: Int {
        Calendar.current.component(.year, from: date)
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (1...12).contains(month) &&
        (1...31).contains(day)
    }
}
