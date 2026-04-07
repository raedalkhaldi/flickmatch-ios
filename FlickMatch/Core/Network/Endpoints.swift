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
        case .searchMovies:           return "/search/movie"
        case .searchSeries:           return "/search/tv"
        }
    }

    private var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "ar-SA")
        ]
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
