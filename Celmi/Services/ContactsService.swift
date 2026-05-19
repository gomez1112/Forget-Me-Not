import Contacts
import Foundation

enum ContactsPermissionState: String, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: "Not Asked"
        case .authorized: "Allowed"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }
}

struct ImportedSpecialDateCandidate: Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String
    var type: SpecialDateType
    var month: Int
    var day: Int
    var year: Int?
}

struct ImportedPersonCandidate: Identifiable, Hashable, Sendable {
    var id: String { contactIdentifier }
    var contactIdentifier: String
    var fullName: String
    var nickname: String? = nil
    var organizationName: String? = nil
    var imageData: Data? = nil
    var dates: [ImportedSpecialDateCandidate]
    var isSelected: Bool = true

    func makePerson(settings: AppSettings) -> Person {
        let person = Person(
            fullName: fullName,
            nickname: cleanOptional(nickname),
            contactIdentifier: contactIdentifier,
            relationshipContext: cleanOptional(organizationName),
            photoData: imageData,
            isImportedFromContacts: true
        )
        person.specialDates = dates.map { candidate in
            SpecialDate(
                title: candidate.title,
                type: candidate.type,
                month: candidate.month,
                day: candidate.day,
                year: candidate.year,
                person: person,
                reminderPreference: settings.makeDefaultReminderPreference()
            )
        }
        return person
    }

    private func cleanOptional(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

@MainActor
final class ContactsService {
    private let store: CNContactStore

    init(store: CNContactStore = CNContactStore()) {
        self.store = store
    }

    func permissionState() -> ContactsPermissionState {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            .notDetermined
        case .authorized:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .limited:
            .authorized
        @unknown default:
            .restricted
        }
    }

    func requestPermission() async -> ContactsPermissionState {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    func fetchImportCandidates(existingPeople: [Person]) async throws -> [ImportedPersonCandidate] {
        let existingContactIDs = Set(existingPeople.compactMap(\.contactIdentifier))
        return try await Task.detached(priority: .userInitiated) {
            try Self.fetchImportCandidates(existingContactIDs: existingContactIDs)
        }.value
    }

    nonisolated private static func fetchImportCandidates(
        existingContactIDs: Set<String>,
        store: CNContactStore = CNContactStore()
    ) throws -> [ImportedPersonCandidate] {
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactDatesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var candidates: [ImportedPersonCandidate] = []

        try store.enumerateContacts(with: request) { contact, _ in
            guard !existingContactIDs.contains(contact.identifier) else { return }

            let name = CNContactFormatter.string(from: contact, style: .fullName)
                ?? [contact.givenName, contact.familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return }

            var dates: [ImportedSpecialDateCandidate] = []
            if let birthday = contact.birthday,
               let birthdayCandidate = Self.candidate(from: birthday, title: "Birthday", type: .birthday) {
                dates.append(birthdayCandidate)
            }

            dates.append(contentsOf: contact.dates.compactMap { labeledDate in
                let label = CNLabeledValue<NSDateComponents>.localizedString(forLabel: labeledDate.label ?? "")
                let type = Self.type(forContactDateLabel: label)
                return Self.candidate(from: labeledDate.value as DateComponents, title: label, type: type)
            })

            guard !dates.isEmpty else { return }
            candidates.append(ImportedPersonCandidate(
                contactIdentifier: contact.identifier,
                fullName: name,
                nickname: contact.nickname,
                organizationName: contact.organizationName,
                imageData: contact.thumbnailImageData,
                dates: dates
            ))
        }

        return candidates.sorted {
            $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
        }
    }

    nonisolated static func duplicateFreeCandidates(
        _ candidates: [ImportedPersonCandidate],
        existingPeople: [Person]
    ) -> [ImportedPersonCandidate] {
        let existingContactIDs = Set(existingPeople.compactMap(\.contactIdentifier))
        return candidates.filter { !existingContactIDs.contains($0.contactIdentifier) }
    }

    nonisolated private static func candidate(
        from components: DateComponents,
        title: String,
        type: SpecialDateType
    ) -> ImportedSpecialDateCandidate? {
        guard let month = components.month, let day = components.day else { return nil }
        return ImportedSpecialDateCandidate(
            title: title,
            type: type,
            month: month,
            day: day,
            year: components.year
        )
    }

    nonisolated private static func type(forContactDateLabel label: String) -> SpecialDateType {
        let lowercased = label.lowercased()

        if lowercased.contains("wedding") {
            return .weddingAnniversary
        }

        if lowercased.contains("work") || lowercased.contains("job") || lowercased.contains("company") {
            return .workAnniversary
        }

        if lowercased.contains("anniversary") {
            return .anniversary
        }

        if lowercased.contains("graduation") || lowercased.contains("graduate") {
            return .graduation
        }

        if lowercased.contains("memorial") || lowercased.contains("remember") {
            return .memorial
        }

        if lowercased.contains("relationship") {
            return .relationshipMilestone
        }

        if lowercased.contains("milestone") {
            return .milestone
        }

        return .custom
    }
}
