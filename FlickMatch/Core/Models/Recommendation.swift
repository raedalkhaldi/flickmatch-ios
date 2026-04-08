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
enum AnyMedia: Identifiable, Hashable {
    case movie(Movie)
    case series(Series)

    static func == (lhs: AnyMedia, rhs: AnyMedia) -> Bool {
        lhs.id == rhs.id && lhs.contentType == rhs.contentType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(contentType)
    }

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

    var originalTitle: String {
        switch self {
        case .movie(let m):  return m.originalTitle
        case .series(let s): return s.originalName
        }
    }

    /// Arabic title if different from original, otherwise empty
    var localizedTitle: String {
        let t = title
        let o = originalTitle
        // If TMDb returned Arabic, title != originalTitle
        return t != o ? t : ""
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

// MARK: - StoredRating → AnyMedia
extension StoredRating {
    func toAnyMedia() -> AnyMedia {
        if contentType == ContentItemType.movie.rawValue {
            return .movie(Movie(
                id: contentId, title: title, originalTitle: title, overview: "",
                posterPath: posterPath.isEmpty ? nil : posterPath, backdropPath: nil,
                voteAverage: Double(score), genreIds: [],
                releaseDate: year.isEmpty ? nil : "\(year)-01-01"
            ))
        } else {
            return .series(Series(
                id: contentId, name: title, originalName: title, overview: "",
                posterPath: posterPath.isEmpty ? nil : posterPath, backdropPath: nil,
                voteAverage: Double(score), genreIds: [],
                firstAirDate: year.isEmpty ? nil : "\(year)-01-01", numberOfSeasons: nil
            ))
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
