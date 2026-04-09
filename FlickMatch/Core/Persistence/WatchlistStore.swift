import Foundation

struct WatchlistItem: Codable, Identifiable {
    let contentId: Int
    let contentType: String
    let title: String
    let posterPath: String
    let year: String
    let addedAt: Date

    var id: Int { contentId }
}

@MainActor
final class WatchlistStore: ObservableObject {
    static let shared = WatchlistStore()

    private let defaults = UserDefaults.standard
    private let storageKey = "flickmatch_watchlist"

    // MARK: - Read
    private func loadAll() -> [Int: WatchlistItem] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Int: WatchlistItem].self, from: data)
        else { return [:] }
        return decoded
    }

    func fetchAll() -> [WatchlistItem] {
        Array(loadAll().values).sorted { $0.addedAt > $1.addedAt }
    }

    func isInWatchlist(contentId: Int) -> Bool {
        loadAll()[contentId] != nil
    }

    var count: Int {
        loadAll().count
    }

    // MARK: - Write
    func toggle(contentId: Int, contentType: ContentItemType,
                title: String, posterPath: String, year: String) {
        var all = loadAll()
        if all[contentId] != nil {
            all.removeValue(forKey: contentId)
        } else {
            all[contentId] = WatchlistItem(
                contentId: contentId,
                contentType: contentType.rawValue,
                title: title,
                posterPath: posterPath,
                year: year,
                addedAt: Date()
            )
        }
        persist(all)
        objectWillChange.send()
    }

    func remove(contentId: Int) {
        var all = loadAll()
        all.removeValue(forKey: contentId)
        persist(all)
        objectWillChange.send()
    }

    private func persist(_ items: [Int: WatchlistItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
