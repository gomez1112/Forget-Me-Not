import SwiftUI

struct ReminderLimitWarningView: View {
    var capacity: ReminderCapacity

    var body: some View {
        if capacity.exceedsSystemLimit {
            Label {
                Text("iOS can keep \(capacity.scheduledReminderLimit) reminders scheduled. Celmi will schedule your next \(capacity.scheduledReminderLimit) of \(capacity.possibleReminderCount) possible reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CelmiDesign.rose)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
    }
}

