import SwiftUI

struct WatchProvidersView: View {
    let providers: WatchProviderCountry

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
                    ProviderSection(title: "اشتراك", providers: flatrate)
                }

                // Rent
                if let rent = providers.rent, !rent.isEmpty {
                    ProviderSection(title: "تأجير", providers: rent)
                }

                // Buy
                if let buy = providers.buy, !buy.isEmpty {
                    ProviderSection(title: "شراء", providers: buy)
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

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title)
                .font(AppTheme.arabic(12, weight: .semibold))
                .foregroundColor(AppTheme.gold)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(providers) { provider in
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
