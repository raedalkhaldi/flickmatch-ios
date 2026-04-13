import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    let maxRating = 10
    let starSize: CGFloat

    init(rating: Binding<Int?>, starSize: CGFloat = 20) {
        self._rating = rating
        self.starSize = starSize
    }

    private var totalWidth: CGFloat {
        CGFloat(maxRating) * cellWidth
    }

    private var cellWidth: CGFloat {
        max(starSize + 8, 30)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...maxRating, id: \.self) { star in
                let isFilled = star <= (rating ?? 0)
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        if rating == star {
                            rating = nil
                        } else {
                            rating = star
                        }
                    }
                } label: {
                    Image(systemName: isFilled ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundColor(isFilled ? AppTheme.gold : AppTheme.textDim.opacity(0.3))
                        .scaleEffect(isFilled ? 1.0 : 0.9)
                        .frame(width: cellWidth, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
