import Foundation

// UserDefaults-based persistence — works on iOS 16+
// Will migrate to Firestore once Firebase is set up

struct StoredRating: Codable {
    let contentId: Int
    let contentType: String
    var score: Int          // 0 = haven't seen
    var title: String
    var posterPath: String
    var year: String
    var updatedAt: Date
}

@MainActor
final class RatingStore: ObservableObject {
    static let shared = RatingStore()

    private let defaults = UserDefaults.standard
    private let moviesKey = "flickmatch_ratings_movie"
    private let seriesKey = "flickmatch_ratings_series"

    private func key(for contentType: ContentItemType) -> String {
        contentType == .movie ? moviesKey : seriesKey
    }

    // MARK: - Read
    private func loadAll(contentType: ContentItemType) -> [Int: StoredRating] {
        guard let data = defaults.data(forKey: key(for: contentType)),
              let decoded = try? JSONDecoder().decode([Int: StoredRating].self, from: data)
        else { return [:] }
        return decoded
    }

    func fetch(contentId: Int, contentType: ContentItemType) -> StoredRating? {
        loadAll(contentType: contentType)[contentId]
    }

    func fetchAll(contentType: ContentItemType) -> [StoredRating] {
        Array(loadAll(contentType: contentType).values)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func ratedCount(contentType: ContentItemType) -> Int {
        fetchAll(contentType: contentType).filter { $0.score > 0 }.count
    }

    func score(contentId: Int, contentType: ContentItemType) -> Int? {
        guard let r = fetch(contentId: contentId, contentType: contentType), r.score > 0 else { return nil }
        return r.score
    }

    func hasNotSeen(contentId: Int, contentType: ContentItemType) -> Bool {
        fetch(contentId: contentId, contentType: contentType)?.score == 0
    }

    // MARK: - Write
    func save(contentId: Int, contentType: ContentItemType, score: Int,
              title: String, posterPath: String, year: String) {
        var all = loadAll(contentType: contentType)
        all[contentId] = StoredRating(
            contentId: contentId,
            contentType: contentType.rawValue,
            score: score,
            title: title,
            posterPath: posterPath,
            year: year,
            updatedAt: Date()
        )
        persist(all, contentType: contentType)
        objectWillChange.send()
    }

    func delete(contentId: Int, contentType: ContentItemType) {
        var all = loadAll(contentType: contentType)
        all.removeValue(forKey: contentId)
        persist(all, contentType: contentType)
        objectWillChange.send()
    }

    private func persist(_ ratings: [Int: StoredRating], contentType: ContentItemType) {
        if let data = try? JSONEncoder().encode(ratings) {
            defaults.set(data, forKey: key(for: contentType))
        }
    }
}
