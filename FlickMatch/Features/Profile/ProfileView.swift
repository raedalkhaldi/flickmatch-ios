import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var ratingStore: RatingStore
    @EnvironmentObject var auth: AuthService
    @State private var selectedTab: ProfileTab = .movies

    enum ProfileTab { case movies, series }

    private var topMovies: [StoredRating] {
        ratingStore.fetchAll(contentType: .movie)
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(10).map { $0 }
    }

    private var topSeries: [StoredRating] {
        ratingStore.fetchAll(contentType: .series)
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(10).map { $0 }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppTheme.gold, AppTheme.goldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.gold.opacity(0.3), radius: 20)
                            Text("👤")
                                .font(.system(size: 32))
                        }

                        VStack(spacing: 2) {
                            Text(auth.displayName ?? "أنت")
                                .font(AppTheme.arabic(20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            if let uid = auth.userId {
                                Text("@\(String(uid.prefix(8)))")
                                    .font(AppTheme.arabic(13))
                                    .foregroundColor(AppTheme.textDim)
                            }
                        }

                        // Stats from real data
                        HStack(spacing: 30) {
                            ProfileStat(value: "\(ratingStore.ratedCount(contentType: .movie))", label: "أفلام")
                            ProfileStat(value: "\(ratingStore.ratedCount(contentType: .series))", label: "مسلسلات")
                        }

                        // Sign out
                        Button {
                            auth.signOut()
                        } label: {
                            Text("تسجيل خروج")
                                .font(AppTheme.arabic(12))
                                .foregroundColor(AppTheme.textDim)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .overlay(
                                    Capsule().stroke(Color(hex: "#333333"), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                    // Tabs
                    HStack(spacing: 0) {
                        ProfileTabButton(title: "🎬 أعلى 10 أفلام",    tab: .movies,  selected: $selectedTab)
                        ProfileTabButton(title: "📺 أعلى 10 مسلسلات", tab: .series, selected: $selectedTab)
                    }
                    .padding(.horizontal, 20)

                    // Top list
                    let items = selectedTab == .movies ? topMovies : topSeries
                    if items.isEmpty {
                        VStack(spacing: 12) {
                            Text("🎬")
                                .font(.system(size: 48))
                            Text("ما عندك تقييمات بعد")
                                .font(AppTheme.arabic(15))
                                .foregroundColor(AppTheme.textDim)
                            Text("ابدأ بتقييم أفلام من الرئيسية")
                                .font(AppTheme.arabic(13))
                                .foregroundColor(AppTheme.textDim)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.contentId) { idx, item in
                                NavigationLink(value: item.toAnyMedia()) {
                                    TopListRow(rating: item, rank: idx + 1)
                                }
                                .padding(.horizontal, 20)
                                if idx < items.count - 1 {
                                    Divider()
                                        .background(Color(hex: "#151520"))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Profile Stat
struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.gold)
            Text(label)
                .font(AppTheme.arabic(11))
                .foregroundColor(AppTheme.textDim)
        }
    }
}

// MARK: - Profile Tab Button
struct ProfileTabButton: View {
    let title: String
    let tab: ProfileView.ProfileTab
    @Binding var selected: ProfileView.ProfileTab

    var body: some View {
        Button { selected = tab } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.arabic(13, weight: selected == tab ? .bold : .regular))
                    .foregroundColor(selected == tab ? AppTheme.gold : AppTheme.textDim)
                Rectangle()
                    .fill(selected == tab ? AppTheme.gold : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Top List Row (real data)
struct TopListRow: View {
    let rating: StoredRating
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(AppTheme.english(14, weight: .black))
                .foregroundColor(AppTheme.gold)
                .frame(width: 24)

            // Poster thumbnail
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default:
                    Rectangle().fill(AppTheme.surface)
                        .overlay(Image(systemName: "film").foregroundColor(AppTheme.textDim).font(.system(size: 16)))
                }
            }
            .frame(width: 44, height: 64)
            .cornerRadius(6)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(rating.title)
                    .font(AppTheme.arabic(13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(rating.year)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDim)
                    Text(rating.contentType == "movie" ? "فيلم" : "مسلسل")
                        .font(AppTheme.arabic(10))
                        .foregroundColor(AppTheme.textDim)
                }
            }

            Spacer()

            Text("\(rating.score) ⭐")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.gold)
        }
        .padding(.vertical, 10)
    }

    private var posterURL: URL? {
        guard !rating.posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(rating.posterPath)")
    }
}
