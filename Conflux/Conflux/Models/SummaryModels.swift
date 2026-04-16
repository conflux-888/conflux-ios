import Foundation
import SwiftUI

// MARK: - Daily Summary

struct DailySummary: Codable, Identifiable {
    let id: String
    let summaryDate: String
    let status: String
    let eventCount: Int
    let incidentCount: Int?
    let title: String
    let content: String
    let topEvents: [TopEvent]?
    let severityBreakdown: SeverityBreakdown
    let model: String?
    let promptTokens: Int?
    let completionTokens: Int?
    let generationNumber: Int?
    let generatedAt: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case summaryDate = "summary_date"
        case status
        case eventCount = "event_count"
        case incidentCount = "incident_count"
        case title
        case content
        case topEvents = "top_events"
        case severityBreakdown = "severity_breakdown"
        case model
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case generationNumber = "generation_number"
        case generatedAt = "generated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isCompleted: Bool { status == "completed" }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: summaryDate) else { return summaryDate }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy"
        return display.string(from: date).uppercased()
    }

    var formattedGeneratedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: generatedAt)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: generatedAt)
        }
        guard let d = date else { return generatedAt }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm 'UTC'"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.string(from: d)
    }
}

// MARK: - Top Event

struct TopEvent: Codable, Identifiable {
    var id: String { title + country }
    let title: String
    let severity: String
    let country: String
    let location: String
    let description: String

    var severityColor: Color {
        switch severity {
        case "critical": return .cxCritical
        case "high": return .cxHigh
        case "medium": return .cxMedium
        case "low": return .cxLow
        default: return .cxTextTertiary
        }
    }

    var severityLabel: String { severity.uppercased() }
}

// MARK: - Severity Breakdown

struct SeverityBreakdown: Codable {
    let critical: Int
    let high: Int
    let medium: Int
    let low: Int

    var total: Int { critical + high + medium + low }
}
