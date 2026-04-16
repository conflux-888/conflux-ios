import Foundation

// MARK: - App Notification

struct AppNotification: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let title: String
    let body: String
    let eventId: String?
    let summaryDate: String?
    let distanceKm: Double?
    let readAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case eventId = "event_id"
        case summaryDate = "summary_date"
        case distanceKm = "distance_km"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    var isUnread: Bool { readAt == nil }
    var isNearby: Bool { type == "critical_nearby" }
    var isBriefing: Bool { type == "daily_briefing" }

    var typeLabel: String {
        switch type {
        case "critical_nearby": return "CRITICAL NEARBY"
        case "daily_briefing": return "DAILY BRIEFING"
        default: return type.uppercased()
        }
    }

    var relativeTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: createdAt)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: createdAt)
        }
        guard let d = date else { return "" }
        return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
    }

    var formattedDistance: String? {
        guard let km = distanceKm else { return nil }
        if km < 1 {
            return String(format: "%.0f M", km * 1000)
        }
        return String(format: "%.1f KM", km)
    }
}

// MARK: - Unread Count

struct UnreadCountResponse: Codable {
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    let notificationsEnabled: Bool
    let minSeverity: String
    let radiusKm: Double
    let lastLocation: GeoJSONPoint?
    let lastLocationAt: String?

    enum CodingKeys: String, CodingKey {
        case notificationsEnabled = "notifications_enabled"
        case minSeverity = "min_severity"
        case radiusKm = "radius_km"
        case lastLocation = "last_location"
        case lastLocationAt = "last_location_at"
    }
}

struct UpdatePreferencesRequest: Encodable {
    var notificationsEnabled: Bool?
    var minSeverity: String?
    var radiusKm: Double?

    enum CodingKeys: String, CodingKey {
        case notificationsEnabled = "notifications_enabled"
        case minSeverity = "min_severity"
        case radiusKm = "radius_km"
    }
}

// MARK: - Message Response

struct MessageResponse: Codable {
    let message: String
}

struct ModifiedCountResponse: Codable {
    let modifiedCount: Int

    enum CodingKeys: String, CodingKey {
        case modifiedCount = "modified_count"
    }
}
