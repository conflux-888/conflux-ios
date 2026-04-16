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

    @MainActor
    func startPolling(token: String) {
        self.token = token
        stopPolling()

        // Initial fetch
        Task { await poll() }

        // Poll every 60 seconds — must be on main RunLoop
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.poll()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    @MainActor
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    func clear() {
        stopPolling()
        token = nil
        unreadCount = 0
        notifications = []
        newBanner = nil
    }

    private func poll() async {
        guard let token else { return }
        do {
            // 1. Fetch unread count
            let count = try await APIService.shared.getUnreadCount(token: token)
            await MainActor.run { self.unreadCount = count }

            // 2. Fetch unread notifications
            let result = try await APIService.shared.getNotifications(unreadOnly: true, limit: 5, token: token)
            let items = result.data

            // 3. Check for truly new notifications
            if let newest = items.first, newest.id != lastSeenId {
                await MainActor.run {
                    self.newBanner = newest
                }
                // Auto-dismiss banner after 4 seconds
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    if self.newBanner?.id == newest.id {
                        self.newBanner = nil
                    }
                }
            }

            if let first = items.first {
                lastSeenId = first.id
            }
        } catch {
            print("[NotificationManager] poll error: \(error)")
        }
    }

    // MARK: - Inbox

    func refreshInbox() async {
        guard let token else { return }
        await MainActor.run { isLoading = true }
        do {
            let result = try await APIService.shared.getNotifications(page: 1, limit: 50, token: token)
            await MainActor.run {
                notifications = result.data
            }
        } catch {
            print("[NotificationManager] refreshInbox error: \(error)")
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
        } catch {
            print("[NotificationManager] markRead error: \(error)")
        }
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
        } catch {
            print("[NotificationManager] markAllRead error: \(error)")
        }
    }

    @MainActor
    func dismissBanner() {
        newBanner = nil
    }
}
