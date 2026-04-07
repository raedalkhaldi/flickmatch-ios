import Foundation

struct Recommendation: Identifiable {
    let id: Int              // contentId
    let contentType: ContentItemType
    let matchPercentage: Int
    let reason: String
    let recommendedBy: [String] // display names of taste twins
    let media: AnyMedia
}

// MARK: - Type-erased wrapper for Movie/Series
enum AnyMedia: Identifiable {
    case movie(Movie)
    case series(Series)

    var id: Int {
        switch self {
        case .movie(let m):  return m.id
        case .series(let s): return s.id
        }
    }

    var title: String {
        switch self {
        case .movie(let m):  return m.title
        case .series(let s): return s.title
        }
    }

    var posterPath: String? {
        switch self {
        case .movie(let m):  return m.posterPath
        case .series(let s): return s.posterPath
        }
    }

    var voteAverage: Double {
        switch self {
        case .movie(let m):  return m.voteAverage
        case .series(let s): return s.voteAverage
        }
    }

    var year: String {
        switch self {
        case .movie(let m):  return m.year
        case .series(let s): return s.year
        }
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    var contentType: ContentItemType {
        switch self {
        case .movie:  return .movie
        case .series: return .series
        }
    }
}

// MARK: - Genre
struct Genre: Identifiable, Codable {
    let id: Int
    let name: String
}

struct GenreResponse: Codable {
    let genres: [Genre]
}
