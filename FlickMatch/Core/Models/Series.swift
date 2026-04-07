import Foundation

struct Series: MediaItem {
    let id: Int
    let name: String
    let originalName: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let genreIds: [Int]
    let firstAirDate: String?
    let numberOfSeasons: Int?

    var contentType: ContentItemType { .series }

    var title: String { name }
    var originalTitle: String { originalName }

    var year: String {
        String(firstAirDate?.prefix(4) ?? "")
    }

    var seasonsText: String? {
        guard let n = numberOfSeasons else { return nil }
        return "\(n) مواسم"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case originalName    = "original_name"
        case posterPath      = "poster_path"
        case backdropPath    = "backdrop_path"
        case voteAverage     = "vote_average"
        case genreIds        = "genre_ids"
        case firstAirDate    = "first_air_date"
        case numberOfSeasons = "number_of_seasons"
    }
}

struct SeriesResponse: Codable {
    let results: [Series]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}
