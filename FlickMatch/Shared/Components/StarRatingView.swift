import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    let maxRating = 10
    let starSize: CGFloat

    init(rating: Binding<Int?>, starSize: CGFloat = 20) {
        self._rating = rating
        self.starSize = starSize
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...maxRating, id: \.self) { star in
                starButton(for: star)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func starButton(for star: Int) -> some View {
        let isFilled = star <= (rating ?? 0)
        return Image(systemName: isFilled ? "star.fill" : "star")
            .resizable()
            .scaledToFit()
            .frame(width: starSize, height: starSize)
            .foregroundColor(isFilled ? AppTheme.gold : AppTheme.textDim.opacity(0.3))
            .scaleEffect(isFilled ? 1.0 : 0.9)
            .frame(width: max(starSize + 8, 30), height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.12)) {
                    if rating == star {
                        rating = nil
                    } else {
                        rating = star
                    }
                }
            }
    }
}
