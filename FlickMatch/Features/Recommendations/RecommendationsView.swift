import SwiftUI

struct RecommendationsView: View {
    @ObservedObject var vm: RatingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Taste badge
            VStack(spacing: 4) {
                Text("بصمة ذوقك")
                    .font(AppTheme.arabic(11))
                    .foregroundColor(AppTheme.textDim)
                Text(vm.tasteBadge)
                    .font(AppTheme.arabic(17, weight: .bold))
                    .foregroundColor(AppTheme.gold)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.gold.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radius).stroke(AppTheme.gold.opacity(0.15), lineWidth: 1))
            .cornerRadius(AppTheme.radius)
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Stats row
            HStack(spacing: 8) {
                StatCard(value: "\(vm.ratedCount)", label: "قيّمت")
                StatCard(value: "\(vm.matchPercentage)%", label: "تطابق")
                StatCard(value: "\(vm.recommendations.count)", label: "توصيات")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Section title
            HStack {
                Text("🎯 نرشح لك")
                    .font(AppTheme.arabic(16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // Recommendation cards
            LazyVStack(spacing: 14) {
                ForEach(vm.recommendations) { rec in
                    NavigationLink(value: rec.media) {
                        RecommendationCard(recommendation: rec, genres: vm.genres)
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Rate more button
            if vm.canRateMore {
                Button(action: vm.rateMore) {
                    Text("🎬 قيّم 10 ثانية لدقة أعلى")
                        .font(AppTheme.arabic(14))
                        .foregroundColor(AppTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radius)
                                .stroke(AppTheme.gold.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.radius)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }

            Spacer().frame(height: 80)
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: Recommendation
    let genres: [Genre]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Match badge + watchlist
            HStack {
                Label("تطابق \(recommendation.matchPercentage)% مع ذوقك", systemImage: "checkmark.circle.fill")
                    .font(AppTheme.arabic(11, weight: .medium))
                    .foregroundColor(AppTheme.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.green.opacity(0.08))
                    .cornerRadius(10)
                Spacer()
                WatchLaterIconButton(media: recommendation.media)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Poster + Info
            HStack(alignment: .top, spacing: 12) {
                PosterImageView(
                    url: recommendation.media.posterURL,
                    width: 80,
                    height: 120,
                    contentType: recommendation.contentType
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.media.originalTitle)
                        .font(AppTheme.english(15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                    if !recommendation.media.localizedTitle.isEmpty {
                        Text(recommendation.media.localizedTitle)
                            .font(AppTheme.arabic(12))
                            .foregroundColor(AppTheme.textDim)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text(String(format: "%.1f", recommendation.media.voteAverage))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textDim)
                        Text(recommendation.media.year)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textDim)
                    }

                    TrailerButton(
                        contentId: recommendation.id,
                        contentType: recommendation.contentType,
                        title: recommendation.media.title
                    )
                    .padding(.top, 2)
                }
                Spacer()
            }
            .padding(14)

            // Reason
            HStack {
                Text(recommendation.reason)
                    .font(AppTheme.arabic(12))
                    .foregroundColor(AppTheme.textDim)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            .overlay(alignment: .top) {
                Divider().background(Color(hex: "#1a1a24"))
            }
        }
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.gold)
            Text(label)
                .font(AppTheme.arabic(10))
                .foregroundColor(AppTheme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .cornerRadius(10)
    }
}
