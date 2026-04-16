import SwiftUI

struct NotificationBellView: View {
    @Environment(NotificationManager.self) private var notifManager
    @State private var showInbox = false

    var body: some View {
        Button {
            showInbox = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(.cxText)

                if notifManager.unreadCount > 0 {
                    Text(notifManager.unreadCount > 99 ? "99+" : "\(notifManager.unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.cxCritical)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -6)
                }
            }
        }
        .sheet(isPresented: $showInbox) {
            NotificationInboxView()
                .presentationBackground(Color.cxBackground)
        }
    }
}
