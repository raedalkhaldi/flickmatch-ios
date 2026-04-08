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
    @Published var pendingRatings: [Int: PendingRating] = [:]  // keyed by contentId
    @Published var genres: [Genre] = []
    @Published var recommendations: [Recommendation] = []
    @Published var tasteBadge: String = ""
    @Published var matchPercentage: Int = 0
    @Published var currentRound: Int = 1
    @Published var errorMessage: String? = nil

    let contentType: ContentItemType
    private let tmdb = TMDbService.shared
    private let store = RatingStore.shared
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
            // Simulate matching delay, then show recommendations
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await generateMockRecommendations()
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
        if pendingRatings[contentId] != nil {
            pendingRatings[contentId]?.score = score
        } else {
            pendingRatings[contentId] = PendingRating(
                id: contentId,
                contentType: contentType,
                score: score
            )
        }
        // Persist locally
        let media = mediaItems.first { $0.id == contentId }
        store.save(
            contentId: contentId,
            contentType: contentType,
            score: score ?? 0,
            title: media?.title ?? "",
            posterPath: media?.posterPath ?? "",
            year: media?.year ?? ""
        )
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
            // Persist as "not seen" (score = 0)
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
            // Restore any previously saved ratings
            for item in items {
                if let saved = store.fetch(contentId: item.id, contentType: contentType) {
                    pendingRatings[item.id] = PendingRating(
                        id: item.id,
                        contentType: contentType,
                        score: saved.score > 0 ? saved.score : nil
                    )
                }
            }
            // If already rated enough, skip to recommendations
            if store.ratedCount(contentType: contentType) >= 5 && round == 1 {
                await generateMockRecommendations()
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

    // Temporary: generate mock recommendations until backend is ready
    private func generateMockRecommendations() async {
        tasteBadge = contentType == .movie ? "دراما + إثارة" : "جريمة + خيال علمي"
        matchPercentage = Int.random(in: 78...94)

        let topRated = pendingRatings.values
            .filter { $0.score != nil }
            .sorted { ($0.score ?? 0) > ($1.score ?? 0) }
            .prefix(3)
            .compactMap { rating -> AnyMedia? in
                mediaItems.first { $0.id == rating.id }
            }

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
