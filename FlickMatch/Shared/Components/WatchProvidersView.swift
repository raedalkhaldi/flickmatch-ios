import SwiftUI

struct WatchProvidersView: View {
    let providers: WatchProviderCountry
    let mediaTitle: String

    var body: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("وين أشوفه؟")
                        .font(AppTheme.arabic(15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Image(systemName: "play.tv")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.gold)
                }
            }

            VStack(spacing: 10) {
                // Subscription (Netflix, etc.)
                if let flatrate = providers.flatrate, !flatrate.isEmpty {
                    ProviderSection(title: "اشتراك", providers: flatrate, mediaTitle: mediaTitle)
                }

                // Rent
                if let rent = providers.rent, !rent.isEmpty {
                    ProviderSection(title: "تأجير", providers: rent, mediaTitle: mediaTitle)
                }

                // Buy
                if let buy = providers.buy, !buy.isEmpty {
                    ProviderSection(title: "شراء", providers: buy, mediaTitle: mediaTitle)
                }
            }
            .padding(14)
            .background(AppTheme.card)
            .cornerRadius(AppTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius)
                    .stroke(AppTheme.surface, lineWidth: 1)
            )

            // Attribution
            HStack {
                Spacer()
                Text("بيانات من JustWatch")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textDim.opacity(0.5))
            }
        }
    }
}

// MARK: - Provider Section
struct ProviderSection: View {
    let title: String
    let providers: [WatchProvider]
    let mediaTitle: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title)
                .font(AppTheme.arabic(12, weight: .semibold))
                .foregroundColor(AppTheme.gold)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(providers) { provider in
                        Button {
                            ProviderDeepLink.open(provider: provider, title: mediaTitle)
                        } label: {
                            VStack(spacing: 4) {
                                AsyncImage(url: provider.logoURL) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFit()
                                    default:
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.surface)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .cornerRadius(10)

                                Text(provider.providerName)
                                    .font(.system(size: 9))
                                    .foregroundColor(AppTheme.textDim)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Provider Deep Linking
enum ProviderDeepLink {
    /// Known provider IDs from TMDb → (URL scheme for app, web fallback)
    /// The appURL uses the provider's registered URL scheme so iOS opens the app
    /// directly instead of Safari. If the app is not installed or scheme fails,
    /// the webURL is used as a fallback.
    private static let providerMap: [Int: (appURL: String?, webURL: String)] = [
        // Netflix — nflx:// scheme opens the Netflix app directly
        8:   (appURL: "nflx://www.netflix.com/search?q={query}",
              webURL: "https://www.netflix.com/search?q={query}"),
        // Amazon Prime Video
        119: (appURL: "aiv://aiv/search?phrase={query}",
              webURL: "https://www.primevideo.com/search?phrase={query}"),
        9:   (appURL: "aiv://aiv/search?phrase={query}",
              webURL: "https://www.primevideo.com/search?phrase={query}"),
        // Disney+
        337: (appURL: "disneyplus://search?q={query}",
              webURL: "https://www.disneyplus.com/search?q={query}"),
        // Apple TV+ — universal link opens TV app directly on iOS
        350: (appURL: nil,
              webURL: "https://tv.apple.com/search?term={query}"),
        2:   (appURL: nil,
              webURL: "https://tv.apple.com/search?term={query}"),
        // Shahid (MBC)
        1715: (appURL: "shahid://search?q={query}",
               webURL: "https://shahid.mbc.net/ar/search?q={query}"),
        // OSN+
        629: (appURL: "osnplus://search?q={query}",
              webURL: "https://www.osn.com/en/search?q={query}"),
        // TOD (beIN)
        1498: (appURL: "tod://",
               webURL: "https://www.tod.tv/search?q={query}"),
        // Starz Play / Lionsgate+
        43:  (appURL: "starzplay://search?q={query}",
              webURL: "https://www.starzplay.com/search?q={query}"),
        // Viu
        158: (appURL: "viu://search?q={query}",
              webURL: "https://www.viu.com/search?q={query}"),
        // Crunchyroll
        283: (appURL: "crunchyroll://search?q={query}",
              webURL: "https://www.crunchyroll.com/search?q={query}"),
        // Paramount+
        531: (appURL: "paramountplus://search?q={query}",
              webURL: "https://www.paramountplus.com/search?q={query}"),
        // YouTube — youtube:// opens app directly
        192: (appURL: "youtube://www.youtube.com/results?search_query={query}",
              webURL: "https://www.youtube.com/results?search_query={query}"),
        // Google Play
        3:   (appURL: nil,
              webURL: "https://play.google.com/store/search?q={query}&c=movies"),
    ]

    static func open(provider: WatchProvider, title: String) {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title

        guard let info = providerMap[provider.providerId] else {
            openWebFallback(title: encoded, providerName: provider.providerName)
            return
        }

        // 1. Try the native URL scheme first (opens the app directly)
        if let appTemplate = info.appURL {
            let appStr = appTemplate.replacingOccurrences(of: "{query}", with: encoded)
            if let appURL = URL(string: appStr) {
                UIApplication.shared.open(appURL, options: [:]) { success in
                    if !success {
                        // App not installed or can't open the scheme → web fallback
                        openWeb(info.webURL, encoded: encoded)
                    }
                }
                return
            }
        }

        // 2. No app scheme — use web/universal link
        openWeb(info.webURL, encoded: encoded)
    }

    private static func openWeb(_ template: String, encoded: String) {
        let str = template.replacingOccurrences(of: "{query}", with: encoded)
        if let url = URL(string: str) {
            UIApplication.shared.open(url)
        }
    }

    private static func openWebFallback(title encoded: String, providerName: String) {
        let providerEncoded = providerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let fallback = "https://www.google.com/search?q=watch+\(encoded)+on+\(providerEncoded)"
        if let url = URL(string: fallback) {
            UIApplication.shared.open(url)
        }
    }
}
