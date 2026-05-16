import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Private by Design") {
                    Text("Celmi stores relationship dates in SwiftData on your device. When iCloud sync is available, data syncs through your private iCloud account.")
                    Text("Celmi does not require an account, does not include ads, and does not include third-party analytics.")
                }

                Section("Contacts") {
                    Text("Contacts access is optional. Celmi only reads birthdays and date fields to help you set up faster. You can always add people manually.")
                }

                Section("Notifications") {
                    Text("Notifications are optional and scheduled locally on your device. They can be changed or disabled at any time.")
                }
            }
            .navigationTitle("Privacy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
