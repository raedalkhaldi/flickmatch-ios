import Foundation

struct Movie: MediaItem {
    let id: Int
    let title: String
    let originalTitle: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let genreIds: [Int]
    let releaseDate: String?

    var contentType: ContentItemType { .movie }

    var year: String {
        String(releaseDate?.prefix(4) ?? "")
    }

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle  = "original_title"
        case posterPath     = "poster_path"
        case backdropPath   = "backdrop_path"
        case voteAverage    = "vote_average"
        case genreIds       = "genre_ids"
        case releaseDate    = "release_date"
    }
}

// MARK: - TMDb Response
struct MovieResponse: Codable {
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}
