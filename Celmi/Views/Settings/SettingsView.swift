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

    var body: some View {
        List {
            Section("Privacy") {
                Text("Celmi keeps your data private. Contact information stays on device and can sync through your private iCloud account when enabled by the system.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Privacy Details", systemImage: "lock.shield") {
                    showingPrivacy = true
                }
            }

            Section("Contacts") {
                LabeledContent("Permission", value: model.contactsPermissionState.title)
                Button("Refresh Contacts", systemImage: "arrow.clockwise") {
                    showingImport = true
                }
            }

            Section("Notifications") {
                LabeledContent("Permission", value: model.notificationPermissionState.title)
                Button("Request Notifications", systemImage: "bell.badge") {
                    Task {
                        await model.requestNotificationPermission()
                    }
                }
                Button("Reschedule All Reminders", systemImage: "calendar.badge.clock") {
                    Task {
                        await model.rescheduleReminders(for: people)
                    }
                }
            }

            Section("Default Reminder Time") {
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
            }

            Section("Premium") {
                LabeledContent("Tier", value: entitlementService.tier.rawValue.capitalized)
                Button("Manage Pro", systemImage: "crown") {
                    showingPaywall = true
                }
            }

            Section("Onboarding") {
                Button("Replay Onboarding", systemImage: "sparkles") {
                    settings.hasCompletedOnboarding = false
                }
            }

            Section("Data") {
                Button("Delete Imported Data", systemImage: "person.crop.circle.badge.xmark", role: .destructive) {
                    showingDeleteImportedConfirmation = true
                }

                Button("Delete All App Data", systemImage: "trash", role: .destructive) {
                    showingDeleteAllConfirmation = true
                }
            }
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

    private func deleteImportedData() {
        people.filter(\.isImportedFromContacts).forEach(modelContext.delete)
        try? modelContext.save()
        model.refreshWidgets()
    }

    private func deleteAllData() {
        people.forEach(modelContext.delete)
        try? modelContext.save()
        Task {
            await model.cancelAllReminders()
        }
        model.refreshWidgets()
    }
}
