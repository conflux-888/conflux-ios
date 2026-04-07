import Foundation
import CoreLocation
import SwiftUI

// MARK: - GeoJSON

struct GeoJSONPoint: Codable {
    let type: String
    let coordinates: [Double] // [longitude, latitude]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
    }
}

// MARK: - Event

struct Event: Codable, Identifiable, Hashable {
    let id: String
    let source: String
    let externalId: String?
    let eventType: String
    let subEventType: String?
    let eventRootCode: String?
    let severity: String
    let title: String
    let description: String?
    let country: String
    let locationName: String?
    let location: GeoJSONPoint
    let numSources: Int?
    let numArticles: Int?
    let actors: [String]?
    let eventDate: String
    let isDeleted: Bool?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case source
        case externalId = "external_id"
        case eventType = "event_type"
        case subEventType = "sub_event_type"
        case eventRootCode = "event_root_code"
        case severity
        case title
        case description
        case country
        case locationName = "location_name"
        case location
        case numSources = "num_sources"
        case numArticles = "num_articles"
        case actors
        case eventDate = "event_date"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: Event, rhs: Event) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var coordinate: CLLocationCoordinate2D { location.coordinate }

    var severityColor: Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return Color(red: 0.9, green: 0.75, blue: 0)
        case "low": return .green
        default: return .gray
        }
    }

    var severityIcon: String {
        switch severity {
        case "critical": return "flame.fill"
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "exclamationmark.circle.fill"
        case "low": return "info.circle.fill"
        default: return "circle.fill"
        }
    }

    var severityLabel: String { severity.capitalized }

    var sourceDisplayName: String {
        source == "gdelt" ? "GDELT News" : "User Report"
    }

    var sourceColor: Color {
        source == "gdelt" ? .blue : .purple
    }

    var sourceIcon: String {
        source == "gdelt" ? "newspaper.fill" : "person.fill"
    }

    var eventTypeDisplayName: String {
        eventType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: eventDate)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: eventDate)
        }
        guard let d = date else { return eventDate }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: d)
    }

    var relativeDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: eventDate)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: eventDate)
        }
        guard let d = date else { return eventDate }
        return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
    }
}

// MARK: - User

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - API Response Wrappers

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let error: APIErrorBody?
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: Pagination?
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
}

struct APIErrorBody: Codable {
    let code: String
    let message: String
}

// MARK: - Auth Responses

struct LoginResponse: Codable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Filter Enums

enum SourceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case gdelt = "GDELT"
    case userReport = "User Reports"

    var id: String { rawValue }

    var apiValue: String? {
        switch self {
        case .all: return nil
        case .gdelt: return "gdelt"
        case .userReport: return "user_report"
        }
    }

    var icon: String {
        switch self {
        case .all: return "globe"
        case .gdelt: return "newspaper.fill"
        case .userReport: return "person.fill"
        }
    }
}

enum SeverityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var id: String { rawValue }

    var apiValue: String? { self == .all ? nil : rawValue.lowercased() }

    var color: Color {
        switch self {
        case .all: return .primary
        case .critical: return .red
        case .high: return .orange
        case .medium: return Color(red: 0.9, green: 0.75, blue: 0)
        case .low: return .green
        }
    }
}

// MARK: - Report Event Types

enum ReportEventType: String, CaseIterable, Identifiable {
    case armedConflict = "armed_conflict"
    case useOfForce = "use_of_force"
    case explosion = "explosion"
    case terrorism = "terrorism"
    case civilUnrest = "civil_unrest"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .armedConflict: return "Armed Conflict"
        case .useOfForce: return "Use of Force"
        case .explosion: return "Explosion"
        case .terrorism: return "Terrorism"
        case .civilUnrest: return "Civil Unrest"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .armedConflict: return "shield.fill"
        case .useOfForce: return "hand.raised.fill"
        case .explosion: return "flame.fill"
        case .terrorism: return "exclamationmark.triangle.fill"
        case .civilUnrest: return "person.3.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

enum ReportSeverity: String, CaseIterable, Identifiable {
    case critical, high, medium, low

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return Color(red: 0.9, green: 0.75, blue: 0)
        case .low: return .green
        }
    }
}
