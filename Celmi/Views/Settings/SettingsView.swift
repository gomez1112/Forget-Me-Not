import FlexStore
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CelmiModel.self) private var model
    @Environment(EntitlementService.self) private var entitlementService
    @Query(sort: \Person.fullName) private var people: [Person]

    @Bindable var settings: AppSettings

    @State private var showingImport = false
    @State private var showingPaywall = false
    @State private var showingPrivacy = false
    @State private var showingDeleteImportedConfirmation = false
    @State private var showingDeleteAllConfirmation = false

    private var reminderCapacity: ReminderCapacity {
        ReminderCapacity.current(for: people)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsSection("Privacy") {
                    Text("Celmi keeps your data private. Contact information stays on device and can sync through your private iCloud account when enabled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    settingsButton("Privacy Details", systemImage: "lock.shield") {
                        showingPrivacy = true
                    }
                }

                settingsSection("Contacts") {
                    LabeledContent("Permission", value: model.contactsPermissionState.title)
                    settingsButton("Refresh Contacts", systemImage: "arrow.clockwise") {
                        showingImport = true
                    }
                }

                settingsSection("Notifications") {
                    if reminderCapacity.exceedsSystemLimit {
                        ReminderLimitWarningView(capacity: reminderCapacity)
                    }

                    LabeledContent("Permission", value: model.notificationPermissionState.title)
                    settingsButton("Request Notifications", systemImage: "bell.badge") {
                        Task {
                            await model.requestNotificationPermission()
                        }
                    }
                    settingsButton("Reschedule All Reminders", systemImage: "calendar.badge.clock") {
                        Task {
                            await model.rescheduleReminders(for: people)
                        }
                    }
                }

                defaultReminderSettings

                settingsSection("Premium") {
                    LabeledContent("Tier", value: entitlementService.tier.rawValue.capitalized)
                    settingsButton("Manage Subscription", systemImage: "crown") {
                        showingPaywall = true
                    }

                    RestorePurchasesButton<CelmiAppTier>()
                        .accessibilityHint("Checks the App Store for previous Celmi Pro purchases.")
                }

                LifetimeUnlockSettingsCard()

                settingsSection("Onboarding") {
                    settingsButton("Replay Onboarding", systemImage: "sparkles") {
                        settings.hasCompletedOnboarding = false
                    }
                }

                settingsSection("Data") {
                    settingsButton("Delete Imported Data", systemImage: "person.crop.circle.badge.xmark", role: .destructive) {
                        showingDeleteImportedConfirmation = true
                    }

                    settingsButton("Delete All App Data", systemImage: "trash", role: .destructive) {
                        showingDeleteAllConfirmation = true
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
        .celmiScreenBackground()
        .task {
            await model.refreshPermissionStates()
        }
        .sheet(isPresented: $showingImport) {
            ImportContactsView(settings: settings)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
        .confirmationDialog("Delete imported people?", isPresented: $showingDeleteImportedConfirmation) {
            Button("Delete Imported Data", role: .destructive) {
                deleteImportedData()
            }
        }
        .confirmationDialog("Delete all Celmi data?", isPresented: $showingDeleteAllConfirmation) {
            Button("Delete All Data", role: .destructive) {
                deleteAllData()
            }
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .celmiCard(cornerRadius: 18)
        }
    }

    private var defaultReminderSettings: some View {
        settingsSection("Default Reminder Time") {
            DatePicker(
                "Time",
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
            Toggle("Two weeks before", isOn: $settings.defaultRemindTwoWeeksBefore)
            Toggle("One month before", isOn: $settings.defaultRemindOneMonthBefore)
            Toggle("Custom lead time", isOn: Binding(
                get: { settings.defaultCustomDaysBefore != nil },
                set: { isOn in
                    settings.defaultCustomDaysBefore = isOn ? (settings.defaultCustomDaysBefore ?? 3) : nil
                }
            ))

            if settings.defaultCustomDaysBefore != nil {
                Stepper(
                    "Custom: \(settings.defaultCustomDaysBefore ?? 3) days before",
                    value: Binding(
                        get: { settings.defaultCustomDaysBefore ?? 3 },
                        set: { settings.defaultCustomDaysBefore = $0 }
                    ),
                    in: 2...365
                )
            }
        }
    }

    private func settingsButton(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .foregroundStyle(role == .destructive ? Color.red : CelmiDesign.rose)
    }

    private func deleteImportedData() {
        people.filter(\.isImportedFromContacts).forEach(modelContext.delete)
        try? modelContext.save()
        let remainingPeople = people.filter { !$0.isImportedFromContacts }
        model.refreshWidgets(for: remainingPeople)
        Task {
            await model.rescheduleReminders(for: remainingPeople)
        }
    }

    private func deleteAllData() {
        people.forEach(modelContext.delete)
        try? modelContext.save()
        Task {
            await model.cancelAllReminders()
        }
        model.refreshWidgets(for: [])
    }
}
