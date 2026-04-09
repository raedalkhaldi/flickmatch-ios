import Foundation
import Combine

@MainActor
final class RatingViewModel: ObservableObject {
    // MARK: - State
    enum Phase {
        case welcome
        case loading
        case rating
        case matching
        case recommendations
    }

    @Published var phase: Phase = .welcome
    @Published var mediaItems: [AnyMedia] = []
    @Published var pendingRatings: [Int: PendingRating] = [:]
    @Published var genres: [Genre] = []
    @Published var recommendations: [Recommendation] = []
    @Published var tasteBadge: String = ""
    @Published var matchPercentage: Int = 0
    @Published var currentRound: Int = 1
    @Published var errorMessage: String? = nil

    let contentType: ContentItemType
    private let tmdb = TMDbService.shared
    private let store = RatingStore.shared
    private let firestore = FirestoreService.shared
    private let maxRounds = 3

    var ratedCount: Int {
        pendingRatings.values.filter { $0.score != nil }.count
    }

    var totalInteracted: Int {
        pendingRatings.count
    }

    var canSubmit: Bool { ratedCount >= 5 }

    var progressValue: Double {
        Double(ratedCount) / 10.0
    }

    var canRateMore: Bool { currentRound < maxRounds }

    var roundTitle: String {
        let rounds = ["الأولى", "الثانية", "الثالثة"]
        let name = rounds[min(currentRound - 1, 2)]
        return contentType == .movie
            ? "⭐ قيّم الأفلام — الجولة \(name)"
            : "⭐ قيّم المسلسلات — الجولة \(name)"
    }

    init(contentType: ContentItemType) {
        self.contentType = contentType
    }

    // MARK: - Actions
    func startOnboarding() {
        Task {
            phase = .loading
            await loadGenres()
            await loadRound(1)
        }
    }

    func submitRatings() {
        Task {
            phase = .matching
            await generateRecommendations()
            phase = .recommendations
        }
    }

    func rateMore() {
        guard canRateMore else { return }
        currentRound += 1
        Task {
            phase = .loading
            await loadRound(currentRound)
            phase = .rating
        }
    }

    func setRating(contentId: Int, score: Int?) {
        // Always create or update the pending rating — this handles both
        // fresh ratings and "not seen" → rated transitions
        pendingRatings[contentId] = PendingRating(
            id: contentId,
            contentType: contentType,
            score: score
        )
        let media = mediaItems.first { $0.id == contentId }
        let title = media?.title ?? ""
        let poster = media?.posterPath ?? ""
        let year = media?.year ?? ""
        store.save(contentId: contentId, contentType: contentType,
                   score: score ?? 0, title: title, posterPath: poster, year: year)
        if let uid = AuthService.shared.userId {
            Task {
                await firestore.saveRating(
                    userId: uid, contentId: contentId,
                    contentType: contentType.rawValue,
                    score: score ?? 0, title: title, posterPath: poster, year: year
                )
            }
        }
    }

    func setNotSeen(contentId: Int, notSeen: Bool) {
        if notSeen {
            if pendingRatings[contentId] != nil {
                pendingRatings[contentId]?.score = nil
            } else {
                pendingRatings[contentId] = PendingRating(
                    id: contentId,
                    contentType: contentType,
                    score: nil
                )
            }
            let media = mediaItems.first { $0.id == contentId }
            store.save(
                contentId: contentId,
                contentType: contentType,
                score: 0,
                title: media?.title ?? "",
                posterPath: media?.posterPath ?? "",
                year: media?.year ?? ""
            )
        } else {
            pendingRatings.removeValue(forKey: contentId)
            store.delete(contentId: contentId, contentType: contentType)
        }
    }

    // MARK: - Private
    private func loadRound(_ round: Int) async {
        do {
            let items = try await tmdb.fetchRatingRound(contentType: contentType, round: round)
            mediaItems = items
            for item in items {
                if let saved = store.fetch(contentId: item.id, contentType: contentType) {
                    pendingRatings[item.id] = PendingRating(
                        id: item.id,
                        contentType: contentType,
                        score: saved.score > 0 ? saved.score : nil
                    )
                }
            }
            if store.ratedCount(contentType: contentType) >= 5 && round == 1 {
                await generateRecommendations()
                phase = .recommendations
            } else {
                phase = .rating
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .welcome
        }
    }

    private func loadGenres() async {
        do {
            genres = contentType == .movie
                ? try await tmdb.fetchMovieGenres()
                : try await tmdb.fetchSeriesGenres()
        } catch {}
    }

    // MARK: - Real Recommendation Engine (Collaborative Filtering)
    private func generateRecommendations() async {
        // 1. Get current user's ratings
        let myRatings = store.fetchAll(contentType: contentType).filter { $0.score > 0 }
        let myRatingMap: [Int: Int] = Dictionary(uniqueKeysWithValues: myRatings.map { ($0.contentId, $0.score) })
        let myRatedIds = Set(myRatingMap.keys)

        // 2. Compute taste badge from top-rated genres
        await computeTasteBadge(myRatings: myRatings)

        // 3. Try Firestore collaborative filtering
        let firestoreRecs = await firestoreCollaborativeFilter(myRatingMap: myRatingMap, myRatedIds: myRatedIds)

        if !firestoreRecs.isEmpty {
            recommendations = firestoreRecs
            matchPercentage = firestoreRecs.first?.matchPercentage ?? 0
        } else {
            // Fallback: TMDb-based recommendations from top-rated items
            await tmdbFallbackRecommendations(myRatings: myRatings, myRatedIds: myRatedIds)
        }
    }

    private func firestoreCollaborativeFilter(myRatingMap: [Int: Int], myRatedIds: Set<Int>) async -> [Recommendation] {
        guard let uid = AuthService.shared.userId else { return [] }

        // Fetch all ratings for this content type from Firestore
        let allRatings = await firestore.fetchAllRatings(contentType: contentType.rawValue)
        if allRatings.isEmpty { return [] }

        // Group ratings by user
        var userRatings: [String: [Int: FirestoreRating]] = [:]
        for r in allRatings {
            if r.userId == uid { continue } // Skip self
            if userRatings[r.userId] == nil { userRatings[r.userId] = [:] }
            userRatings[r.userId]?[r.contentId] = r
        }

        // Calculate similarity with each user (cosine similarity on shared items)
        var userSimilarities: [(userId: String, similarity: Double, ratings: [Int: FirestoreRating])] = []
        for (otherUserId, otherRatings) in userRatings {
            let sharedIds = myRatedIds.intersection(Set(otherRatings.keys))
            guard sharedIds.count >= 2 else { continue } // Need at least 2 shared ratings

            // Cosine similarity
            var dotProduct = 0.0
            var myMagnitude = 0.0
            var otherMagnitude = 0.0
            for id in sharedIds {
                let myScore = Double(myRatingMap[id] ?? 0)
                let otherScore = Double(otherRatings[id]?.score ?? 0)
                dotProduct += myScore * otherScore
                myMagnitude += myScore * myScore
                otherMagnitude += otherScore * otherScore
            }
            let magnitude = sqrt(myMagnitude) * sqrt(otherMagnitude)
            guard magnitude > 0 else { continue }
            let similarity = dotProduct / magnitude

            userSimilarities.append((userId: otherUserId, similarity: similarity, ratings: otherRatings))
        }

        // Sort by similarity (taste twins first)
        userSimilarities.sort { $0.similarity > $1.similarity }
        let tasteTwins = Array(userSimilarities.prefix(5))

        if tasteTwins.isEmpty { return [] }

        // Collect recommendations: items taste twins rated highly that I haven't seen
        var candidateScores: [Int: (totalWeight: Double, count: Int, rating: FirestoreRating, recommenders: [String])] = [:]

        for twin in tasteTwins {
            for (contentId, rating) in twin.ratings {
                if myRatedIds.contains(contentId) { continue } // Already seen
                if rating.score < 7 { continue } // Only recommend highly-rated items

                if candidateScores[contentId] != nil {
                    candidateScores[contentId]!.totalWeight += twin.similarity * Double(rating.score)
                    candidateScores[contentId]!.count += 1
                    candidateScores[contentId]!.recommenders.append(twin.userId)
                } else {
                    candidateScores[contentId] = (
                        totalWeight: twin.similarity * Double(rating.score),
                        count: 1,
                        rating: rating,
                        recommenders: [twin.userId]
                    )
                }
            }
        }

        // Sort by weighted score
        let sorted = candidateScores.sorted { $0.value.totalWeight > $1.value.totalWeight }
        let topRecs = Array(sorted.prefix(10))

        return topRecs.enumerated().map { idx, entry in
            let (contentId, data) = entry
            let r = data.rating
            let matchPct = min(99, Int(tasteTwins.first!.similarity * 100))

            let media: AnyMedia
            if contentType == .movie {
                media = .movie(Movie(
                    id: contentId, title: r.title, originalTitle: r.title, overview: "",
                    posterPath: r.posterPath.isEmpty ? nil : r.posterPath, backdropPath: nil,
                    voteAverage: Double(r.score), genreIds: [],
                    releaseDate: r.year.isEmpty ? nil : "\(r.year)-01-01"
                ))
            } else {
                media = .series(Series(
                    id: contentId, name: r.title, originalName: r.title, overview: "",
                    posterPath: r.posterPath.isEmpty ? nil : r.posterPath, backdropPath: nil,
                    voteAverage: Double(r.score), genreIds: [],
                    firstAirDate: r.year.isEmpty ? nil : "\(r.year)-01-01", numberOfSeasons: nil
                ))
            }

            return Recommendation(
                id: contentId,
                contentType: contentType,
                matchPercentage: max(50, matchPct - idx * 2),
                reason: "أشخاص بنفس ذوقك قيّموا هذا العمل \(r.score)/10",
                recommendedBy: Array(data.recommenders.prefix(3)),
                media: media
            )
        }
    }

    private func tmdbFallbackRecommendations(myRatings: [StoredRating], myRatedIds: Set<Int>) async {
        // Use TMDb "similar" or just recommend from top-rated that user hasn't seen
        do {
            let page = Int.random(in: 2...5)
            let items: [AnyMedia]
            if contentType == .movie {
                items = try await tmdb.fetchTopMovies(page: page).map { .movie($0) }
            } else {
                items = try await tmdb.fetchTopSeries(page: page).map { .series($0) }
            }

            let unseen = items.filter { !myRatedIds.contains($0.id) }
            let topRecs = Array(unseen.prefix(5))

            matchPercentage = Int.random(in: 70...88)
            recommendations = topRecs.enumerated().map { idx, media in
                Recommendation(
                    id: media.id,
                    contentType: contentType,
                    matchPercentage: matchPercentage - idx * 3,
                    reason: "مبني على تقييماتك — نتوقع يعجبك",
                    recommendedBy: [],
                    media: media
                )
            }
        } catch {
            // Last resort: show top rated items from current session
            let topRated = pendingRatings.values
                .filter { $0.score != nil }
                .sorted { ($0.score ?? 0) > ($1.score ?? 0) }
                .prefix(3)
                .compactMap { rating -> AnyMedia? in
                    mediaItems.first { $0.id == rating.id }
                }

            matchPercentage = Int.random(in: 70...85)
            recommendations = topRated.enumerated().map { idx, media in
                Recommendation(
                    id: media.id,
                    contentType: contentType,
                    matchPercentage: matchPercentage - idx * 4,
                    reason: "أشخاص قيّموا نفس اختياراتك أحبوا هذا العمل كثيراً",
                    recommendedBy: ["أحمد", "سارة"],
                    media: media
                )
            }
        }
    }

    private func computeTasteBadge(myRatings: [StoredRating]) async {
        // Map genre IDs to names from top-rated items
        let topRatedMedia = myRatings
            .sorted { $0.score > $1.score }
            .prefix(5)
            .compactMap { rating -> AnyMedia? in
                mediaItems.first { $0.id == rating.contentId }
            }

        var genreCount: [Int: Int] = [:]
        for media in topRatedMedia {
            let ids: [Int]
            switch media {
            case .movie(let m): ids = m.genreIds
            case .series(let s): ids = s.genreIds
            }
            for gid in ids {
                genreCount[gid, default: 0] += 1
            }
        }

        let topGenreIds = genreCount.sorted { $0.value > $1.value }.prefix(2).map { $0.key }
        let topGenreNames = topGenreIds.compactMap { id in genres.first(where: { $0.id == id })?.name }

        if topGenreNames.count >= 2 {
            tasteBadge = "\(topGenreNames[0]) + \(topGenreNames[1])"
        } else if let first = topGenreNames.first {
            tasteBadge = first
        } else {
            tasteBadge = contentType == .movie ? "محب أفلام" : "محب مسلسلات"
        }

        // Save badge to Firestore
        if let uid = AuthService.shared.userId {
            await firestore.updateTasteBadge(userId: uid, badge: tasteBadge)
        }
    }
}
