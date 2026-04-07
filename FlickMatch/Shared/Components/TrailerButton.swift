import SwiftUI
import WebKit

// MARK: - Trailer Button
struct TrailerButton: View {
    let contentId: Int
    let contentType: ContentItemType
    @State private var showTrailer = false
    @State private var trailerURL: URL? = nil
    @State private var title: String

    init(contentId: Int, contentType: ContentItemType, title: String) {
        self.contentId = contentId
        self.contentType = contentType
        self._title = State(initialValue: title)
    }

    var body: some View {
        Button {
            Task { await loadAndShowTrailer() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                Text("مشاهدة التريلر")
                    .font(AppTheme.arabic(11))
            }
            .foregroundColor(AppTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.accent.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .sheet(isPresented: $showTrailer, onDismiss: { trailerURL = nil }) {
            if let url = trailerURL {
                TrailerModal(url: url, title: title)
            }
        }
    }

    private func loadAndShowTrailer() async {
        do {
            let video: VideoResult?
            if contentType == .movie {
                video = try await TMDbService.shared.fetchMovieTrailer(id: contentId)
            } else {
                video = try await TMDbService.shared.fetchSeriesTrailer(id: contentId)
            }
            if let url = video?.youtubeEmbedURL {
                trailerURL = url
                showTrailer = true
            }
        } catch {}
    }
}

// MARK: - Trailer Modal
struct TrailerModal: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.card.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(AppTheme.arabic(15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                YouTubePlayerView(url: url)
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - YouTube WKWebView
struct YouTubePlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
