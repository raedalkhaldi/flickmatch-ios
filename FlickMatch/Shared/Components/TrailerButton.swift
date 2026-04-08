import SwiftUI
import WebKit

// MARK: - Trailer Button
struct TrailerButton: View {
    let contentId: Int
    let contentType: ContentItemType
    @State private var showTrailer = false
    @State private var trailerURL: URL? = nil
    @State private var videoKey: String? = nil
    @State private var isLoading = false
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
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(AppTheme.accent)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                }
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
        .disabled(isLoading)
        .sheet(isPresented: $showTrailer, onDismiss: { videoKey = nil }) {
            if let key = videoKey {
                TrailerModal(videoKey: key, title: title)
            }
        }
    }

    private func loadAndShowTrailer() async {
        isLoading = true
        do {
            let video: VideoResult?
            if contentType == .movie {
                video = try await TMDbService.shared.fetchMovieTrailer(id: contentId)
            } else {
                video = try await TMDbService.shared.fetchSeriesTrailer(id: contentId)
            }
            if let v = video {
                videoKey = v.key
                showTrailer = true
            }
        } catch {}
        isLoading = false
    }
}

// MARK: - Trailer Modal
struct TrailerModal: View {
    let videoKey: String
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
                        .lineLimit(1)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                YouTubePlayerView(videoKey: videoKey)
                    .aspectRatio(16/9, contentMode: .fit)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - YouTube WKWebView (HTML-based — works in Simulator)
struct YouTubePlayerView: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(videoKey)?playsinline=1&autoplay=1&rel=0&modestbranding=1&showinfo=0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}
