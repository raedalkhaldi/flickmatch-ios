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
    /// Known provider IDs from TMDb → deep link info
    private static let providerMap: [Int: (scheme: String?, searchURL: String)] = [
        // Netflix
        8:   (scheme: "nflx://", searchURL: "https://www.netflix.com/search?q={query}"),
        // Amazon Prime Video
        119: (scheme: "aiv://", searchURL: "https://www.primevideo.com/search?phrase={query}"),
        9:   (scheme: "aiv://", searchURL: "https://www.primevideo.com/search?phrase={query}"),
        // Disney+
        337: (scheme: "disneyplus://", searchURL: "https://www.disneyplus.com/search?q={query}"),
        // Apple TV+
        350: (scheme: nil, searchURL: "https://tv.apple.com/search?term={query}"),
        2:   (scheme: nil, searchURL: "https://tv.apple.com/search?term={query}"),
        // Shahid
        1715: (scheme: "shahid://", searchURL: "https://shahid.mbc.net/ar/search?q={query}"),
        // OSN+
        629: (scheme: "osnplus://", searchURL: "https://www.osn.com/en/search?q={query}"),
        // TOD (beIN)
        1498: (scheme: nil, searchURL: "https://www.tod.tv/search?q={query}"),
        // Starz Play / Lionsgate+
        43:  (scheme: "starzplay://", searchURL: "https://www.starzplay.com/search?q={query}"),
        // Viu
        158: (scheme: "viu://", searchURL: "https://www.viu.com/search?q={query}"),
        // Crunchyroll
        283: (scheme: "crunchyroll://", searchURL: "https://www.crunchyroll.com/search?q={query}"),
        // Paramount+
        531: (scheme: "paramountplus://", searchURL: "https://www.paramountplus.com/search?q={query}"),
        // YouTube
        192: (scheme: nil, searchURL: "https://www.youtube.com/results?search_query={query}"),
        // Google Play
        3:   (scheme: nil, searchURL: "https://play.google.com/store/search?q={query}&c=movies"),
    ]

    static func open(provider: WatchProvider, title: String) {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title

        // 1. Try known search URL (universal link — opens app if installed, Safari if not)
        if let info = providerMap[provider.providerId] {
            let searchStr = info.searchURL.replacingOccurrences(of: "{query}", with: encoded)
            if let url = URL(string: searchStr) {
                UIApplication.shared.open(url)
                return
            }
        }

        // 2. Fallback: Google search for "watch [title] on [provider]"
        let fallback = "https://www.google.com/search?q=watch+\(encoded)+on+\(provider.providerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: fallback) {
            UIApplication.shared.open(url)
        }
    }
}
