import SwiftUI

struct NotificationBannerView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Severity/type bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(notification.isNearby ? Color.cxCritical : Color.cxAccent)
                    .frame(width: 3, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(notification.typeLabel)
                            .font(.cxData)
                            .foregroundStyle(notification.isNearby ? .cxCritical : .cxAccent)

                        if let distance = notification.formattedDistance {
                            Text(distance)
                                .font(.cxMono)
                                .foregroundStyle(.cxAccent)
                        }

                        Spacer()

                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.cxTextTertiary)
                                .frame(width: 24, height: 24)
                        }
                    }

                    Text(notification.title)
                        .font(.cxBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.cxText)
                        .lineLimit(1)

                    Text(notification.body)
                        .font(.cxData)
                        .foregroundStyle(.cxTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.cxSurface)
            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                    .stroke(notification.isNearby ? Color.cxCritical.opacity(0.4) : Color.cxBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
