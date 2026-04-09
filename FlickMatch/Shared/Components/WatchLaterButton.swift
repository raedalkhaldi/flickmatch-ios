import SwiftUI

// MARK: - Full-width button for detail pages
struct WatchLaterButton: View {
    let media: AnyMedia
    @EnvironmentObject var watchlistStore: WatchlistStore

    private var isInWatchlist: Bool {
        watchlistStore.isInWatchlist(contentId: media.id)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                watchlistStore.toggle(
                    contentId: media.id,
                    contentType: media.contentType,
                    title: media.title,
                    posterPath: media.posterPath ?? "",
                    year: media.year
                )
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                Text(isInWatchlist ? "في قائمة المشاهدة ✓" : "أشوفه لاحقاً")
                    .font(AppTheme.arabic(13, weight: .semibold))
            }
            .foregroundColor(isInWatchlist ? AppTheme.gold : AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isInWatchlist ? AppTheme.gold.opacity(0.1) : AppTheme.card)
            .cornerRadius(AppTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius)
                    .stroke(isInWatchlist ? AppTheme.gold.opacity(0.3) : AppTheme.surface, lineWidth: 1)
            )
        }
    }
}

// MARK: - Small icon button for search results and cards
struct WatchLaterIconButton: View {
    let media: AnyMedia
    @EnvironmentObject var watchlistStore: WatchlistStore

    private var isInWatchlist: Bool {
        watchlistStore.isInWatchlist(contentId: media.id)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                watchlistStore.toggle(
                    contentId: media.id,
                    contentType: media.contentType,
                    title: media.title,
                    posterPath: media.posterPath ?? "",
                    year: media.year
                )
            }
        } label: {
            Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16))
                .foregroundColor(isInWatchlist ? AppTheme.gold : AppTheme.textDim)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
