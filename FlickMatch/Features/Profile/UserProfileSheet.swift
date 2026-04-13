import SwiftUI

/// Sheet that shows another user's profile (from Discover or Following list)
struct UserProfileSheet: View {
    let userId: String
    let userName: String
    let tasteBadge: String
    let matchPercentage: Int?

    @State private var ratings: [FirestoreRating] = []
    @State private var isLoading = true
    @State private var selectedTab: TabChoice = .movies
    @State private var isFollowing = false
    @Environment(\.dismiss) private var dismiss

    enum TabChoice { case movies, series }

    private var movieRatings: [FirestoreRating] {
        ratings.filter { $0.contentType == "movie" && $0.score > 0 }
            .sorted { $0.score > $1.score }
    }

    private var seriesRatings: [FirestoreRating] {
        ratings.filter { $0.contentType == "series" && $0.score > 0 }
            .sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.textDim)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Avatar + name
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [AppTheme.gold, AppTheme.goldDim],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 70, height: 70)
                                Text(String(userName.prefix(1)))
                                    .font(AppTheme.arabic(28, weight: .bold))
                                    .foregroundColor(AppTheme.background)
                            }

                            Text(userName)
                                .font(AppTheme.arabic(18, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(tasteBadge)
                                .font(AppTheme.arabic(13))
                                .foregroundColor(AppTheme.textDim)

                            // Match badge
                            if let pct = matchPercentage {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                    Text("تطابق \(pct)%")
                                        .font(AppTheme.arabic(12, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.green)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(AppTheme.green.opacity(0.08))
                                .cornerRadius(12)
                            } else {
                                Text("قيّم أفلام أكثر عشان نحسب التطابق")
                                    .font(AppTheme.arabic(11))
                                    .foregroundColor(AppTheme.textDim)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.surface)
                                    .cornerRadius(12)
                            }

                            // Follow button
                            Button {
                                withAnimation {
                                    isFollowing.toggle()
                                    Task {
                                        guard let myUid = AuthService.shared.userId else { return }
                                        if isFollowing {
                                            await FirestoreService.shared.follow(followerId: myUid, followingId: userId)
                                        } else {
                                            await FirestoreService.shared.unfollow(followerId: myUid, followingId: userId)
                                        }
                                    }
                                }
                            } label: {
                                Text(isFollowing ? "تتابعه ✓" : "+ تابع")
                                    .font(AppTheme.arabic(13, weight: .semibold))
                                    .foregroundColor(isFollowing ? AppTheme.textDim : AppTheme.background)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(isFollowing ? Color.clear : AppTheme.gold)
                                    .overlay(
                                        Capsule().stroke(
                                            isFollowing ? Color(hex: "#333333") : Color.clear,
                                            lineWidth: 1
                                        )
                                    )
                                    .clipShape(Capsule())
                            }

                            // Stats
                            HStack(spacing: 30) {
                                ProfileStat(value: "\(movieRatings.count)", label: "أفلام")
                                ProfileStat(value: "\(seriesRatings.count)", label: "مسلسلات")
                            }
                            .padding(.top, 4)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)

                        if isLoading {
                            ProgressView().tint(AppTheme.gold)
                                .padding(.top, 40)
                        } else {
                            // Tabs
                            HStack(spacing: 0) {
                                tabButton(title: "🎬 أفلام", tab: .movies)
                                tabButton(title: "📺 مسلسلات", tab: .series)
                            }
                            .padding(.horizontal, 20)

                            // Ratings grid
                            let items = selectedTab == .movies ? movieRatings : seriesRatings
                            if items.isEmpty {
                                Text("ما عنده تقييمات بعد")
                                    .font(AppTheme.arabic(14))
                                    .foregroundColor(AppTheme.textDim)
                                    .padding(.top, 30)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 16) {
                                    ForEach(items, id: \.contentId) { rating in
                                        NavigationLink(value: ratingToMedia(rating)) {
                                            VStack(spacing: 6) {
                                                AsyncImage(url: posterURL(for: rating)) { phase in
                                                    switch phase {
                                                    case .success(let img): img.resizable().scaledToFill()
                                                    default: Rectangle().fill(AppTheme.surface)
                                                    }
                                                }
                                                .frame(height: 150)
                                                .cornerRadius(8)
                                                .clipped()

                                                Text(rating.title)
                                                    .font(AppTheme.arabic(10))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(1)

                                                Text("\(rating.score)/10 ⭐")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(AppTheme.gold)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadRatings()
            await loadFollowState()
        }
    }

    private func tabButton(title: String, tab: TabChoice) -> some View {
        Button { withAnimation { selectedTab = tab } } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.arabic(13, weight: selectedTab == tab ? .bold : .regular))
                    .foregroundColor(selectedTab == tab ? AppTheme.gold : AppTheme.textDim)
                Rectangle()
                    .fill(selectedTab == tab ? AppTheme.gold : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func loadRatings() async {
        ratings = await FirestoreService.shared.fetchUserRatings(userId: userId)
        isLoading = false
    }

    private func loadFollowState() async {
        guard let myUid = await AuthService.shared.userId else { return }
        isFollowing = await FirestoreService.shared.isFollowing(followerId: myUid, followingId: userId)
    }

    private func posterURL(for r: FirestoreRating) -> URL? {
        guard !r.posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(r.posterPath)")
    }

    private func ratingToMedia(_ r: FirestoreRating) -> AnyMedia {
        if r.contentType == "movie" {
            return .movie(Movie(
                id: r.contentId, title: r.title, originalTitle: r.title, overview: "",
                posterPath: r.posterPath.isEmpty ? nil : r.posterPath, backdropPath: nil,
                voteAverage: Double(r.score), genreIds: [],
                releaseDate: r.year.isEmpty ? nil : "\(r.year)-01-01"
            ))
        } else {
            return .series(Series(
                id: r.contentId, name: r.title, originalName: r.title, overview: "",
                posterPath: r.posterPath.isEmpty ? nil : r.posterPath, backdropPath: nil,
                voteAverage: Double(r.score), genreIds: [],
                firstAirDate: r.year.isEmpty ? nil : "\(r.year)-01-01", numberOfSeasons: nil
            ))
        }
    }
}
