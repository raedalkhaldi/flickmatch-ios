import Foundation

struct AppUser: Identifiable, Codable {
    let id: String
    var displayName: String
    var handle: String
    var email: String?
    var avatarURL: String?
    var tasteBadge: String?
    var followersCount: Int
    var followingCount: Int
    var moviesRatedCount: Int
    var seriesRatedCount: Int
    let createdAt: Date

    var matchPercentage: Int? // Populated when viewing other users
}

struct UserProfile: Identifiable, Codable {
    let user: AppUser
    let topMovies: [RankedMedia]
    let topSeries: [RankedMedia]
    var isFollowing: Bool
}

struct RankedMedia: Identifiable, Codable {
    let id: Int
    let rank: Int
    let title: String
    let posterPath: String?
    let year: String
    let genreNames: [String]
    let userRating: Int
    let contentType: ContentItemType

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }
}
