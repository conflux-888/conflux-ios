import SwiftUI

struct NotificationInboxView: View {
    @Environment(NotificationManager.self) private var notifManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEvent: Event?

    var body: some View {
        NavigationStack {
            Group {
                if notifManager.isLoading && notifManager.notifications.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(.cxAccent)
                        Text("LOADING").font(.cxData).foregroundStyle(.cxTextSecondary).tracking(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifManager.notifications.isEmpty {
                    ContentUnavailableView {
                        Label("No Notifications", systemImage: "bell.slash")
                            .foregroundStyle(.cxAccent)
                    } description: {
                        Text("You'll be notified of nearby threats and daily briefings.")
                            .foregroundStyle(.cxTextSecondary)
                    }
                } else {
                    List {
                        ForEach(notifManager.notifications) { notif in
                            Button {
                                Task { await handleTap(notif) }
                            } label: {
                                NotificationRow(notification: notif)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                if notif.isUnread {
                                    Button {
                                        Task { await notifManager.markRead(notif) }
                                    } label: {
                                        Label("Read", systemImage: "envelope.open")
                                    }
                                    .tint(.cxAccent)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await notifManager.refreshInbox() }
                }
            }
            .background(Color.cxBackground)
            .navigationTitle("NOTIFICATIONS")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.cxAccent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cxAccent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if notifManager.unreadCount > 0 {
                        Button {
                            Task { await notifManager.markAllRead() }
                        } label: {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                                .font(.cxData)
                        }
                        .foregroundStyle(.cxAccent)
                    }
                }
            }
            .task { await notifManager.refreshInbox() }
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.cxBackground)
            }
        }
    }

    private func handleTap(_ notif: AppNotification) async {
        // Mark as read
        if notif.isUnread {
            await notifManager.markRead(notif)
        }

        // Navigate based on type
        if notif.isNearby, let eventId = notif.eventId {
            // Fetch event and show detail
            guard let token = UserDefaults.standard.string(forKey: "conflux_token") else { return }
            if let event = try? await APIService.shared.getEvent(id: eventId, token: token) {
                selectedEvent = event
            }
        }
        // daily_briefing navigation would require switching tabs — for now just mark read
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Unread indicator
            Circle()
                .fill(notification.isUnread ? Color.cxAccent : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            // Type color bar
            RoundedRectangle(cornerRadius: 1)
                .fill(notification.isNearby ? Color.cxCritical : Color.cxAccent)
                .frame(width: 3)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                // Type + time
                HStack(spacing: 6) {
                    Text(notification.typeLabel)
                        .font(.cxData)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(notification.isNearby ? Color.cxCritical.opacity(0.1) : Color.cxAccent.opacity(0.1))
                        .foregroundStyle(notification.isNearby ? .cxCritical : .cxAccent)
                        .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                    Spacer()

                    Text(notification.relativeTime)
                        .font(.cxMono)
                        .foregroundStyle(.cxTextTertiary)
                        .lineLimit(1)
                        .layoutPriority(-1)
                }

                // Title
                Text(notification.title)
                    .font(.cxBody)
                    .fontWeight(notification.isUnread ? .semibold : .regular)
                    .foregroundStyle(notification.isUnread ? .cxText : .cxTextSecondary)
                    .lineLimit(1)

                // Body
                Text(notification.body)
                    .font(.cxData)
                    .foregroundStyle(.cxTextSecondary)
                    .lineLimit(2)

                // Distance (for nearby)
                if let distance = notification.formattedDistance {
                    Text(distance)
                        .font(.cxMono)
                        .foregroundStyle(.cxAccent)
                }

                // Summary date (for briefing)
                if let date = notification.summaryDate {
                    Text(date)
                        .font(.cxMono)
                        .foregroundStyle(.cxAccent)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }
}
