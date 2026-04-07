import SwiftUI

struct DiscoverView: View {
    // Mock data — will be replaced with Firestore data
    @State private var users: [MockUser] = MockUser.samples
    @State private var followedIds: Set<String> = []

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("🌟 مستخدمين قريبين من ذوقك")
                            .font(AppTheme.arabic(16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    LazyVStack(spacing: 10) {
                        ForEach(users.sorted { $0.matchPercentage > $1.matchPercentage }) { user in
                            UserCard(
                                user: user,
                                isFollowing: followedIds.contains(user.id)
                            ) {
                                withAnimation {
                                    if followedIds.contains(user.id) {
                                        followedIds.remove(user.id)
                                    } else {
                                        followedIds.insert(user.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - User Card
struct UserCard: View {
    let user: MockUser
    let isFollowing: Bool
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 48, height: 48)
                Text(user.emoji)
                    .font(.system(size: 24))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(AppTheme.arabic(14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(user.tasteBadge)
                    .font(AppTheme.arabic(11))
                    .foregroundColor(AppTheme.textDim)
                Text("تطابق \(user.matchPercentage)%")
                    .font(AppTheme.arabic(10))
                    .foregroundColor(AppTheme.green)
            }

            Spacer()

            // Follow button
            Button(action: onFollow) {
                Text(isFollowing ? "تتابعه" : "تابع")
                    .font(AppTheme.arabic(12, weight: .semibold))
                    .foregroundColor(isFollowing ? AppTheme.textDim : AppTheme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color.clear : AppTheme.gold)
                    .overlay(
                        Capsule().stroke(
                            isFollowing ? Color(hex: "#333333") : Color.clear,
                            lineWidth: 1
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
    }
}

// MARK: - Mock Data
struct MockUser: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let tasteBadge: String
    let matchPercentage: Int

    static let samples: [MockUser] = [
        MockUser(id: "1", name: "أحمد الزهراني", emoji: "🎭", tasteBadge: "دراما + إثارة", matchPercentage: 92),
        MockUser(id: "2", name: "سارة المالكي",  emoji: "🎬", tasteBadge: "خيال علمي + أكشن", matchPercentage: 87),
        MockUser(id: "3", name: "خالد العمري",   emoji: "🍿", tasteBadge: "جريمة + تشويق",  matchPercentage: 83),
        MockUser(id: "4", name: "نورة السبيعي",  emoji: "🎥", tasteBadge: "رومانسي + درامي", matchPercentage: 79),
        MockUser(id: "5", name: "فيصل القحطاني", emoji: "📽", tasteBadge: "كوميدي + دراما",  matchPercentage: 74),
    ]
}
