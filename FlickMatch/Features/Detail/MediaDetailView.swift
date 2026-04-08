import SwiftUI
import WebKit

struct MediaDetailView: View {
    let media: AnyMedia

    @State private var fullMedia: AnyMedia?
    @State private var genres: [Genre] = []
    @State private var trailerURL: URL?
    @State private var isLoadingTrailer = true
    @State private var showFullOverview = false
    @EnvironmentObject var ratingStore: RatingStore

    private var displayMedia: AnyMedia { fullMedia ?? media }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Backdrop + Trailer
                    ZStack {
                        AsyncImage(url: displayMedia.backdropURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Rectangle().fill(AppTheme.surface)
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, AppTheme.background],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        if isLoadingTrailer {
                            ProgressView().tint(.white)
                        }
                    }
                    .frame(height: 220)

                    // Poster + Title row
                    HStack(alignment: .top, spacing: 16) {
                        PosterImageView(
                            url: displayMedia.posterURLLarge,
                            width: 120,
                            height: 180
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10)
                        .offset(y: -60)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayMedia.title)
                                .font(AppTheme.english(22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(3)

                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Text("IMDb")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color(hex: "#f5c518"))
                                        .cornerRadius(3)
                                    Text(String(format: "%.1f", displayMedia.voteAverage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                Text("•").foregroundColor(AppTheme.textDim)

                                Text(displayMedia.year)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textDim)
                            }

                            // Genres
                            if !genreNames.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(genreNames, id: \.self) { name in
                                            Text(name)
                                                .font(AppTheme.arabic(11))
                                                .foregroundColor(AppTheme.textDim)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(AppTheme.surface)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }

                            // Your rating
                            if let score = ratingStore.score(contentId: media.id, contentType: media.contentType) {
                                HStack(spacing: 4) {
                                    Text("تقييمك:")
                                        .font(AppTheme.arabic(12))
                                        .foregroundColor(AppTheme.textDim)
                                    Text("\(score)/10")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.gold)
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.gold)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)

                    // Trailer button
                    if let url = trailerURL {
                        TrailerPlayerSection(url: url, title: displayMedia.title)
                            .padding(.horizontal, 20)
                            .padding(.top, -40)
                    }

                    // Overview
                    if !displayMedia.overview.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("القصة")
                                .font(AppTheme.arabic(16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(displayMedia.overview)
                                .font(AppTheme.arabic(14))
                                .foregroundColor(AppTheme.textDim)
                                .lineSpacing(6)
                                .lineLimit(showFullOverview ? nil : 4)

                            if displayMedia.overview.count > 150 {
                                Button {
                                    withAnimation { showFullOverview.toggle() }
                                } label: {
                                    Text(showFullOverview ? "أقل" : "المزيد...")
                                        .font(AppTheme.arabic(13, weight: .semibold))
                                        .foregroundColor(AppTheme.gold)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, -30)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .task { await loadDetails() }
    }

    private var genreNames: [String] {
        let ids: [Int]
        switch displayMedia {
        case .movie(let m): ids = m.genreIds
        case .series(let s): ids = s.genreIds
        }
        return ids.compactMap { id in genres.first(where: { $0.id == id })?.name }
    }

    private func loadDetails() async {
        async let trailerTask: Void = loadTrailer()
        async let genresTask: Void = loadGenres()
        async let detailsTask: Void = loadFullDetails()
        _ = await (trailerTask, genresTask, detailsTask)
    }

    private func loadTrailer() async {
        isLoadingTrailer = true
        do {
            let video: VideoResult?
            switch media {
            case .movie(let m):
                video = try await TMDbService.shared.fetchMovieTrailer(id: m.id)
            case .series(let s):
                video = try await TMDbService.shared.fetchSeriesTrailer(id: s.id)
            }
            trailerURL = video?.youtubeEmbedURL
        } catch {}
        isLoadingTrailer = false
    }

    private func loadGenres() async {
        do {
            genres = media.contentType == .movie
                ? try await TMDbService.shared.fetchMovieGenres()
                : try await TMDbService.shared.fetchSeriesGenres()
        } catch {}
    }

    private func loadFullDetails() async {
        // If overview is empty, fetch full details from TMDb
        guard displayMedia.overview.isEmpty else { return }
        do {
            switch media {
            case .movie(let m):
                let full = try await TMDbService.shared.fetchMovieDetails(id: m.id)
                fullMedia = .movie(full)
            case .series(let s):
                let full = try await TMDbService.shared.fetchSeriesDetails(id: s.id)
                fullMedia = .series(full)
            }
        } catch {}
    }
}

// MARK: - Trailer Player Section
struct TrailerPlayerSection: View {
    let url: URL
    let title: String
    @State private var showPlayer = false

    var body: some View {
        VStack(spacing: 0) {
            if showPlayer {
                YouTubePlayerView(url: url)
                    .frame(height: 220)
                    .cornerRadius(AppTheme.radius)
            } else {
                Button {
                    withAnimation { showPlayer = true }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 44, height: 44)
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("شاهد التريلر")
                                .font(AppTheme.arabic(15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("YouTube")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textDim)
                        }
                        Spacer()
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(AppTheme.accent)
                            .font(.system(size: 24))
                    }
                    .padding(14)
                    .background(AppTheme.card)
                    .cornerRadius(AppTheme.radius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radius)
                            .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - AnyMedia extensions
extension AnyMedia {
    var overview: String {
        switch self {
        case .movie(let m): return m.overview
        case .series(let s): return s.overview
        }
    }

    var backdropURL: URL? {
        let path: String?
        switch self {
        case .movie(let m): path = m.backdropPath
        case .series(let s): path = s.backdropPath
        }
        guard let p = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(p)")
    }

    var posterURLLarge: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}
