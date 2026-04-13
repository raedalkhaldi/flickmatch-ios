import SwiftUI

struct GenreFilterChips: View {
    let genres: [Genre]
    let selectedId: Int?
    let onSelect: (Int?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                chipButton(label: "الكل", isSelected: selectedId == nil) {
                    onSelect(nil)
                }

                ForEach(genres) { genre in
                    chipButton(label: genre.name, isSelected: selectedId == genre.id) {
                        onSelect(selectedId == genre.id ? nil : genre.id)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.arabic(12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? AppTheme.background : AppTheme.textDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AppTheme.gold : AppTheme.surface)
                .cornerRadius(14)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(hex: "#252530"), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
}
