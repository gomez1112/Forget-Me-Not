import Foundation

enum SpecialDateType: String, CaseIterable, Codable, Identifiable, Sendable {
    case birthday
    case anniversary
    case milestone
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .milestone: "Milestone"
        case .custom: "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .birthday: "gift"
        case .anniversary: "heart"
        case .milestone: "sparkles"
        case .custom: "star"
        }
    }
}

enum AppTier: String, CaseIterable, Codable, Identifiable, Sendable {
    case free
    case pro

    var id: String { rawValue }
}
