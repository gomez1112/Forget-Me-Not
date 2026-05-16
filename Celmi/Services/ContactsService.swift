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
    var dates: [ImportedSpecialDateCandidate]
    var isSelected: Bool = true

    func makePerson(settings: AppSettings) -> Person {
        let person = Person(
            fullName: fullName,
            contactIdentifier: contactIdentifier,
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

    func fetchImportCandidates(existingPeople: [Person]) throws -> [ImportedPersonCandidate] {
        let existingContactIDs = Set(existingPeople.compactMap(\.contactIdentifier))
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactDatesKey as CNKeyDescriptor
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
                let lowercased = label.lowercased()
                let type: SpecialDateType = lowercased.contains("anniversary") ? .anniversary : .custom
                return Self.candidate(from: labeledDate.value as DateComponents, title: label, type: type)
            })

            guard !dates.isEmpty else { return }
            candidates.append(ImportedPersonCandidate(
                contactIdentifier: contact.identifier,
                fullName: name,
                dates: dates
            ))
        }

        return candidates.sorted {
            $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
        }
    }

    static func duplicateFreeCandidates(
        _ candidates: [ImportedPersonCandidate],
        existingPeople: [Person]
    ) -> [ImportedPersonCandidate] {
        let existingContactIDs = Set(existingPeople.compactMap(\.contactIdentifier))
        return candidates.filter { !existingContactIDs.contains($0.contactIdentifier) }
    }

    private static func candidate(
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
}
