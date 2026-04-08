import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [AnyMedia] = []
    @Published var isLoading = false
    @Published var hasSearched = false

    private let tmdb = TMDbService.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            hasSearched = false
            return
        }
        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            hasSearched = true
            do {
                async let movies = tmdb.searchMovies(query: query)
                async let series = tmdb.searchSeries(query: query)
                let (m, s) = try await (movies, series)
                if !Task.isCancelled {
                    results = (m.map { .movie($0) } + s.map { .series($0) })
                        .sorted { $0.voteAverage > $1.voteAverage }
                }
            } catch {}
            isLoading = false
        }
    }

    func clear() {
        query = ""
        results = []
        hasSearched = false
        searchTask?.cancel()
    }
}

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 15))
                        TextField("", text: $vm.query, prompt:
                            Text("ابحث عن فيلم أو مسلسل...")
                                .foregroundColor(AppTheme.textDim)
                                .font(AppTheme.arabic(14))
                        )
                        .font(AppTheme.arabic(14))
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($focused)
                        .submitLabel(.search)
                        .onSubmit { vm.search() }
                        .onChange(of: vm.query) { _ in
                            if vm.query.count >= 3 { vm.search() }
                            if vm.query.isEmpty { vm.clear() }
                        }

                        if !vm.query.isEmpty {
                            Button { vm.clear() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textDim)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if vm.isLoading {
                    Spacer()
                    ProgressView().tint(AppTheme.gold)
                    Spacer()
                } else if !vm.hasSearched {
                    SearchEmptyState()
                } else if vm.results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🔍")
                            .font(.system(size: 48))
                        Text("ما لقينا نتائج لـ \"\(vm.query)\"")
                            .font(AppTheme.arabic(15))
                            .foregroundColor(AppTheme.textDim)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.results) { media in
                                NavigationLink(value: media) {
                                    SearchResultRow(media: media)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - Empty State with trending posters
struct SearchEmptyState: View {
    @State private var trendingMovies: [AnyMedia] = []
    @State private var trendingSeries: [AnyMedia] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Movies section
                if !trendingMovies.isEmpty {
                    Text("🎬 أفلام رائجة")
                        .font(AppTheme.arabic(16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trendingMovies) { media in
                                NavigationLink(value: media) {
                                    SuggestionPosterCard(media: media)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Series section
                if !trendingSeries.isEmpty {
                    Text("📺 مسلسلات رائجة")
                        .font(AppTheme.arabic(16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trendingSeries) { media in
                                NavigationLink(value: media) {
                                    SuggestionPosterCard(media: media)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(AppTheme.gold)
                        Spacer()
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .task { await loadTrending() }
    }

    private func loadTrending() async {
        do {
            async let movies = TMDbService.shared.fetchTopMovies(page: 1)
            async let series = TMDbService.shared.fetchTopSeries(page: 1)
            let (m, s) = try await (movies, series)
            trendingMovies = m.prefix(10).map { .movie($0) }
            trendingSeries = s.prefix(10).map { .series($0) }
        } catch {}
        isLoading = false
    }
}

// MARK: - Suggestion Poster Card
struct SuggestionPosterCard: View {
    let media: AnyMedia

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: media.posterURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Rectangle().fill(AppTheme.surface)
                        .overlay(Image(systemName: "film").foregroundColor(AppTheme.textDim))
                }
            }
            .frame(width: 100, height: 150)
            .cornerRadius(10)
            .clipped()

            VStack(spacing: 2) {
                Text(media.originalTitle)
                    .font(AppTheme.english(11, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                if !media.localizedTitle.isEmpty {
                    Text(media.localizedTitle)
                        .font(AppTheme.arabic(10))
                        .foregroundColor(AppTheme.textDim)
                        .lineLimit(1)
                }
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "#f5c518"))
                    Text(String(format: "%.1f", media.voteAverage))
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textDim)
                }
            }
            .frame(width: 100)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let media: AnyMedia

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: media.posterURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default:
                    Rectangle().fill(AppTheme.surface)
                        .overlay(Image(systemName: "film").foregroundColor(AppTheme.textDim))
                }
            }
            .frame(width: 50, height: 72)
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(media.originalTitle)
                    .font(AppTheme.english(14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                if !media.localizedTitle.isEmpty {
                    Text(media.localizedTitle)
                        .font(AppTheme.arabic(12))
                        .foregroundColor(AppTheme.textDim)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(media.contentType == .movie ? "فيلم" : "مسلسل")
                        .font(AppTheme.arabic(11))
                        .foregroundColor(AppTheme.textDim)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppTheme.surface)
                        .cornerRadius(6)
                    Text(media.year)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDim)
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#f5c518"))
                        Text(String(format: "%.1f", media.voteAverage))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textDim)
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
    }
}
