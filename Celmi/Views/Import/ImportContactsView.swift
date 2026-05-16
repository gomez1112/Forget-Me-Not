import SwiftData
import SwiftUI

struct ImportContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CelmiModel.self) private var model
    @Query(sort: \Person.fullName) private var people: [Person]

    @Bindable var settings: AppSettings

    var body: some View {
        NavigationStack {
            List {
                privacySection

                if model.contactsPermissionState == .authorized {
                    candidatesSection
                } else {
                    permissionSection
                }
            }
            .navigationTitle("Import from Contacts")
            .celmiScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Selected") {
                        model.saveSelectedImportCandidates(
                            into: modelContext,
                            settings: settings,
                            existingPeople: people
                        )
                        dismiss()
                    }
                    .disabled(model.importCandidates.filter(\.isSelected).isEmpty)
                }
            }
            .task {
                await model.refreshPermissionStates()
                if model.contactsPermissionState == .authorized {
                    await model.loadContactCandidates(existingPeople: people)
                }
            }
        }
    }

    private var privacySection: some View {
        Section {
            Label(
                "Celmi reads birthdays and saved dates on device. Contact data is never sent to a server.",
                systemImage: "lock.shield"
            )
            .foregroundStyle(CelmiDesign.deepPlum)
        }
    }

    private var permissionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Contacts access is optional.")
                    .font(.headline)
                Text("Allow access to review birthdays already saved in Contacts, or keep using Celmi with manual entry.")
                    .foregroundStyle(.secondary)

                Button("Allow Contacts", systemImage: "person.crop.circle.badge.plus") {
                    Task {
                        let state = await model.requestContactsPermission()
                        if state == .authorized {
                            await model.loadContactCandidates(existingPeople: people)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
        }
    }

    private var candidatesSection: some View {
        Section("Found Dates") {
            if model.importCandidates.isEmpty {
                CelmiEmptyStateView(
                    title: "No new dates found.",
                    message: "You can still add birthdays, anniversaries, and milestones manually.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .listRowBackground(Color.clear)
            } else {
                Button("Select All") {
                    for index in model.importCandidates.indices {
                        model.importCandidates[index].isSelected = true
                    }
                }

                ForEach(model.importCandidates) { candidate in
                    Toggle(isOn: selectionBinding(for: candidate)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.fullName)
                                .font(.headline)
                            Text(candidate.dates.map(\.title).joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Import \(candidate.fullName)")
                }
            }
        }
    }

    private func selectionBinding(for candidate: ImportedPersonCandidate) -> Binding<Bool> {
        Binding {
            model.importCandidates.first { $0.id == candidate.id }?.isSelected ?? false
        } set: { isSelected in
            guard let index = model.importCandidates.firstIndex(where: { $0.id == candidate.id }) else { return }
            model.importCandidates[index].isSelected = isSelected
        }
    }
}
