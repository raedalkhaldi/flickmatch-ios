import SwiftUI

struct MediaCard: View {
    let media: AnyMedia
    let rank: Int
    let genres: [Genre]
    @Binding var rating: Int?
    @Binding var hasNotSeen: Bool
    @EnvironmentObject var watchlistStore: WatchlistStore

    var body: some View {
        VStack(spacing: 0) {
            // Top: poster + info
            HStack(alignment: .top, spacing: 12) {
                PosterImageView(
                    url: media.posterURL,
                    width: 80,
                    height: 120,
                    rank: rank,
                    contentType: media.contentType
                )

                VStack(alignment: .leading, spacing: 4) {
                    // Primary title (English from en-US, or localized)
                    Text(media.title)
                        .font(AppTheme.english(15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                    // Secondary title (Arabic if available)
                    if !media.localizedTitle.isEmpty {
                        Text(media.localizedTitle)
                            .font(AppTheme.arabic(12))
                            .foregroundColor(AppTheme.textDim)
                            .lineLimit(1)
                    }

                    // Meta row
                    HStack(spacing: 8) {
                        // IMDb badge
                        HStack(spacing: 3) {
                            Text("IMDb")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color(hex: "#f5c518"))
                                .cornerRadius(3)
                            Text(media.imdbRating)
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textDim)
                        }

                        Text(media.year)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textDim)

                        if let genreName = genreNames.first {
                            Text(genreName)
                                .font(AppTheme.arabic(10))
                                .foregroundColor(AppTheme.textDim)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(AppTheme.surface)
                                .cornerRadius(10)
                        }
                    }

                    // Trailer button
                    TrailerButton(
                        contentId: media.id,
                        contentType: media.contentType,
                        title: media.title
                    )
                    .padding(.top, 2)
                }
                Spacer()
            }
            .padding(14)

            // Bottom: rating section
            VStack(spacing: 8) {
                // Stars row
                HStack(spacing: 8) {
                    StarRatingView(rating: $rating)
                    .opacity(hasNotSeen ? 0.3 : 1.0)
                    .allowsHitTesting(!hasNotSeen)

                    Spacer()

                    // Rating number
                    if let r = rating, !hasNotSeen {
                        Text("\(r)/10")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.gold)
                    }
                }

                // Actions row
                HStack {
                    // Watch later button
                    WatchLaterIconButton(media: media)

                    Spacer()

                    // "Haven't seen" button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hasNotSeen.toggle()
                            if hasNotSeen { rating = nil }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: hasNotSeen ? "eye.slash.fill" : "eye.slash")
                                .font(.system(size: 11))
                            Text("ما شفته")
                                .font(AppTheme.arabic(11, weight: .medium))
                        }
                        .foregroundColor(hasNotSeen ? AppTheme.accent : AppTheme.textDim)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(hasNotSeen ? AppTheme.accent.opacity(0.1) : AppTheme.surface)
                        .overlay(
                            Capsule().stroke(
                                hasNotSeen ? AppTheme.accent.opacity(0.5) : Color(hex: "#252530"),
                                lineWidth: 1
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(AppTheme.card)
        .cornerRadius(AppTheme.radius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius)
                .stroke(
                    rating != nil ? AppTheme.gold.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var genreNames: [String] {
        switch media {
        case .movie(let m):
            return m.genreIds.compactMap { id in genres.first(where: { $0.id == id })?.name }
        case .series(let s):
            return s.genreIds.compactMap { id in genres.first(where: { $0.id == id })?.name }
        }
    }
}

// MARK: - Computed on AnyMedia
private extension AnyMedia {
    var imdbRating: String {
        String(format: "%.1f", voteAverage)
    }
}
