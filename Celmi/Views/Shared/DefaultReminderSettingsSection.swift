import SwiftUI

struct DefaultReminderSettingsSection: View {
    @Bindable var settings: AppSettings
    var title: String = "Default Reminder Time"

    var body: some View {
        Section(title) {
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
}

