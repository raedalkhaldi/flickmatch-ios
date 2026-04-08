import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    let maxRating = 10
    let starSize: CGFloat

    init(rating: Binding<Int?>, starSize: CGFloat = 26) {
        self._rating = rating
        self.starSize = starSize
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        if rating == star {
                            rating = nil
                        } else {
                            rating = star
                        }
                    }
                } label: {
                    Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundColor(star <= (rating ?? 0) ? AppTheme.gold : AppTheme.textDim.opacity(0.3))
                        .scaleEffect(star <= (rating ?? 0) ? 1.0 : 0.9)
                        .frame(width: starSize + 6, height: starSize + 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
