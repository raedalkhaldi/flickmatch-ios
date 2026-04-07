import SwiftUI

struct PosterImageView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    var rank: Int? = nil
    var contentType: ContentItemType? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Rectangle()
                        .fill(AppTheme.surface)
                        .overlay(Image(systemName: "film").foregroundColor(AppTheme.textDim))
                @unknown default:
                    Rectangle().fill(AppTheme.surface)
                }
            }
            .frame(width: width, height: height)
            .clipped()

            // Rank badge
            if let rank {
                Text("\(rank)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(AppTheme.background)
                    .frame(width: 20, height: 20)
                    .background(AppTheme.gold)
                    .clipShape(Circle())
                    .padding(5)
            }

            // Type badge
            if let type = contentType {
                VStack {
                    Spacer()
                    HStack {
                        Text(type == .movie ? "فيلم" : "مسلسل")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(5)
                        Spacer()
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .cornerRadius(AppTheme.radiusSmall)
    }
}
