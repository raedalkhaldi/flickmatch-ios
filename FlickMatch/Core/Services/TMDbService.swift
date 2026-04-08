import Foundation
// Note: Using SwiftUI AsyncImage for image loading (no external dependency needed)

final class TMDbService {
    static let shared = TMDbService()
    private init() {}

    private let client = APIClient.shared

    // MARK: - Movies
    func fetchTopMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponse = try await client.fetch(TMDbEndpoint.topMovies(page: page))
        return response.results
    }

    func fetchMovieDetails(id: Int) async throws -> Movie {
        return try await client.fetch(TMDbEndpoint.movieDetails(id: id))
    }

    func fetchMovieTrailer(id: Int) async throws -> VideoResult? {
        let response: VideoResponse = try await client.fetch(TMDbEndpoint.movieTrailers(id: id))
        return bestVideo(from: response.results)
    }

    // MARK: - Series
    func fetchTopSeries(page: Int = 1) async throws -> [Series] {
        let response: SeriesResponse = try await client.fetch(TMDbEndpoint.topSeries(page: page))
        return response.results
    }

    func fetchSeriesDetails(id: Int) async throws -> Series {
        return try await client.fetch(TMDbEndpoint.seriesDetails(id: id))
    }

    func fetchSeriesTrailer(id: Int) async throws -> VideoResult? {
        let response: VideoResponse = try await client.fetch(TMDbEndpoint.seriesTrailers(id: id))
        return bestVideo(from: response.results)
    }

    /// Pick the best video: official trailer > trailer > teaser > clip > any YouTube
    private func bestVideo(from results: [VideoResult]) -> VideoResult? {
        let yt = results.filter { $0.site == "YouTube" }
        return yt.first(where: { $0.type == "Trailer" && $0.official })
            ?? yt.first(where: { $0.type == "Trailer" })
            ?? yt.first(where: { $0.type == "Teaser" })
            ?? yt.first(where: { $0.type == "Clip" })
            ?? yt.first
    }

    // MARK: - Genres
    func fetchMovieGenres() async throws -> [Genre] {
        let response: GenreResponse = try await client.fetch(TMDbEndpoint.movieGenres)
        return response.genres
    }

    func fetchSeriesGenres() async throws -> [Genre] {
        let response: GenreResponse = try await client.fetch(TMDbEndpoint.seriesGenres)
        return response.genres
    }

    // MARK: - Search
    func searchMovies(query: String) async throws -> [Movie] {
        let response: MovieResponse = try await client.fetch(TMDbEndpoint.searchMovies(query: query))
        return response.results
    }

    func searchSeries(query: String) async throws -> [Series] {
        let response: SeriesResponse = try await client.fetch(TMDbEndpoint.searchSeries(query: query))
        return response.results
    }

    // MARK: - Rating Rounds
    // Returns 10 items per round (page-based)
    func fetchRatingRound(contentType: ContentItemType, round: Int) async throws -> [AnyMedia] {
        let page = round
        switch contentType {
        case .movie:
            let movies = try await fetchTopMovies(page: page)
            return Array(movies.prefix(10)).map { .movie($0) }
        case .series:
            let series = try await fetchTopSeries(page: page)
            return Array(series.prefix(10)).map { .series($0) }
        }
    }
}
