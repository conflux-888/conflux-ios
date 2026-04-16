import Foundation
import SwiftUI
import Observation

@Observable
class NotificationManager {
    var unreadCount: Int = 0
    var notifications: [AppNotification] = []
    var newBanner: AppNotification?
    var isLoading = false

    private var timer: Timer?
    private var token: String?
    private let lastSeenKey = "conflux_last_seen_notification"

    private var lastSeenId: String? {
        get { UserDefaults.standard.string(forKey: lastSeenKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastSeenKey) }
    }

    // MARK: - Polling

    func startPolling(token: String) {
        self.token = token
        stopPolling()

        // Initial fetch
        Task { await poll() }

        // Poll every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.poll() }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        token = nil
    }

    func clear() {
        stopPolling()
        unreadCount = 0
        notifications = []
        newBanner = nil
    }

    private func poll() async {
        guard let token else { return }
        do {
            // 1. Fetch unread count
            let count = try await APIService.shared.getUnreadCount(token: token)
            await MainActor.run { unreadCount = count }

            // 2. Fetch unread notifications to detect new ones
            let result = try await APIService.shared.getNotifications(unreadOnly: true, limit: 5, token: token)
            let items = result.data ?? []

            // 3. Check for truly new notifications
            if let newest = items.first, newest.id != lastSeenId {
                await MainActor.run {
                    newBanner = newest
                }
                // Auto-dismiss banner after 4 seconds
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    if newBanner?.id == newest.id {
                        newBanner = nil
                    }
                }
            }

            if let first = items.first {
                lastSeenId = first.id
            }
        } catch {
            // Silent fail — polling continues
        }
    }

    // MARK: - Inbox

    func refreshInbox() async {
        guard let token else { return }
        isLoading = true
        do {
            let result = try await APIService.shared.getNotifications(page: 1, limit: 50, token: token)
            await MainActor.run {
                notifications = result.data ?? []
            }
        } catch {
            // Silent
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Actions

    func markRead(_ notification: AppNotification) async {
        guard let token else { return }
        do {
            try await APIService.shared.markNotificationAsRead(id: notification.id, token: token)
            await MainActor.run {
                if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                    // Replace with a read version
                    let n = notifications[idx]
                    let read = AppNotification(
                        id: n.id, type: n.type, title: n.title, body: n.body,
                        eventId: n.eventId, summaryDate: n.summaryDate,
                        distanceKm: n.distanceKm,
                        readAt: ISO8601DateFormatter().string(from: Date()),
                        createdAt: n.createdAt
                    )
                    notifications[idx] = read
                }
                if unreadCount > 0 { unreadCount -= 1 }
            }
        } catch {}
    }

    func markAllRead() async {
        guard let token else { return }
        do {
            try await APIService.shared.markAllNotificationsAsRead(token: token)
            await MainActor.run {
                let now = ISO8601DateFormatter().string(from: Date())
                notifications = notifications.map { n in
                    AppNotification(
                        id: n.id, type: n.type, title: n.title, body: n.body,
                        eventId: n.eventId, summaryDate: n.summaryDate,
                        distanceKm: n.distanceKm, readAt: n.readAt ?? now,
                        createdAt: n.createdAt
                    )
                }
                unreadCount = 0
            }
        } catch {}
    }

    func dismissBanner() {
        newBanner = nil
    }
}
