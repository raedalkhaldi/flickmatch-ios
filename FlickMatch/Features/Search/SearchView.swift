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

// MARK: - Empty State with trending content (tabs + infinite scroll)
struct SearchEmptyState: View {
    enum SuggestionTab { case movies, series }
    @State private var selectedTab: SuggestionTab = .movies
    @State private var movies: [AnyMedia] = []
    @State private var series: [AnyMedia] = []
    @State private var moviePage = 1
    @State private var seriesPage = 1
    @State private var isLoadingMore = false
    @State private var isInitialLoad = true

    private var currentItems: [AnyMedia] {
        selectedTab == .movies ? movies : series
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            HStack(spacing: 0) {
                SuggestionTabButton(title: "🎬 أفلام", isSelected: selectedTab == .movies) {
                    selectedTab = .movies
                }
                SuggestionTabButton(title: "📺 مسلسلات", isSelected: selectedTab == .series) {
                    selectedTab = .series
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if isInitialLoad {
                Spacer()
                ProgressView().tint(AppTheme.gold)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    let columns = [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ]
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(currentItems) { media in
                            NavigationLink(value: media) {
                                SuggestionPosterCard(media: media)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    // Load more trigger
                    if !currentItems.isEmpty {
                        if isLoadingMore {
                            ProgressView().tint(AppTheme.gold)
                                .padding(.vertical, 16)
                        } else {
                            Color.clear
                                .frame(height: 1)
                                .onAppear { Task { await loadMore() } }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .task { await loadInitial() }
    }

    private func loadInitial() async {
        do {
            async let m = TMDbService.shared.fetchTopMovies(page: 1)
            async let s = TMDbService.shared.fetchTopSeries(page: 1)
            let (moviesResult, seriesResult) = try await (m, s)
            movies = moviesResult.map { .movie($0) }
            series = seriesResult.map { .series($0) }
        } catch {}
        isInitialLoad = false
    }

    private func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        do {
            if selectedTab == .movies {
                moviePage += 1
                let more = try await TMDbService.shared.fetchTopMovies(page: moviePage)
                movies.append(contentsOf: more.map { .movie($0) })
            } else {
                seriesPage += 1
                let more = try await TMDbService.shared.fetchTopSeries(page: seriesPage)
                series.append(contentsOf: more.map { .series($0) })
            }
        } catch {}
        isLoadingMore = false
    }
}

// MARK: - Suggestion Tab Button
struct SuggestionTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.arabic(13, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? AppTheme.gold : AppTheme.textDim)
                Rectangle()
                    .fill(isSelected ? AppTheme.gold : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
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
            .frame(maxWidth: .infinity)
            .aspectRatio(2/3, contentMode: .fit)
            .cornerRadius(10)
            .clipped()
            .overlay(alignment: .topTrailing) {
                WatchLaterIconButton(media: media)
                    .scaleEffect(0.8)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }

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

            WatchLaterIconButton(media: media)
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
    }
}
