import SwiftUI

/// Horizontal genre chips in "exclude" mode.
/// All genres start visible (active). Tapping one crosses it out and hides
/// matching items from the rating list. Tapping again restores it.
struct GenreFilterChips: View {
    let genres: [Genre]
    let excludedIds: Set<Int>
    let onToggle: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres) { genre in
                    let isExcluded = excludedIds.contains(genre.id)
                    Button { onToggle(genre.id) } label: {
                        Text(genre.name)
                            .font(AppTheme.arabic(12, weight: .regular))
                            .strikethrough(isExcluded, color: AppTheme.accent)
                            .foregroundColor(isExcluded ? AppTheme.textDim.opacity(0.4) : AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isExcluded ? AppTheme.accent.opacity(0.08) : AppTheme.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    isExcluded ? AppTheme.accent.opacity(0.3) : Color(hex: "#252530"),
                                    lineWidth: 1
                                )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
