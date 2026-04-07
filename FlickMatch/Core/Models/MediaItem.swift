import Foundation

// MARK: - Shared Media Protocol
protocol MediaItem: Identifiable, Codable {
    var id: Int { get }
    var title: String { get }
    var originalTitle: String { get }
    var overview: String { get }
    var posterPath: String? { get }
    var backdropPath: String? { get }
    var voteAverage: Double { get }
    var genreIds: [Int] { get }
    var contentType: ContentItemType { get }
}

enum ContentItemType: String, Codable {
    case movie  = "movie"
    case series = "series"
}

// MARK: - TMDb Image URLs
extension MediaItem {
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    var posterURLLarge: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var imdbRating: String {
        String(format: "%.1f", voteAverage)
    }
}
