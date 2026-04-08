import SwiftUI

struct AppNotification: Identifiable {
    let id: String
    let type: NotifType
    let title: String
    let body: String
    let timeAgo: String
    var isRead: Bool

    enum NotifType {
        case newRecommendation
        case newFollower
        case tasteTwinUpdate
    }

    var icon: String {
        switch type {
        case .newRecommendation: return "🎯"
        case .newFollower:       return "👤"
        case .tasteTwinUpdate:   return "🔄"
        }
    }

    var accentColor: Color {
        switch type {
        case .newRecommendation: return AppTheme.green
        case .newFollower:       return AppTheme.gold
        case .tasteTwinUpdate:   return AppTheme.blue
        }
    }
}

struct NotificationsView: View {
    @State private var notifications = AppNotification.samples
    @State private var showClearConfirm = false

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("الإشعارات")
                        .font(AppTheme.arabic(20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.background)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    if !notifications.isEmpty {
                        Button("قراءة الكل") {
                            withAnimation {
                                for i in notifications.indices { notifications[i].isRead = true }
                            }
                        }
                        .font(AppTheme.arabic(13))
                        .foregroundColor(AppTheme.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                if notifications.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("🔔")
                            .font(.system(size: 52))
                        Text("ما عندك إشعارات")
                            .font(AppTheme.arabic(16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("لما يكون عندك توصيات جديدة أو متابعين جدد راح تظهر هنا")
                            .font(AppTheme.arabic(13))
                            .foregroundColor(AppTheme.textDim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 1) {
                            ForEach(notifications) { notif in
                                NotificationRow(notification: notif) {
                                    withAnimation {
                                        if let idx = notifications.firstIndex(where: { $0.id == notif.id }) {
                                            notifications[idx].isRead = true
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(notification.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text(notification.icon)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(AppTheme.arabic(14, weight: notification.isRead ? .regular : .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(notification.body)
                        .font(AppTheme.arabic(12))
                        .foregroundColor(AppTheme.textDim)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(notification.timeAgo)
                        .font(AppTheme.arabic(11))
                        .foregroundColor(AppTheme.textDim.opacity(0.7))
                }

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(AppTheme.gold)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(notification.isRead ? Color.clear : AppTheme.gold.opacity(0.03))
        }
        .buttonStyle(.plain)
        Divider().background(Color(hex: "#151520")).padding(.leading, 20)
    }
}

// MARK: - Sample Data
extension AppNotification {
    static let samples: [AppNotification] = [
        AppNotification(
            id: "1",
            type: .newRecommendation,
            title: "توصيات جديدة جاهزة 🎯",
            body: "بناءً على تقييماتك الأخيرة، عندنا 5 أفلام ما شفتها بتعجبك",
            timeAgo: "منذ دقيقتين",
            isRead: false
        ),
        AppNotification(
            id: "2",
            type: .newFollower,
            title: "أحمد الزهراني بدأ يتابعك",
            body: "تطابق الذوق بينكم 92% — شوف قائمته",
            timeAgo: "منذ ساعة",
            isRead: false
        ),
        AppNotification(
            id: "3",
            type: .tasteTwinUpdate,
            title: "توأم ذوقك قيّم أفلام جديدة",
            body: "سارة المالكي أضافت 8 تقييمات جديدة قد تهمك",
            timeAgo: "منذ 3 ساعات",
            isRead: true
        ),
        AppNotification(
            id: "4",
            type: .newRecommendation,
            title: "Oppenheimer مرشح لك ⭐",
            body: "4 أشخاص من توأم ذوقك أعطوه 9/10",
            timeAgo: "أمس",
            isRead: true
        ),
    ]
}

