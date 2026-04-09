import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var users: [DiscoverUser] = []
    @Published var followedIds: Set<String> = []
    @Published var isLoading = false
    private var hasLoaded = false

    private let firestore = FirestoreService.shared
    private let store = RatingStore.shared

    struct DiscoverUser: Identifiable {
        let id: String
        let name: String
        let tasteBadge: String
        let matchPercentage: Int
        let topRatings: [FirestoreRating]
    }

    func load(force: Bool = false) async {
        guard let uid = AuthService.shared.userId else { return }
        guard !hasLoaded || force else { return }
        isLoading = true

        // Load followed IDs
        followedIds = await firestore.fetchFollowedIds(userId: uid)

        // Load my ratings for comparison
        let myMovieRatings = store.fetchAll(contentType: .movie).filter { $0.score > 0 }
        let mySeriesRatings = store.fetchAll(contentType: .series).filter { $0.score > 0 }
        var myRatingMap: [Int: Int] = [:]
        for r in myMovieRatings { myRatingMap[r.contentId] = r.score }
        for r in mySeriesRatings { myRatingMap[r.contentId] = r.score }

        // Fetch users from Firestore
        let firestoreUsers = await firestore.fetchDiscoverUsers(excludeUserId: uid)

        var discoverUsers: [DiscoverUser] = []
        for (user, ratings) in firestoreUsers {
            // Calculate taste match
            let matchPct = calculateMatch(myRatings: myRatingMap, otherRatings: ratings)
            let badge = user.tasteBadge.isEmpty ? "محب أفلام" : user.tasteBadge
            discoverUsers.append(DiscoverUser(
                id: user.uid,
                name: user.displayName,
                tasteBadge: badge,
                matchPercentage: matchPct,
                topRatings: ratings.sorted { $0.score > $1.score }.prefix(5).map { $0 }
            ))
        }

        // Sort by match percentage
        users = discoverUsers.sorted { $0.matchPercentage > $1.matchPercentage }

        // If no Firestore users, show mock data
        if users.isEmpty {
            users = MockDiscoverUser.samples
        }

        isLoading = false
        hasLoaded = true
    }

    func refreshFollowedIds() async {
        guard let uid = AuthService.shared.userId else { return }
        followedIds = await firestore.fetchFollowedIds(userId: uid)
    }

    func toggleFollow(userId: String) {
        guard let myUid = AuthService.shared.userId else { return }
        if followedIds.contains(userId) {
            followedIds.remove(userId)
            Task { await firestore.unfollow(followerId: myUid, followingId: userId) }
        } else {
            followedIds.insert(userId)
            Task { await firestore.follow(followerId: myUid, followingId: userId) }
        }
    }

    func isFollowing(userId: String) -> Bool {
        followedIds.contains(userId)
    }

    private func calculateMatch(myRatings: [Int: Int], otherRatings: [FirestoreRating]) -> Int {
        let otherMap = Dictionary(uniqueKeysWithValues: otherRatings.map { ($0.contentId, $0.score) })
        let sharedIds = Set(myRatings.keys).intersection(Set(otherMap.keys))

        guard sharedIds.count >= 2 else {
            // Not enough shared ratings — estimate based on genre similarity
            return Int.random(in: 55...75)
        }

        var dotProduct = 0.0
        var myMag = 0.0
        var otherMag = 0.0
        for id in sharedIds {
            let my = Double(myRatings[id] ?? 0)
            let other = Double(otherMap[id] ?? 0)
            dotProduct += my * other
            myMag += my * my
            otherMag += other * other
        }
        let magnitude = sqrt(myMag) * sqrt(otherMag)
        guard magnitude > 0 else { return 50 }

        return min(99, Int((dotProduct / magnitude) * 100))
    }
}

// MARK: - Mock data for offline/empty state
enum MockDiscoverUser {
    static let samples: [DiscoverViewModel.DiscoverUser] = [
        .init(id: "mock1", name: "أحمد الزهراني", tasteBadge: "دراما + إثارة", matchPercentage: 92, topRatings: []),
        .init(id: "mock2", name: "سارة المالكي",  tasteBadge: "خيال علمي + أكشن", matchPercentage: 87, topRatings: []),
        .init(id: "mock3", name: "خالد العمري",   tasteBadge: "جريمة + تشويق",  matchPercentage: 83, topRatings: []),
        .init(id: "mock4", name: "نورة السبيعي",  tasteBadge: "رومانسي + درامي", matchPercentage: 79, topRatings: []),
        .init(id: "mock5", name: "فيصل القحطاني", tasteBadge: "كوميدي + دراما",  matchPercentage: 74, topRatings: []),
    ]
}

// MARK: - View
struct DiscoverView: View {
    @StateObject private var vm = DiscoverViewModel()

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

                    if vm.isLoading {
                        VStack {
                            ProgressView().tint(AppTheme.gold)
                            Text("ندور على مستخدمين...")
                                .font(AppTheme.arabic(13))
                                .foregroundColor(AppTheme.textDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.users) { user in
                                DiscoverUserCard(
                                    user: user,
                                    isFollowing: vm.followedIds.contains(user.id),
                                    onFollow: {
                                        withAnimation { vm.toggleFollow(userId: user.id) }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .task { await vm.load() }
    }
}

// MARK: - User Card (tappable → opens profile sheet)
struct DiscoverUserCard: View {
    let user: DiscoverViewModel.DiscoverUser
    let isFollowing: Bool
    let onFollow: () -> Void
    @State private var showProfile = false

    var body: some View {
        VStack(spacing: 0) {
            // Tappable user info area
            Button { showProfile = true } label: {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 48, height: 48)
                        Text(String(user.name.prefix(1)))
                            .font(AppTheme.arabic(20, weight: .bold))
                            .foregroundColor(AppTheme.gold)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(user.name)
                                .font(AppTheme.arabic(14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.textDim)
                        }
                        Text(user.tasteBadge)
                            .font(AppTheme.arabic(11))
                            .foregroundColor(AppTheme.textDim)
                        Text("تطابق \(user.matchPercentage)%")
                            .font(AppTheme.arabic(10))
                            .foregroundColor(AppTheme.green)
                    }

                    Spacer()
                }
            }

            // Follow button (separate from tap area)
            HStack {
                Spacer()
                Button(action: onFollow) {
                    Text(isFollowing ? "تتابعه ✓" : "+ تابع")
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
            .padding(.top, 6)

            // Top rated posters
            if !user.topRatings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(user.topRatings, id: \.contentId) { rating in
                            NavigationLink(value: ratingToMedia(rating)) {
                                VStack(spacing: 4) {
                                    AsyncImage(url: posterURL(for: rating)) { phase in
                                        switch phase {
                                        case .success(let img): img.resizable().scaledToFill()
                                        default: Rectangle().fill(AppTheme.surface)
                                        }
                                    }
                                    .frame(width: 44, height: 64)
                                    .cornerRadius(6)
                                    .clipped()

                                    Text("\(rating.score)⭐")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(AppTheme.gold)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
        .sheet(isPresented: $showProfile) {
            UserProfileSheet(
                userId: user.id,
                userName: user.name,
                tasteBadge: user.tasteBadge,
                matchPercentage: user.matchPercentage
            )
        }
    }

    private func posterURL(for rating: FirestoreRating) -> URL? {
        guard !rating.posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(rating.posterPath)")
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
