import PhotosUI
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
    @State private var relationshipContext: String
    @State private var giftIdeas: String
    @State private var favoriteColors: String
    @State private var clothingSizes: String
    @State private var previousGifts: String
    @State private var plans: String
    @State private var importantMemories: String
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var dateDrafts: [SpecialDateDraft]

    init(person: Person? = nil, settings: AppSettings) {
        self.person = person
        self._settings = Bindable(settings)
        self._fullName = State(initialValue: person?.fullName ?? "")
        self._nickname = State(initialValue: person?.nickname ?? "")
        self._notes = State(initialValue: person?.notes ?? "")
        self._relationshipContext = State(initialValue: person?.relationshipContext ?? "")
        self._giftIdeas = State(initialValue: person?.giftIdeas ?? "")
        self._favoriteColors = State(initialValue: person?.favoriteColors ?? "")
        self._clothingSizes = State(initialValue: person?.clothingSizes ?? "")
        self._previousGifts = State(initialValue: person?.previousGifts ?? "")
        self._plans = State(initialValue: person?.plans ?? "")
        self._importantMemories = State(initialValue: person?.importantMemories ?? "")
        self._photoData = State(initialValue: person?.photoData)
        self._dateDrafts = State(initialValue: person?.specialDates?.map(SpecialDateDraft.init) ?? [.birthday(settings: settings)])
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection

                Section("Person") {
                    TextField("Name or label", text: $fullName)
                        .textContentType(.name)
                    TextField("Nickname", text: $nickname)
                    multilineField("Relationship or context", text: $relationshipContext)
                    multilineField("Notes", text: $notes)
                }

                Section("Helpful Details") {
                    multilineField("Gift ideas", text: $giftIdeas)
                    multilineField("Favorite colors", text: $favoriteColors)
                    multilineField("Clothing sizes", text: $clothingSizes)
                    multilineField("Previous gifts", text: $previousGifts)
                    multilineField("Plans", text: $plans)
                    multilineField("Important memories", text: $importantMemories)
                }

                Section("Special Dates") {
                    ForEach($dateDrafts) { $draft in
                        SpecialDateDraftEditor(draft: $draft)
                    }
                    .onDelete { offsets in
                        dateDrafts.remove(atOffsets: offsets)
                    }

                    Button("Add Date", systemImage: "plus.circle") {
                        dateDrafts.append(.custom(settings: settings))
                    }
                }

                DefaultReminderSettingsSection(settings: settings, title: "Defaults For New Dates")
            }
            .formStyle(.grouped)
            .navigationTitle(person == nil ? "Add Person or Occasion" : "Edit Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("personEditor.cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                    .accessibilityLabel("Save Person")
                    .accessibilityIdentifier("personEditor.save")
                }
            }
            .task(id: selectedPhotoItem) {
                await loadSelectedPhoto()
            }
        }
        .celmiSheetSizing(width: 620, height: 760)
    }

    private var photoSection: some View {
        let hasPhoto = photoData != nil

        return Section("Photo") {
            HStack(spacing: 16) {
                PersonAvatarView(name: avatarName, imageData: photoData, size: 72)

                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(hasPhoto ? "Change Photo" : "Choose Photo", systemImage: "photo")
                    }

                    if hasPhoto {
                        Button("Remove Photo", systemImage: "trash", role: .destructive) {
                            photoData = nil
                            selectedPhotoItem = nil
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var avatarName: String {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNickname.isEmpty {
            return trimmedNickname
        }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "New Entry" : trimmedName
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        dateDrafts.contains(where: \.isValid)
    }

    private func multilineField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text, axis: .vertical)
            .lineLimit(2...6)
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem,
              let data = try? await selectedPhotoItem.loadTransferable(type: Data.self)
        else {
            return
        }

        photoData = data
    }

    private func save() {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        let targetPerson = person ?? Person(fullName: cleanName)
        targetPerson.fullName = cleanName
        targetPerson.nickname = cleanOptional(nickname)
        targetPerson.notes = cleanOptional(notes)
        targetPerson.relationshipContext = cleanOptional(relationshipContext)
        targetPerson.giftIdeas = cleanOptional(giftIdeas)
        targetPerson.favoriteColors = cleanOptional(favoriteColors)
        targetPerson.clothingSizes = cleanOptional(clothingSizes)
        targetPerson.previousGifts = cleanOptional(previousGifts)
        targetPerson.plans = cleanOptional(plans)
        targetPerson.importantMemories = cleanOptional(importantMemories)
        targetPerson.photoData = photoData
        targetPerson.updatedAt = Date()

        if person == nil {
            modelContext.insert(targetPerson)
        }

        let oldDates = targetPerson.specialDates ?? []
        oldDates.forEach { date in
            if let preference = date.reminderPreference {
                modelContext.delete(preference)
            }
            modelContext.delete(date)
        }

        let newDates = dateDrafts.filter(\.isValid).map { draft in
            SpecialDate(
                title: draft.cleanTitle,
                type: draft.type,
                recurrence: draft.recurrence,
                month: draft.month,
                day: draft.day,
                year: draft.storedYear,
                customRecurrenceDays: draft.storedCustomRecurrenceDays,
                notes: cleanOptional(draft.notes),
                person: targetPerson,
                reminderPreference: draft.makeReminderPreference()
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
        let people = fetchPeople(fallback: targetPerson)
        model.refreshWidgets(for: people)
        Task {
            await model.rescheduleReminders(for: people)
        }
        dismiss()
    }

    private func fetchPeople(fallback: Person) -> [Person] {
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\Person.fullName)])
        return (try? modelContext.fetch(descriptor)) ?? [fallback]
    }

    private func cleanOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

            Picker("Repeats", selection: $draft.recurrence) {
                ForEach(SpecialDateRecurrence.allCases) { recurrence in
                    Label(recurrence.title, systemImage: recurrence.systemImage)
                        .tag(recurrence)
                }
            }

            if draft.recurrence == .custom {
                Stepper("Every \(draft.customRecurrenceDays) days", value: $draft.customRecurrenceDays, in: 1...365)
            }

            if draft.recurrence.requiresExactStartDate {
                Label("Uses the selected year", systemImage: "calendar.badge.clock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Toggle("Year known", isOn: $draft.yearKnown)
            }

            TextField("Date notes", text: $draft.notes, axis: .vertical)
                .lineLimit(2...4)

            Divider()

            reminderControls
        }
        .onChange(of: draft.type) { _, newType in
            if draft.title.isEmpty || SpecialDateType.allCases.map(\.title).contains(draft.title) {
                draft.title = newType.title
            }
        }
        .onChange(of: draft.recurrence) { _, newRecurrence in
            if newRecurrence.requiresExactStartDate {
                draft.yearKnown = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var reminderControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Reminders", isOn: $draft.reminderEnabled)

            if draft.reminderEnabled {
                DatePicker("Reminder Time", selection: $draft.reminderDate, displayedComponents: .hourAndMinute)
                Toggle("Day of", isOn: $draft.remindOnDay)
                Toggle("One day before", isOn: $draft.remindOneDayBefore)
                Toggle("One week before", isOn: $draft.remindOneWeekBefore)
                Toggle("Two weeks before", isOn: $draft.remindTwoWeeksBefore)
                Toggle("One month before", isOn: $draft.remindOneMonthBefore)
                Toggle("Custom lead time", isOn: Binding(
                    get: { draft.customReminderDays != nil },
                    set: { isOn in
                        draft.customReminderDays = isOn ? (draft.customReminderDays ?? 3) : nil
                    }
                ))

                if draft.customReminderDays != nil {
                    Stepper(
                        "Custom: \(draft.customReminderDays ?? 3) days before",
                        value: Binding(
                            get: { draft.customReminderDays ?? 3 },
                            set: { draft.customReminderDays = $0 }
                        ),
                        in: 2...365
                    )
                }
            }
        }
    }
}

private struct SpecialDateDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var type: SpecialDateType
    var date: Date
    var yearKnown: Bool
    var recurrence: SpecialDateRecurrence
    var customRecurrenceDays: Int
    var notes: String
    var reminderEnabled: Bool
    var remindOnDay: Bool
    var remindOneDayBefore: Bool
    var remindOneWeekBefore: Bool
    var remindTwoWeeksBefore: Bool
    var remindOneMonthBefore: Bool
    var customReminderDays: Int?
    var reminderDate: Date

    static func birthday(settings: AppSettings) -> SpecialDateDraft {
        SpecialDateDraft(
            title: "Birthday",
            type: .birthday,
            date: Date(),
            yearKnown: false,
            recurrence: .yearly,
            customRecurrenceDays: 30,
            notes: "",
            preference: settings.makeDefaultReminderPreference()
        )
    }

    static func custom(settings: AppSettings) -> SpecialDateDraft {
        SpecialDateDraft(
            title: "Milestone",
            type: .milestone,
            date: Date(),
            yearKnown: false,
            recurrence: .yearly,
            customRecurrenceDays: 30,
            notes: "",
            preference: settings.makeDefaultReminderPreference()
        )
    }

    init(
        title: String,
        type: SpecialDateType,
        date: Date,
        yearKnown: Bool,
        recurrence: SpecialDateRecurrence,
        customRecurrenceDays: Int,
        notes: String,
        preference: ReminderPreference?
    ) {
        self.title = title
        self.type = type
        self.date = date
        self.yearKnown = yearKnown || recurrence.requiresExactStartDate
        self.recurrence = recurrence
        self.customRecurrenceDays = customRecurrenceDays
        self.notes = notes
        self.reminderEnabled = preference?.isEnabled ?? true
        self.remindOnDay = preference?.remindOnDay ?? true
        self.remindOneDayBefore = preference?.remindOneDayBefore ?? true
        self.remindOneWeekBefore = preference?.remindOneWeekBefore ?? false
        self.remindTwoWeeksBefore = preference?.remindTwoWeeksBefore ?? false
        self.remindOneMonthBefore = preference?.remindOneMonthBefore ?? false
        self.customReminderDays = preference?.customDaysBefore
        self.reminderDate = Self.reminderDate(
            hour: preference?.preferredNotificationHour ?? 9,
            minute: preference?.preferredNotificationMinute ?? 0
        )
    }

    init(specialDate: SpecialDate) {
        var components = DateComponents()
        components.year = specialDate.year ?? Calendar.current.component(.year, from: Date())
        components.month = specialDate.month
        components.day = specialDate.day

        self.init(
            title: specialDate.title,
            type: specialDate.type,
            date: Calendar.current.date(from: components) ?? Date(),
            yearKnown: specialDate.year != nil,
            recurrence: specialDate.recurrence,
            customRecurrenceDays: specialDate.customRecurrenceDays ?? 30,
            notes: specialDate.notes ?? "",
            preference: specialDate.reminderPreference
        )
    }

    var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
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

    var storedYear: Int? {
        yearKnown || recurrence.requiresExactStartDate ? year : nil
    }

    var storedCustomRecurrenceDays: Int? {
        recurrence == .custom ? customRecurrenceDays : nil
    }

    var isValid: Bool {
        !cleanTitle.isEmpty &&
        (1...12).contains(month) &&
        (1...31).contains(day) &&
        (recurrence != .custom || customRecurrenceDays > 0)
    }

    func makeReminderPreference() -> ReminderPreference {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        return ReminderPreference(
            remindOnDay: remindOnDay,
            remindOneDayBefore: remindOneDayBefore,
            remindOneWeekBefore: remindOneWeekBefore,
            remindTwoWeeksBefore: remindTwoWeeksBefore,
            remindOneMonthBefore: remindOneMonthBefore,
            customDaysBefore: customReminderDays,
            preferredNotificationHour: components.hour ?? 9,
            preferredNotificationMinute: components.minute ?? 0,
            isEnabled: reminderEnabled
        )
    }

    private static func reminderDate(hour: Int, minute: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current, hour: hour, minute: minute)
        return Calendar.current.date(from: components) ?? Date()
    }
}
