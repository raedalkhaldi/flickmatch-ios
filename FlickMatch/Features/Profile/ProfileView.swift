import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var ratingStore: RatingStore
    @EnvironmentObject var watchlistStore: WatchlistStore
    @EnvironmentObject var auth: AuthService
    @State private var selectedTab: ProfileTab = .movies
    @State private var followingUsers: [FollowingUser] = []
    @State private var isLoadingFollowing = true
    @State private var showSettings = false

    enum ProfileTab { case movies, series, watchlist, following }

    struct FollowingUser: Identifiable {
        let id: String
        let name: String
        let tasteBadge: String
    }

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
                    // Top bar with settings gear
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.textDim)
                                .frame(width: 36, height: 36)
                                .background(AppTheme.surface)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

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

                        // Stats
                        HStack(spacing: 24) {
                            ProfileStat(value: "\(ratingStore.ratedCount(contentType: .movie))", label: "أفلام")
                            ProfileStat(value: "\(ratingStore.ratedCount(contentType: .series))", label: "مسلسلات")
                            ProfileStat(value: "\(followingUsers.count)", label: "متابَع")
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                    // Tabs
                    HStack(spacing: 0) {
                        ProfileTabButton(title: "🎬 أفلام", tab: .movies, selected: $selectedTab)
                        ProfileTabButton(title: "📺 مسلسلات", tab: .series, selected: $selectedTab)
                        ProfileTabButton(title: "🔖 أشوفه", tab: .watchlist, selected: $selectedTab)
                        ProfileTabButton(title: "👥 متابَع", tab: .following, selected: $selectedTab)
                    }
                    .padding(.horizontal, 20)

                    // Content
                    switch selectedTab {
                    case .movies, .series:
                        topListContent
                    case .watchlist:
                        watchlistContent
                    case .following:
                        followingContent
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .onAppear {
            Task { await loadFollowing() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(auth)
        }
    }

    // MARK: - Top List
    @ViewBuilder
    private var topListContent: some View {
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

    // MARK: - Watchlist
    @ViewBuilder
    private var watchlistContent: some View {
        let items = watchlistStore.fetchAll()
        if items.isEmpty {
            VStack(spacing: 12) {
                Text("🔖")
                    .font(.system(size: 48))
                Text("ما عندك شي بالقائمة بعد")
                    .font(AppTheme.arabic(15))
                    .foregroundColor(AppTheme.textDim)
                Text("اضغط \"أشوفه لاحقاً\" على أي فيلم أو مسلسل")
                    .font(AppTheme.arabic(13))
                    .foregroundColor(AppTheme.textDim)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.contentId) { idx, item in
                    NavigationLink(value: item.toAnyMedia()) {
                        WatchlistRow(item: item)
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

    // MARK: - Following List
    @ViewBuilder
    private var followingContent: some View {
        if isLoadingFollowing {
            ProgressView().tint(AppTheme.gold)
                .padding(.top, 40)
        } else if followingUsers.isEmpty {
            VStack(spacing: 12) {
                Text("👥")
                    .font(.system(size: 48))
                Text("ما تتابع أحد بعد")
                    .font(AppTheme.arabic(15))
                    .foregroundColor(AppTheme.textDim)
                Text("روح لـ اكتشف وتابع ناس بنفس ذوقك")
                    .font(AppTheme.arabic(13))
                    .foregroundColor(AppTheme.textDim)

                Button {
                    coordinator.selectedTab = .discover
                } label: {
                    Text("اكتشف مستخدمين")
                        .font(AppTheme.arabic(13, weight: .semibold))
                        .foregroundColor(AppTheme.background)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(AppTheme.gold)
                        .cornerRadius(16)
                }
                .padding(.top, 4)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(followingUsers) { user in
                    FollowingRow(user: user)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    private func loadFollowing() async {
        guard let uid = auth.userId else {
            isLoadingFollowing = false
            return
        }
        let followedIds = await FirestoreService.shared.fetchFollowedIds(userId: uid)
        var users: [FollowingUser] = []
        for fid in followedIds {
            if let profile = await FirestoreService.shared.fetchUserProfile(uid: fid) {
                users.append(FollowingUser(
                    id: fid,
                    name: profile.displayName,
                    tasteBadge: profile.tasteBadge.isEmpty ? "محب أفلام" : profile.tasteBadge
                ))
            }
        }
        followingUsers = users
        isLoadingFollowing = false
    }
}

// MARK: - Following Row (tappable → opens user profile sheet)
struct FollowingRow: View {
    let user: ProfileView.FollowingUser
    @State private var showProfile = false

    var body: some View {
        Button { showProfile = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 44, height: 44)
                    Text(String(user.name.prefix(1)))
                        .font(AppTheme.arabic(18, weight: .bold))
                        .foregroundColor(AppTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(AppTheme.arabic(14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(user.tasteBadge)
                        .font(AppTheme.arabic(11))
                        .foregroundColor(AppTheme.textDim)
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textDim)
            }
            .padding(12)
            .background(AppTheme.card)
            .cornerRadius(AppTheme.radius)
        }
        .sheet(isPresented: $showProfile) {
            UserProfileSheet(
                userId: user.id,
                userName: user.name,
                tasteBadge: user.tasteBadge,
                matchPercentage: 0
            )
        }
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
                    .font(AppTheme.arabic(12, weight: selected == tab ? .bold : .regular))
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

// MARK: - Top List Row
struct TopListRow: View {
    let rating: StoredRating
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(AppTheme.english(14, weight: .black))
                .foregroundColor(AppTheme.gold)
                .frame(width: 24)

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

// MARK: - Watchlist Row
struct WatchlistRow: View {
    let item: WatchlistItem
    @EnvironmentObject var watchlistStore: WatchlistStore

    var body: some View {
        HStack(spacing: 12) {
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
                Text(item.title)
                    .font(AppTheme.arabic(13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.year)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDim)
                    Text(item.contentType == "movie" ? "فيلم" : "مسلسل")
                        .font(AppTheme.arabic(10))
                        .foregroundColor(AppTheme.textDim)
                }
            }

            Spacer()

            // Remove from watchlist
            Button {
                withAnimation { watchlistStore.remove(contentId: item.contentId) }
            } label: {
                Image(systemName: "bookmark.slash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textDim)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 10)
    }

    private var posterURL: URL? {
        guard !item.posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(item.posterPath)")
    }
}

// MARK: - WatchlistItem → AnyMedia
extension WatchlistItem {
    func toAnyMedia() -> AnyMedia {
        if contentType == ContentItemType.movie.rawValue {
            return .movie(Movie(
                id: contentId, title: title, originalTitle: title, overview: "",
                posterPath: posterPath.isEmpty ? nil : posterPath, backdropPath: nil,
                voteAverage: 0, genreIds: [],
                releaseDate: year.isEmpty ? nil : "\(year)-01-01"
            ))
        } else {
            return .series(Series(
                id: contentId, name: title, originalName: title, overview: "",
                posterPath: posterPath.isEmpty ? nil : posterPath, backdropPath: nil,
                voteAverage: 0, genreIds: [],
                firstAirDate: year.isEmpty ? nil : "\(year)-01-01", numberOfSeasons: nil
            ))
        }
    }
}
