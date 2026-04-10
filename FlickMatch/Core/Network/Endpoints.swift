import Foundation

// MARK: - Endpoint Protocol
protocol Endpoint {
    var url: URL? { get }
    var method: String { get }
    var headers: [String: String] { get }
}

// MARK: - TMDb Endpoints
enum TMDbEndpoint: Endpoint {
    case topMovies(page: Int)
    case topSeries(page: Int)
    case movieDetails(id: Int)
    case seriesDetails(id: Int)
    case movieTrailers(id: Int)
    case seriesTrailers(id: Int)
    case movieGenres
    case seriesGenres
    case searchMovies(query: String)
    case searchSeries(query: String)
    case movieWatchProviders(id: Int)
    case seriesWatchProviders(id: Int)
    case movieReleaseDates(id: Int)
    case seriesContentRatings(id: Int)

    private static let baseURL = "https://api.themoviedb.org/3"
    private static let readToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI3NjU4NzZmZmUyMzg0ZmZhOWM2ZDM1MWFjOWY2NmEyOSIsIm5iZiI6MTc3NTU5NDQwOS40NTIsInN1YiI6IjY5ZDU2YmE5OGFmMDRmNDBhOGNhODY2YiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ._szy4icDEutyskYvrIZw8690aWrraJxrvmi0zs8e6f4"

    var url: URL? {
        var components = URLComponents(string: TMDbEndpoint.baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }

    var method: String { "GET" }

    var headers: [String: String] {
        [
            "Authorization": "Bearer \(TMDbEndpoint.readToken)",
            "accept": "application/json"
        ]
    }

    private var path: String {
        switch self {
        case .topMovies:              return "/movie/top_rated"
        case .topSeries:              return "/tv/top_rated"
        case .movieDetails(let id):   return "/movie/\(id)"
        case .seriesDetails(let id):  return "/tv/\(id)"
        case .movieTrailers(let id):  return "/movie/\(id)/videos"
        case .seriesTrailers(let id): return "/tv/\(id)/videos"
        case .movieGenres:            return "/genre/movie/list"
        case .seriesGenres:           return "/genre/tv/list"
        case .searchMovies:                  return "/search/movie"
        case .searchSeries:                  return "/search/tv"
        case .movieWatchProviders(let id):   return "/movie/\(id)/watch/providers"
        case .seriesWatchProviders(let id):  return "/tv/\(id)/watch/providers"
        case .movieReleaseDates(let id):     return "/movie/\(id)/release_dates"
        case .seriesContentRatings(let id):  return "/tv/\(id)/content_ratings"
        }
    }

    private var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        // Videos: don't filter by language (most trailers are English)
        // Other endpoints: use Arabic
        switch self {
        case .movieTrailers, .seriesTrailers, .movieWatchProviders, .seriesWatchProviders,
             .movieReleaseDates, .seriesContentRatings:
            break // no language filter for videos/providers/ratings
        default:
            items.append(URLQueryItem(name: "language", value: "ar-SA"))
        }
        switch self {
        case .topMovies(let page), .topSeries(let page):
            items.append(URLQueryItem(name: "page", value: "\(page)"))
        case .searchMovies(let q), .searchSeries(let q):
            items.append(URLQueryItem(name: "query", value: q))
        default:
            break
        }
        return items
    }
}

// MARK: - Video Response
struct VideoResponse: Codable {
    let results: [VideoResult]
}

// MARK: - Watch Providers Response
struct WatchProvidersResponse: Codable {
    let results: [String: WatchProviderCountry]?
}

struct WatchProviderCountry: Codable {
    let link: String?
    let flatrate: [WatchProvider]?  // Subscription (Netflix, etc.)
    let rent: [WatchProvider]?
    let buy: [WatchProvider]?
}

struct WatchProvider: Codable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String?
    let displayPriority: Int?

    var id: Int { providerId }

    var logoURL: URL? {
        guard let path = logoPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w92\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }
}

// MARK: - Age / Content Rating Responses

/// Movies — /movie/{id}/release_dates
struct ReleaseDatesResponse: Codable {
    let results: [ReleaseDatesCountry]
}

struct ReleaseDatesCountry: Codable {
    let iso3166_1: String
    let releaseDates: [ReleaseDateEntry]

    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case releaseDates = "release_dates"
    }
}

struct ReleaseDateEntry: Codable {
    let certification: String
    let type: Int?
}

/// Series — /tv/{id}/content_ratings
struct ContentRatingsResponse: Codable {
    let results: [ContentRatingEntry]
}

struct ContentRatingEntry: Codable {
    let iso3166_1: String
    let rating: String

    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case rating
    }
}

struct VideoResult: Codable {
    let key: String
    let site: String
    let type: String
    let official: Bool

    var isYouTubeTrailer: Bool {
        site == "YouTube" && type == "Trailer"
    }

    var youtubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(key)")
    }

    var youtubeEmbedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(key)?autoplay=1")
    }
}
