import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab: ProfileTab = .movies

    enum ProfileTab { case movies, series }

    // Mock top lists — will come from Firestore
    private let topMovies: [MockTopItem] = MockTopItem.movieSamples
    private let topSeries: [MockTopItem] = MockTopItem.seriesSamples

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppTheme.gold, AppTheme.goldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.gold.opacity(0.3), radius: 20)
                            Text("👤")
                                .font(.system(size: 32))
                        }

                        VStack(spacing: 2) {
                            Text("أنت")
                                .font(AppTheme.arabic(20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("@moviefan")
                                .font(AppTheme.arabic(13))
                                .foregroundColor(AppTheme.textDim)
                        }

                        // Stats
                        HStack(spacing: 30) {
                            ProfileStat(value: "14", label: "أفلام")
                            ProfileStat(value: "8",  label: "مسلسلات")
                            ProfileStat(value: "12", label: "متابِع")
                            ProfileStat(value: "8",  label: "متابَع")
                        }
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                    // Tabs
                    HStack(spacing: 0) {
                        ProfileTabButton(title: "🎬 أعلى 10 أفلام",    tab: .movies,  selected: $selectedTab)
                        ProfileTabButton(title: "📺 أعلى 10 مسلسلات", tab: .series, selected: $selectedTab)
                    }
                    .padding(.horizontal, 20)

                    // Top list
                    LazyVStack(spacing: 0) {
                        let items = selectedTab == .movies ? topMovies : topSeries
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            TopListRow(item: item, rank: idx + 1)
                                .padding(.horizontal, 20)
                            if idx < items.count - 1 {
                                Divider()
                                    .background(Color(hex: "#151520"))
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Profile Stat
struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.gold)
            Text(label)
                .font(AppTheme.arabic(11))
                .foregroundColor(AppTheme.textDim)
        }
    }
}

// MARK: - Profile Tab Button
struct ProfileTabButton: View {
    let title: String
    let tab: ProfileView.ProfileTab
    @Binding var selected: ProfileView.ProfileTab

    var body: some View {
        Button { selected = tab } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.arabic(13, weight: selected == tab ? .bold : .regular))
                    .foregroundColor(selected == tab ? AppTheme.gold : AppTheme.textDim)
                Rectangle()
                    .fill(selected == tab ? AppTheme.gold : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Top List Row
struct TopListRow: View {
    let item: MockTopItem
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(AppTheme.english(14, weight: .black))
                .foregroundColor(AppTheme.gold)
                .frame(width: 24)

            // Poster thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.surface)
                    .frame(width: 44, height: 64)
                Text(item.emoji)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppTheme.arabic(13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.year)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDim)
                    Text(item.genre)
                        .font(AppTheme.arabic(10))
                        .foregroundColor(AppTheme.textDim)
                }
            }

            Spacer()

            Text("\(item.rating) ⭐")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.gold)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Mock Data
struct MockTopItem: Identifiable {
    let id: Int
    let title: String
    let emoji: String
    let year: String
    let genre: String
    let rating: Int

    static let movieSamples: [MockTopItem] = [
        MockTopItem(id: 1, title: "The Shawshank Redemption", emoji: "🏛", year: "1994", genre: "دراما", rating: 10),
        MockTopItem(id: 2, title: "The Godfather", emoji: "🤌", year: "1972", genre: "جريمة", rating: 10),
        MockTopItem(id: 3, title: "The Dark Knight", emoji: "🦇", year: "2008", genre: "أكشن", rating: 9),
        MockTopItem(id: 4, title: "Schindler's List", emoji: "📜", year: "1993", genre: "تاريخي", rating: 9),
        MockTopItem(id: 5, title: "Pulp Fiction", emoji: "💼", year: "1994", genre: "جريمة", rating: 9),
    ]

    static let seriesSamples: [MockTopItem] = [
        MockTopItem(id: 10, title: "Breaking Bad", emoji: "⚗️", year: "2008", genre: "جريمة", rating: 10),
        MockTopItem(id: 11, title: "Game of Thrones", emoji: "👑", year: "2011", genre: "فانتازيا", rating: 9),
        MockTopItem(id: 12, title: "Chernobyl", emoji: "☢️", year: "2019", genre: "دراما", rating: 9),
        MockTopItem(id: 13, title: "Band of Brothers", emoji: "🪖", year: "2001", genre: "حرب", rating: 9),
        MockTopItem(id: 14, title: "The Wire", emoji: "📡", year: "2002", genre: "جريمة", rating: 9),
    ]
}
