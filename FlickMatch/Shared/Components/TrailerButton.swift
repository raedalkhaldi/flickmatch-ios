import SwiftUI
import WebKit

// MARK: - Trailer Button
struct TrailerButton: View {
    let contentId: Int
    let contentType: ContentItemType
    @State private var showTrailer = false
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
                Text("التريلر")
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
        .fullScreenCover(isPresented: $showTrailer) {
            if let key = videoKey {
                TrailerFullScreen(videoKey: key, title: title) {
                    showTrailer = false
                }
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

// MARK: - Full Screen Trailer (no YouTube branding visible)
struct TrailerFullScreen: View {
    let videoKey: String
    let title: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Text(title)
                        .font(AppTheme.arabic(14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer()
                    // Spacer for symmetry
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                Spacer()

                VideoPlayerView(videoKey: videoKey)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)

                Spacer()
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Video Player (WKWebView — clean embed, no branding)
struct VideoPlayerView: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // youtube-nocookie for privacy, hide all branding
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube-nocookie.com/embed/\(videoKey)?playsinline=1&autoplay=1&rel=0&modestbranding=1&showinfo=0&controls=1&iv_load_policy=3&disablekb=0&fs=0&color=white"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
}

// Keep old name for compatibility with MediaDetailView's TrailerPlayerSection
typealias YouTubePlayerView = VideoPlayerView
