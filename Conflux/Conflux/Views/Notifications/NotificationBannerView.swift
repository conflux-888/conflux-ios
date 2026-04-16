import SwiftUI

struct NotificationBannerView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Severity/type bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(notification.isNearby ? Color.cxCritical : Color.cxAccent)
                    .frame(width: 4)

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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cxSurface)
            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                    .stroke(notification.isNearby ? Color.cxCritical.opacity(0.4) : Color.cxBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
