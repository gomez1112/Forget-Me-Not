import Foundation

enum SpecialDateType: String, CaseIterable, Codable, Identifiable, Sendable {
    case birthday
    case anniversary
    case weddingAnniversary
    case workAnniversary
    case relationshipMilestone
    case graduation
    case memorial
    case milestone
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .weddingAnniversary: "Wedding Anniversary"
        case .workAnniversary: "Work Anniversary"
        case .relationshipMilestone: "Relationship Milestone"
        case .graduation: "Graduation"
        case .memorial: "Memorial"
        case .milestone: "Milestone"
        case .custom: "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .birthday: "gift"
        case .anniversary: "heart"
        case .weddingAnniversary: "heart.circle"
        case .workAnniversary: "briefcase"
        case .relationshipMilestone: "heart.text.square"
        case .graduation: "graduationcap"
        case .memorial: "flame"
        case .milestone: "sparkles"
        case .custom: "star"
        }
    }
}

enum SpecialDateRecurrence: String, CaseIterable, Codable, Identifiable, Sendable {
    case yearly
    case monthly
    case oneTime
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .oneTime: "One Time"
        case .custom: "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .yearly: "repeat"
        case .monthly: "calendar"
        case .oneTime: "calendar.badge.exclamationmark"
        case .custom: "slider.horizontal.3"
        }
    }

    var requiresExactStartDate: Bool {
        switch self {
        case .oneTime, .custom:
            true
        case .yearly, .monthly:
            false
        }
    }
}

enum AppTier: String, CaseIterable, Codable, Identifiable, Sendable {
    case free
    case pro

    var id: String { rawValue }
}
