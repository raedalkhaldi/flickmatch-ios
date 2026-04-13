import Foundation
// Note: Using SwiftUI AsyncImage for image loading (no external dependency needed)

final class TMDbService {
    static let shared = TMDbService()
    private init() {}

    private let client = APIClient.shared

    // MARK: - Movies
    func fetchTopMovies(page: Int = 1, withGenre: Int? = nil, withoutGenre: Int? = nil) async throws -> [Movie] {
        let response: MovieResponse = try await client.fetch(TMDbEndpoint.topMovies(page: page, withGenre: withGenre, withoutGenre: withoutGenre))
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
    func fetchTopSeries(page: Int = 1, withGenre: Int? = nil, withoutGenre: Int? = nil) async throws -> [Series] {
        let response: SeriesResponse = try await client.fetch(TMDbEndpoint.topSeries(page: page, withGenre: withGenre, withoutGenre: withoutGenre))
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

    // MARK: - Age / Content Rating
    /// Returns the best available age rating for SA, falling back to US then any non-empty rating.
    func fetchAgeRating(id: Int, contentType: ContentItemType) async throws -> String? {
        switch contentType {
        case .movie:
            let response: ReleaseDatesResponse = try await client.fetch(TMDbEndpoint.movieReleaseDates(id: id))
            return pickMovieCertification(from: response.results)
        case .series:
            let response: ContentRatingsResponse = try await client.fetch(TMDbEndpoint.seriesContentRatings(id: id))
            return pickSeriesRating(from: response.results)
        }
    }

    private func pickMovieCertification(from countries: [ReleaseDatesCountry]) -> String? {
        let preferred = ["SA", "AE", "US", "GB"]
        for code in preferred {
            if let country = countries.first(where: { $0.iso3166_1 == code }),
               let cert = country.releaseDates.first(where: { !$0.certification.isEmpty })?.certification {
                return cert
            }
        }
        // Any country with a non-empty certification
        for country in countries {
            if let cert = country.releaseDates.first(where: { !$0.certification.isEmpty })?.certification {
                return cert
            }
        }
        return nil
    }

    private func pickSeriesRating(from entries: [ContentRatingEntry]) -> String? {
        let preferred = ["SA", "AE", "US", "GB"]
        for code in preferred {
            if let entry = entries.first(where: { $0.iso3166_1 == code && !$0.rating.isEmpty }) {
                return entry.rating
            }
        }
        return entries.first(where: { !$0.rating.isEmpty })?.rating
    }

    // MARK: - Watch Providers (Saudi Arabia)
    func fetchWatchProviders(id: Int, contentType: ContentItemType) async throws -> WatchProviderCountry? {
        let endpoint: TMDbEndpoint = contentType == .movie
            ? .movieWatchProviders(id: id)
            : .seriesWatchProviders(id: id)
        let response: WatchProvidersResponse = try await client.fetch(endpoint)
        return response.results?["SA"] // Saudi Arabia
    }

    // MARK: - Rating Rounds
    // Returns 10 items per round (page-based)
    func fetchRatingRound(contentType: ContentItemType, round: Int, withGenre: Int? = nil, withoutGenre: Int? = nil) async throws -> [AnyMedia] {
        let page = round
        switch contentType {
        case .movie:
            let movies = try await fetchTopMovies(page: page, withGenre: withGenre, withoutGenre: withoutGenre)
            return Array(movies.prefix(10)).map { .movie($0) }
        case .series:
            let series = try await fetchTopSeries(page: page, withGenre: withGenre, withoutGenre: withoutGenre)
            return Array(series.prefix(10)).map { .series($0) }
        }
    }
}
